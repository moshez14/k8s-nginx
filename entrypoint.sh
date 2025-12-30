#!/usr/bin/env bash
set -e

echo "▶ Entrypoint started"
echo "INPUT_STREAM=$INPUT_STREAM"
echo "OUTPUT_STREAM=$OUTPUT_STREAM"

if [[ -z "$INPUT_STREAM" || -z "$OUTPUT_STREAM" ]]; then
  echo "ERROR: INPUT_STREAM or OUTPUT_STREAM is not set"
  exit 1
fi

echo "▶ Starting nginx first..."
/usr/local/nginx/sbin/nginx \
  -c /app/nginx.conf \
  -g "daemon off;" &

NGINX_PID=$!
echo "nginx PID=$NGINX_PID"

echo "▶ Starting FFmpeg after nginx..."
/app/run_ffmpeg.sh "$INPUT_STREAM" "$OUTPUT_STREAM" &

FFMPEG_PID=$!
echo "ffmpeg PID=$FFMPEG_PID"

# Graceful shutdown
trap "echo 'Stopping...'; kill $FFMPEG_PID $NGINX_PID; exit 0" SIGTERM SIGINT

# Keep container alive while nginx runs
wait $NGINX_PID

