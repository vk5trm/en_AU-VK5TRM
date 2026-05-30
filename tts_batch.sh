#!/bin/bash
set -euo pipefail

###############################################################################
# Configuration
###############################################################################
INPUT_DIR="${1:-.}"
TARGET_RATE="${2:-16000}"
PARALLEL_JOBS="${3:-1}"
USE_CACHE=1

###############################################################################
# Locate tts_handler.sh
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TTS_HANDLER="$SCRIPT_DIR/tts_handler.sh"

if [ ! -f "$TTS_HANDLER" ]; then
    echo "ERROR: tts_handler.sh not found at $TTS_HANDLER"
    exit 1
fi

if [ ! -x "$TTS_HANDLER" ]; then
    echo "ERROR: tts_handler.sh not executable at $TTS_HANDLER"
    exit 1
fi

###############################################################################
# Process one file
###############################################################################
process_file() {
    local txt_file="$1"
    local dir base wav_file text

    dir="$(dirname "$txt_file")"
    base="$(basename "$txt_file" .txt)"
    wav_file="$dir/$base.wav"

    if [ -f "$wav_file" ]; then
        echo "[SKIP] $wav_file already exists"
        return 0
    fi

    # Read text safely
    text="$(<"$txt_file")"

    echo "[TTS ] $txt_file"

    # Run tts_handler with proper error handling
    if ! "$TTS_HANDLER" -r "$TARGET_RATE" -c "$text" "$wav_file"; then
        echo "[ERROR] Failed to generate TTS for $txt_file" >&2
        return 1
    fi

    if [ -s "$wav_file" ]; then
        echo "[ OK ] $wav_file generated"
    else
        echo "[ERROR] Empty output for $txt_file" >&2
        return 1
    fi
}

export TTS_HANDLER TARGET_RATE USE_CACHE
export -f process_file

###############################################################################
# Verify input directory
###############################################################################
if [ ! -d "$INPUT_DIR" ]; then
    echo "ERROR: Directory not found: $INPUT_DIR"
    exit 1
fi

###############################################################################
# Find and process files
###############################################################################
echo "Input directory: $INPUT_DIR"
echo "Sample rate    : $TARGET_RATE"
echo "Parallel jobs  : $PARALLEL_JOBS"
echo

# Sequential processing with error handling
while IFS= read -r -d '' file; do
    if ! process_file "$file"; then
        echo "[WARN] Skipping to next file"
    fi
done < <(find "$INPUT_DIR" -type f -iname "*.txt" -print0)

echo
echo "Processing completed."
