#!/usr/bin/env bash
# Extract frames from a render so they can actually be looked at before delivery.
#
#   ./inspect_frames.sh "$JOB/out/promo_1080x1920_v1.mp4" "$JOB/frames"
#
# Produces: one frame per second, the first and last frame, and a contact sheet.
# Clears previous extractions first, so you never inspect a stale frame from an
# earlier render and reach a confident wrong verdict.
set -euo pipefail

VIDEO="${1:?usage: inspect_frames.sh <video> [outdir]}"
OUT="${2:-frames}"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found"; exit 1; }
[ -f "$VIDEO" ] || { echo "no such file: $VIDEO"; exit 1; }

mkdir -p "$OUT"
rm -f "$OUT"/f_*.png "$OUT"/first.png "$OUT"/last.png "$OUT"/sheet.png

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
echo "duration: ${DUR}s"

ffmpeg -v error -i "$VIDEO" -vf fps=1 "$OUT/f_%03d.png"
ffmpeg -v error -i "$VIDEO" -frames:v 1 "$OUT/first.png"
ffmpeg -v error -sseof -0.2 -i "$VIDEO" -frames:v 1 -update 1 "$OUT/last.png"
ffmpeg -v error -i "$VIDEO" -vf "fps=1,scale=320:-1,tile=5x4" -frames:v 1 -update 1 "$OUT/sheet.png" 2>/dev/null || true

echo "frames written to $OUT/"
echo "Inspect at minimum: first.png, the hook frame (~f_002), each transition, last.png."
