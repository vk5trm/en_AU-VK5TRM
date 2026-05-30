#!/bin/sh
###############################################################################
#
# This is the tts_handler.sh script which is used to generate sound clips
# using online Text-to-Speech (TTS) services for the SvxLink server system.
# Generated audio is processed through the same filtering as static clips.
#
#   Usage: tts_handler.sh [-L|-B] [-g] [-r <rate>] <text> <destination file>
#
# The script will read a configuration file, tts_handler.cfg, for TTS settings
# and audio processing parameters.
#
###############################################################################

# Print a warning message
warning()
{
  echo -e "\033[31m*** WARNING: $@\033[0m"
}

# Print an error message
error()
{
  echo -e "\033[31m*** ERROR: $@\033[0m"
}

# Print an info message
info()
{
  echo -e "\033[32mINFO: $@\033[0m"
}

# Print usage and exit
print_usage_and_exit()
{
  echo
  echo "Usage: tts_handler.sh [-L|-B] [-g] [-r <rate>] [-p <provider>] <text> <destination>"
  echo
  echo "  -L -- Target sound clip files should be little endian (default)"
  echo "  -B -- Target sound clip files should be big endian"
  echo "  -g -- Target sound clip files should be GSM encoded"
  echo "  -r -- Target sound clip file sample rate (default 8000)"
  echo "  -p -- TTS provider (google, azure, aws, espeak, festival)"
  echo "  -c -- Use cached version if available"
  echo
  exit 1
}

# Generate TTS using Google Cloud
generate_google_tts()
{
  local text="$1"
  local output_file="$2"
  
  if [ -z "$GOOGLE_API_KEY" ]; then
    error "Google API key not configured"
    return 1
  fi
  
  info "Generating TTS with Google Cloud for: $text"
  
  # Use sed to extract the base64 string robustly (handles spaces/newlines)
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-Goog-Api-Key: $GOOGLE_API_KEY" \
    -d "{
      \"input\": {\"text\": \"$text\"},
      \"voice\": {
        \"languageCode\": \"$GOOGLE_LANGUAGE\"
      },
      \"audioConfig\": {
        \"audioEncoding\": \"LINEAR16\",
        \"sampleRateHertz\": 16000
      }
    }" \
    "https://texttospeech.googleapis.com/v1/text:synthesize" | \
    sed -n 's/.*"audioContent": "\([^"]*\)".*/\1/p' | base64 -d > "$output_file"
  
  if [ $? -eq 0 ] && [ -s "$output_file" ]; then
    info "Google TTS generation completed"
    return 0
  else
    error "Google TTS generation failed or produced empty audio"
    return 1
  fi
}

# Generate TTS using Azure Cognitive Services
generate_azure_tts()
{
  local text="$1"
  local output_file="$2"
  
  if [ -z "$AZURE_API_KEY" ]; then
    error "Azure API key not configured"
    return 1
  fi
  
  info "Generating TTS with Azure for: $text"
  
  curl -s -X POST \
    -H "Ocp-Apim-Subscription-Key: $AZURE_API_KEY" \
    -H "Content-Type: application/ssml+xml" \
    -H "X-Microsoft-OutputFormat: riff-16khz-16bit-mono-pcm" \
    --data "<speak version='1.0' xml:lang='en-AU'><voice name='$AZURE_VOICE'>$text</voice></speak>" \
    "https://$AZURE_REGION.tts.speech.microsoft.com/cognitiveservices/v1" > "$output_file"
  
  if [ $? -eq 0 ]; then
    info "Azure TTS generation completed"
    return 0
  else
    error "Azure TTS generation failed"
    return 1
  fi
}

# Generate TTS using AWS Polly
generate_aws_tts()
{
  local text="$1"
  local output_file="$2"
  
  info "Generating TTS with AWS Polly for: $text"
  
  aws polly synthesize-speech \
    --text "$text" \
    --output-format pcm \
    --voice-id "$AWS_VOICE_ID" \
    --sample-rate 16000 \
    --engine neural \
    --region "$AWS_REGION" \
    "$output_file" 2>/dev/null
  
  if [ $? -eq 0 ]; then
    info "AWS Polly TTS generation completed"
    return 0
  else
    error "AWS Polly TTS generation failed"
    return 1
  fi
}

# Generate TTS using espeak
# Generate TTS using espeak
generate_espeak_tts()
{
  local text="$1"
  local output_file="$2"

   if ! command -v espeak >/dev/null 2>&1; then  
#  if ! command -v espeak &> /dev/null; then
    error "espeak is not installed or not in PATH"
    return 1
  fi

  info "Generating TTS with espeak for: $text"
  
  # Generate WAV directly from espeak (espeak outputs 16-bit 8kHz or 16kHz depending on flags)
  # We use 'stdout' and pipe to sox to ensure correct format
  espeak -v "$ESPEAK_VOICE" -s "$ESPEAK_SPEED" -p "$ESPEAK_PITCH" --stdout "$text" > /tmp/espeak_raw_$$.wav
  
  if [ ! -s "/tmp/espeak_raw_$$.wav" ]; then
    error "espeak generated an empty file"
    rm -f "/tmp/espeak_raw_$$.wav"
    return 1
  fi

  # Convert to the raw format expected by the main script (16kHz, 16-bit signed, mono)
  # Note: espeak usually outputs 8kHz by default, so we resample to 16kHz for better quality
  sox /tmp/espeak_raw_$$.wav -r 16000 -e signed -b 16 -c 1 -t raw - > "$output_file"
  
  local status=$?
  rm -f "/tmp/espeak_raw_$$.wav"
  
  if [ $status -eq 0 ] && [ -s "$output_file" ]; then
    info "espeak TTS generation completed"
    return 0
  else
    error "espeak TTS generation failed or sox conversion failed"
    return 1
  fi
}

