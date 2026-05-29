@echo off
REM ============================================================================
REM Audio File Normalization Script for SVXLink
REM Description: Searches each directory for WAV files and normalizes them
REM              to -20 dB RMS at 16kHz sample rate using SoX
REM Requirements: SoX executable in same directory or in PATH
REM ============================================================================

setlocal enabledelayedexpansion

REM Define the base directory (script directory)
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%"

REM Define subdirectories to process
set "DIRS=Core Default DtmfRepeater EchoLink Frn Help MetarInfo Parrot PropagationMonitor SelCallEnc TclVoiceMail Trx"

REM Define target specifications
set "TARGET_RMS=-20"
set "SAMPLE_RATE=16000"
set "OUTPUT_FORMAT=16"

REM Check for SoX in multiple locations
set "SOX_PATH="

if exist "%SCRIPT_DIR%sox.exe" (
    set "SOX_PATH=%SCRIPT_DIR%sox.exe"
    echo Found SoX in script directory
) else if exist "%SCRIPT_DIR%sox\sox.exe" (
    set "SOX_PATH=%SCRIPT_DIR%sox\sox.exe"
    echo Found SoX in sox subdirectory
) else (
    REM Try to find SoX in PATH
    for /f "delims=" %%A in ('where sox 2^>nul') do (
        set "SOX_PATH=%%A"
    )
)

echo.
echo ============================================================================
echo Audio File Normalization Utility
echo ============================================================================
echo Base Directory: %BASE_DIR%
echo Target RMS Level: %TARGET_RMS% dB
echo Sample Rate: %SAMPLE_RATE% Hz
echo Output Format: %OUTPUT_FORMAT%-bit
echo.

REM Check if SoX is available
if "!SOX_PATH!"=="" (
    echo ERROR: SoX not found!
    echo.
    echo Solutions:
    echo 1. Install SoX globally: http://sox.sourceforge.net/
    echo    Then add the installation directory to your system PATH
    echo.
    echo 2. Place sox.exe in the same directory as this script
    echo.
    echo 3. Create a "sox" subdirectory and place sox.exe there
    echo.
    echo For Windows, download from:
    echo http://sourceforge.net/projects/sox/files/sox/
    echo.
    pause
    exit /b 1
)

echo SoX found at: !SOX_PATH!
"!SOX_PATH!" --version
echo.
echo Proceeding with normalization...
echo.

set "TOTAL_FILES=0"
set "PROCESSED_FILES=0"
set "ERROR_FILES=0"

REM Process each directory
for %%D in (%DIRS%) do (
    set "DIR_PATH=%BASE_DIR%%%D"
    
    if exist "!DIR_PATH!" (
        echo.
        echo Processing directory: %%D
        echo -----------------------------------------------
        
        REM Search for WAV files in the directory
        for /f "delims=" %%F in ('dir /b /s "!DIR_PATH!\*.wav" 2^>nul') do (
            set /a TOTAL_FILES+=1
            set "INPUT_FILE=%%F"
            set "DIRNAME=%%~dpF"
            set "FILENAME=%%~nF"
            set "OUTPUT_FILE=!DIRNAME!!FILENAME!.temp.wav"
            
            echo Processing: !FILENAME!
            
            REM Use SoX to normalize and resample
            "!SOX_PATH!" "!INPUT_FILE!" -b %OUTPUT_FORMAT% -r %SAMPLE_RATE% -D "!OUTPUT_FILE!" gain -n %TARGET_RMS% 2>nul
            
            if errorlevel 1 (
                echo   [ERROR] Failed to process !INPUT_FILE!
                if exist "!OUTPUT_FILE!" del "!OUTPUT_FILE!"
                set /a ERROR_FILES+=1
            ) else (
                REM Replace original with processed file
                del "!INPUT_FILE!"
                ren "!OUTPUT_FILE!" "!FILENAME!"
                echo   [OK] Normalized to %TARGET_RMS% dB RMS at %SAMPLE_RATE% Hz
                set /a PROCESSED_FILES+=1
            )
        )
        
        if !TOTAL_FILES! equ 0 (
            echo   (No WAV files found in this directory)
        )
    ) else (
        echo Directory not found: %%D (skipping)
    )
)

echo.
echo ============================================================================
echo Processing Complete
echo ============================================================================
echo Total files found:     !TOTAL_FILES!
echo Successfully processed: !PROCESSED_FILES!
echo Errors encountered:    !ERROR_FILES!
echo ============================================================================
echo.

pause
endlocal
