#!/bin/bash
set -x

INPUT_STREAM="$1"
OUTPUT_STREAM="$2"
escaped_string=${OUTPUT_STREAM//\!/\\!}
script_pid=$$

# Check if process already running
if pgrep -f "$escaped_string" | grep -v -w $script_pid ; then
    echo "Process $escaped_string is already running"
    exit 1
fi

# Paths
LOG_FILE="/tmp/ffmpeg_error.log"

# First ffmpeg attempt (scale=1280:-1)
FFMPEG_CMD1=(
    ffmpeg -rtsp_transport tcp -i "$INPUT_STREAM"
    -err_detect ignore_err -an
    -c:v libx264 -preset veryfast -crf 28 -tune zerolatency
    -vf "fps=25,scale=1280:-1"
    -b:v 4000k -maxrate 5000k -bufsize 10000k
    -max_muxing_queue_size 4096 -avoid_negative_ts make_zero
    -flvflags no_duration_filesize
    -f flv "$OUTPUT_STREAM"
)

# Second ffmpeg attempt (fallback scale=1280:-2)
FFMPEG_CMD2=(
    ffmpeg -rtsp_transport tcp -i "$INPUT_STREAM"
    -err_detect ignore_err -an
    -c:v libx264 -preset veryfast -crf 28 -tune zerolatency
    -vf "fps=25,scale=1280:-2"
    -b:v 4000k -maxrate 5000k -bufsize 10000k
    -max_muxing_queue_size 4096 -avoid_negative_ts make_zero
    -flvflags no_duration_filesize
    -f flv "$OUTPUT_STREAM"
)

# Function to run ffmpeg and capture errors
run_ffmpeg() {
    "${@}" 2> "$LOG_FILE" &
    FFMPEG_PID=$!
    wait $FFMPEG_PID
    return $?
}

# First attempt
echo "Starting ffmpeg with scale=1280:-1"
run_ffmpeg "${FFMPEG_CMD1[@]}"
EXIT_CODE=$?

# Check error log for height issue or connection reset
if grep -q -e "height not divisible by 2" -e "Connection reset by peer" -e "Broken pipe" "$LOG_FILE"; then
    echo "Retrying with scale=1280:-2 due to detected error"
    run_ffmpeg "${FFMPEG_CMD2[@]}"
    EXIT_CODE=$?
fi

# Final result
if [ $EXIT_CODE -ne 0 ]; then
    echo "FFmpeg exited with error code $EXIT_CODE"
    cat "$LOG_FILE"
else
    echo "FFmpeg completed successfully"
fi

exit $EXIT_CODE