# Generate TTS using festival
generate_festival_tts()
{
  local text="$1"
  local output_file="$2"
  
  info "Generating TTS with festival for: $text"
  
  # Festival outputs to stdout if we use --tts, but we need to ensure it's raw PCM
  # We use a temporary file for Festival's raw output first
  local temp_raw="/tmp/fest_raw_$$.wav"
  
  # Generate WAV file directly from Festival
  echo "(SayText \"$text\")" | festival --tss --batch > "$temp_raw" 2>/dev/null
  
  # Check if file was created and has content
  if [ ! -s "$temp_raw" ]; then
    error "Festival failed to generate audio"
    rm -f "$temp_raw"
    return 1
  fi

  # Convert WAV to raw PCM (16-bit, 16kHz) for the main script processing chain
  # Festival outputs standard WAV, so we convert it to the raw format the rest of the script expects
  sox "$temp_raw" -r 16000 -e signed -b 16 -c 1 -t raw - > "$output_file"
  
  # Cleanup
  rm -f "$temp_raw"
  
  if [ $? -eq 0 ] && [ -s "$output_file" ]; then
    info "Festival TTS generation completed"
    return 0
  else
    error "Festival TTS generation failed"
    return 1
  fi
}

# Generate hash for cache filename
get_cache_hash()
{
  echo "$1" | md5sum | cut -d' ' -f1
}

# Parse command line options
endian="L"
encoding=""
ext="wav"
target_rate=16000
provider=""
use_cache=0

while getopts LBgr:p:ch opt; do
  case $opt in
    L)
      endian="L"
      ;;
    B)
      endian="B"
      ;;
    g)
      encoding="g"
      ext="gsm"
      ;;
    r)
      target_rate=$OPTARG
      ;;
    p)
      provider=$OPTARG
      ;;
    c)
      use_cache=1
      ;;
    *)
      print_usage_and_exit
      ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt 2 ]; then
  print_usage_and_exit
fi

TEXT="$1"
DEST_FILE="$2"

# Find the directory where this script resides
BASEDIR=$(cd "$(dirname "$0")" && pwd)

# Source the configuration file
if [ ! -r "$BASEDIR/tts_handler.cfg" ]; then
  error "Configuration file $BASEDIR/tts_handler.cfg is missing"
  exit 1
fi
. "$BASEDIR/tts_handler.cfg"

# Override provider if specified on command line
if [ -n "$provider" ]; then
  TTS_PROVIDER="$provider"
fi

# Create cache directory if it doesn't exist
if [ ! -d "$TTS_CACHE_DIR" ]; then
  mkdir -p "$TTS_CACHE_DIR"
fi

# Check cache
CACHE_HASH=$(get_cache_hash "$TEXT-$TTS_PROVIDER-$target_rate-$ext")
CACHE_FILE="$TTS_CACHE_DIR/$CACHE_HASH.$ext"

if [ $use_cache -eq 1 ] && [ -f "$CACHE_FILE" ]; then
  info "Using cached TTS: $CACHE_FILE"
  cp "$CACHE_FILE" "$DEST_FILE"
  exit 0
fi

# Generate raw audio based on provider
RAW_OUTPUT="/tmp/tts_raw_$$.raw"
trap "rm -f $RAW_OUTPUT" EXIT

case "$TTS_PROVIDER" in
  google)
    generate_google_tts "$TEXT" "$RAW_OUTPUT" || exit 1
    ;;
  azure)
    generate_azure_tts "$TEXT" "$RAW_OUTPUT" || exit 1
    ;;
  aws)
    generate_aws_tts "$TEXT" "$RAW_OUTPUT" || exit 1
    ;;
  espeak)
    generate_espeak_tts "$TEXT" "$RAW_OUTPUT" || exit 1
    ;;
  festival)
    generate_festival_tts "$TEXT" "$RAW_OUTPUT" || exit 1
    ;;
  *)
    error "Unknown TTS provider: $TTS_PROVIDER"
    exit 1
    ;;
esac

# Process audio: Resample, apply effects, and save
# We use a single sox call where possible to avoid piping issues
# If TTS_EFFECT is complex, we pipe, but with explicit format flags

# 1. Ensure input is treated as 16-bit signed raw
INPUT_OPTS="-t raw -r 16000 -e signed -b 16 -c 1"

# 2. Run the processing chain
# Note: We explicitly define the output format of the first stage to match the second
sox $INPUT_OPTS "$RAW_OUTPUT" -r $target_rate -e signed -b 16 -c 1 -t raw - \
  | sox -t raw -r $target_rate -e signed -b 16 -c 1 - \
    -t raw -r $target_rate -e signed -b 16 -c 1 - \
    $TTS_EFFECT \
  | sox -t raw -r $target_rate -e signed -b 16 -c 1 - "$DEST_FILE"

if [ $? -eq 0 ]; then
  info "TTS processing completed: $DEST_FILE"
  # Cache the result
  cp "$DEST_FILE" "$CACHE_FILE"
  exit 0
else
  error "TTS audio processing failed"
  exit 1
fi
