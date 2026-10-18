#!/usr/bin/env bash
# Extract frames from a render so they can actually be looked at before delivery.
#
#   ./inspect_frames.sh "$JOB/out/promo_1080x1920_v1.mp4" "$JOB/frames"
#
# Produces: one frame per second, the first and last frame, a contact sheet,
# and qa.txt — automated flags for black or frozen stretches, silence, loudness
# and a size that disagrees with the filename.
# Clears previous extractions first, so you never inspect a stale frame from an
# earlier render and reach a confident wrong verdict.
set -euo pipefail

VIDEO="${1:?usage: inspect_frames.sh <video> [outdir]}"
OUT="${2:-frames}"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found"; exit 1; }
[ -f "$VIDEO" ] || { echo "no such file: $VIDEO"; exit 1; }

mkdir -p "$OUT"
rm -f "$OUT"/f_*.png "$OUT"/first.png "$OUT"/last.png "$OUT"/sheet.png "$OUT"/qa.txt "$OUT"/qa.log

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
echo "duration: ${DUR}s"

ffmpeg -v error -i "$VIDEO" -vf fps=1 "$OUT/f_%03d.png"
ffmpeg -v error -i "$VIDEO" -frames:v 1 "$OUT/first.png"
ffmpeg -v error -sseof -0.2 -i "$VIDEO" -frames:v 1 -update 1 "$OUT/last.png"
# One cell per second so the sheet covers the whole video, the CTA included; past
# 60s it samples evenly instead of growing without bound.
CELLS="$(awk -v d="$DUR" 'BEGIN { n = int(d); if (n < d) n++; print (n < 1 ? 1 : (n > 60 ? 60 : n)) }')"
SHEET_FPS="$(awk -v n="$CELLS" -v d="$DUR" 'BEGIN { printf "%.6f", n / d }')"
ffmpeg -v error -i "$VIDEO" -vf "fps=$SHEET_FPS,scale=320:-1,tile=5x$(( (CELLS + 4) / 5 ))" -frames:v 1 -update 1 "$OUT/sheet.png" 2>/dev/null || true

echo "frames written to $OUT/"

# Machine checks. They flag; you judge. A dark-themed video can trip
# blackdetect on purpose, and grain hides a frozen frame from freezedetect —
# which is why these sit beside the frames rather than replacing them.
HAS_AUDIO="$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$VIDEO" | head -1)"
AF=()
if [ -n "$HAS_AUDIO" ]; then AF=(-af "silencedetect=n=-45dB:d=0.8,ebur128=peak=true:framelog=verbose"); fi
LOG="$OUT/qa.log"
ffmpeg -hide_banner -nostats -i "$VIDEO" \
  -vf "blackdetect=d=0.4:pix_th=0.08,freezedetect=n=0.001:d=2" ${AF[@]+"${AF[@]}"} \
  -f null - 2>"$LOG" || true

SIZE="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$VIDEO")"
RATE="$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$VIDEO")"

{
  printf 'QA  %s · %s fps · %.1fs · audio: %s\n' "$SIZE" "$RATE" "$DUR" "$([ -n "$HAS_AUDIO" ] && echo yes || echo no)"

  NAMED="$(basename "$VIDEO" | sed -nE 's/.*_([0-9]+x[0-9]+)_v[0-9]+\.[a-z0-9]+$/\1/p')"
  if [ -z "$NAMED" ]; then echo "--    filename carries no <W>x<H>_v<N>; size not cross-checked"
  elif [ "$NAMED" = "$SIZE" ]; then echo "ok    size matches filename"
  else echo "WARN  filename says $NAMED, file is $SIZE"; fi

  BLACK="$(awk '/black_start/ { for (i = 1; i <= NF; i++) if ($i ~ /^black_(start|end):/) { split($i, a, ":"); printf "%s%s", a[2], (a[1] == "black_start" ? "–" : "s  ") } }' "$LOG")"
  if [ -n "$BLACK" ]; then echo "WARN  near-black: $BLACK(intentional?)"; else echo "ok    no near-black stretch ≥0.4s"; fi

  # A freeze that runs to the last frame never gets a freeze_end line.
  FREEZE="$(awk -F': ' '/freeze_start/ { s = $2 } /freeze_end/ { printf "%s–%ss  ", s, $2; s = "" }
                        END { if (s != "") printf "%s–end  ", s }' "$LOG")"
  if [ -n "$FREEZE" ]; then echo "WARN  frozen picture ≥2s: $FREEZE"; else echo "ok    no frozen stretch ≥2s"; fi

  if [ -n "$HAS_AUDIO" ]; then
    SIL="$(awk '/silence_start/ { s = $NF } /silence_end/ { split($0, a, "silence_end: "); split(a[2], b, " "); printf "%s–%ss  ", s, b[1] }' "$LOG")"
    if [ -n "$SIL" ]; then echo "WARN  silence ≥0.8s: $SIL"; else echo "ok    no silence ≥0.8s"; fi

    # The summary block is the last "I:" and "Peak:" in the log.
    LUFS="$(awk '/^ *I: / { v = $2 } END { print v }' "$LOG")"
    PEAK="$(awk '/^ *Peak: / { v = $2 } END { print v }' "$LOG")"
    awk -v i="$LUFS" -v p="$PEAK" 'BEGIN {
      ok = (i >= -16 && i <= -12 && p <= -1.0)
      printf "%s  loudness %s LUFS, true peak %s dBFS (target -14 ±2, peak ≤ -1)\n", (ok ? "ok  " : "WARN"), i, p
    }'
  fi
} | tee "$OUT/qa.txt"

echo "Inspect at minimum: first.png, the hook frame (~f_002), each transition, last.png."
