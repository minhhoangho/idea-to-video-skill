#!/usr/bin/env bash
# Render a job's composition to the next free version in <job>/out/, normalise
# its loudness for social platforms, then run the QA pass on it.
#
#   ./render.sh "$JOB"                       # Main → out/<slug>_<W>x<H>_v<N>.mp4
#   ./render.sh "$JOB" --composition Square  # another composition, same rules
#   ./render.sh "$JOB" --no-loudnorm         # keep the mix exactly as rendered
#
# Never overwrites: <N> is one past the highest existing render of the same
# slug and size. Prints the new file's path on stdout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

JOB=""
COMP="Main"
LOUDNORM=1

while [ $# -gt 0 ]; do
  case "$1" in
    --composition) COMP="${2:?--composition needs an id}"; shift 2 ;;
    --composition=*) COMP="${1#--composition=}"; shift ;;
    --no-loudnorm) LOUDNORM=0; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) [ -z "$JOB" ] || { echo "unexpected argument: $1" >&2; exit 1; }; JOB="$1"; shift ;;
  esac
done

[ -n "$JOB" ] || { echo "usage: render.sh <job> [--composition <id>] [--no-loudnorm]" >&2; exit 1; }
PROJECT="$JOB/project"
[ -f "$PROJECT/package.json" ] || { echo "no Remotion project in $PROJECT — run scaffold_remotion.sh first" >&2; exit 1; }
[ -d "$PROJECT/node_modules" ] || { echo "dependencies missing — run 'npm install' in $PROJECT" >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "ffprobe not found — install ffmpeg" >&2; exit 1; }

# The job folder is <date>-<slug>; renders are named by the slug alone.
SLUG="$(basename "$JOB" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//')"
mkdir -p "$JOB/out"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "rendering $COMP…" >&2
(cd "$PROJECT" && npx remotion render "$COMP" "$TMP/raw.mp4" --codec=h264 --crf=18 --log=error) >&2

# Size comes from the file, not from arguments, so the filename cannot lie.
SIZE="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$TMP/raw.mp4")"

N=0
for f in "$JOB/out/${SLUG}_${SIZE}_v"*.mp4; do
  [ -e "$f" ] || continue
  v="${f##*_v}"; v="${v%.mp4}"
  case "$v" in ''|*[!0-9]*) continue ;; esac
  if [ "$v" -gt "$N" ]; then N="$v"; fi
done
OUT="$JOB/out/${SLUG}_${SIZE}_v$((N + 1)).mp4"

HAS_AUDIO="$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$TMP/raw.mp4" | head -1)"
if [ "$LOUDNORM" = "1" ] && [ -n "$HAS_AUDIO" ]; then
  # -14 LUFS is what TikTok, Reels and YouTube normalise to; arriving there
  # means the platform leaves the mix alone. -ar matters: loudnorm upsamples
  # to 192kHz otherwise.
  # ponytail: one-pass (dynamic) loudnorm; two-pass linear if pumping is ever audible.
  echo "normalising loudness to -14 LUFS…" >&2
  ffmpeg -v error -i "$TMP/raw.mp4" -c:v copy \
    -af loudnorm=I=-14:TP=-1.5:LRA=11 -ar 48000 -c:a aac -b:a 192k \
    -movflags +faststart "$OUT"
else
  mv "$TMP/raw.mp4" "$OUT"
fi

echo "rendered: $OUT" >&2
"$SCRIPT_DIR/inspect_frames.sh" "$OUT" "$JOB/frames" >&2
echo "$OUT"
