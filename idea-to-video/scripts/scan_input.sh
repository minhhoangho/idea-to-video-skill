#!/usr/bin/env bash
# Inventory the reference material a user dropped into a job's input/ folder,
# so the agent reads one table instead of probing six files by hand.
#
#   ./scan_input.sh video-projects/2026-08-28-adidas
#   ./scan_input.sh video-projects/2026-08-28-adidas --target 1080x1920
#
# Read-only. Nothing in input/ is ever modified, moved or deleted.
set -euo pipefail

TARGET="1080x1920"
JOB=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:?--target needs WxH}"; shift 2 ;;
    --target=*) TARGET="${1#--target=}"; shift ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) [ -z "$JOB" ] || { echo "unexpected argument: $1" >&2; exit 1; }; JOB="$1"; shift ;;
  esac
done

[ -n "$JOB" ] || { echo "usage: scan_input.sh <job-dir> [--target WxH]" >&2; exit 1; }

TW="${TARGET%%x*}"
TH="${TARGET##*x}"
case "$TW$TH" in *[!0-9]*|"") echo "--target must look like 1080x1920, got '$TARGET'" >&2; exit 1 ;; esac

INPUT="$JOB/input"
[ -d "$INPUT" ] || { echo "no input/ folder in $JOB — run new_project.sh first" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Seconds (possibly fractional) to M:SS. Duration is the one number that decides
# whether a reference clip is usable, so it is worth printing readably.
fmt_dur() {
  awk -v s="$1" 'BEGIN { if (s == "" || s+0 <= 0) { print "?"; exit }
                         m = int(s/60); printf "%d:%02d", m, int(s-m*60) }'
}

probe_dims() {
  have ffprobe || return 1
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
          -of csv=s=x:p=0 "$1" 2>/dev/null | head -1 | tr -d '\r'
}

probe_dur() {
  have ffprobe || return 1
  ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1" 2>/dev/null | head -1
}

pdf_pages() {
  if have pdfinfo; then
    pdfinfo "$1" 2>/dev/null | awk '/^Pages:/ { print $2; exit }'
  elif have mdls; then
    p="$(mdls -raw -name kMDItemNumberOfPages "$1" 2>/dev/null || true)"
    [ "$p" = "(null)" ] || printf '%s' "$p"
  fi
}

human_size() {
  # BSD and GNU stat disagree on flags; try both before giving up.
  b="$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0)"
  awk -v b="$b" 'BEGIN { if (b >= 1048576) printf "%.1f MB", b/1048576
                         else if (b >= 1024) printf "%.0f KB", b/1024
                         else printf "%d B", b }'
}

printf '%-30s %-6s %-16s %s\n' "FILE" "KIND" "DETAIL" "NOTE"
printf '%-30s %-6s %-16s %s\n' "------------------------------" "------" "----------------" "----"

COUNT=0
UNREADABLE=0

# -print0 because reference material arrives with spaces and accents in the
# names far more often than source code does.
while IFS= read -r -d '' f; do
  rel="${f#"$INPUT"/}"
  ext="$(printf '%s' "${f##*.}" | tr '[:upper:]' '[:lower:]')"
  COUNT=$((COUNT + 1))
  kind="other"; detail="$(human_size "$f")"; note="unknown type — ask the user what it is"

  case "$ext" in
    png|jpg|jpeg|gif|webp|heic|heif|tiff|tif|bmp)
      kind="image"
      dims="$(probe_dims "$f" || true)"
      if [ -n "${dims:-}" ] && [ "${dims%x*}" -gt 0 ] 2>/dev/null; then
        w="${dims%x*}"; h="${dims#*x}"; detail="$dims"
        pct=$(( w * 100 / TW ))
        if [ "$w" -ge "$TW" ] && [ "$h" -ge "$TH" ]; then note="full-frame capable"
        elif [ "$pct" -lt 25 ]; then note="! tiny — spans ${pct}% of frame width"
        else note="spans ${pct}% of frame width"
        fi
      else
        note="look at it; install ffmpeg for dimensions"
      fi
      ;;
    svg)
      kind="image"; detail="vector"; note="scales freely — best case for a logo" ;;
    mp4|mov|m4v|webm|avi|mkv)
      kind="video"
      dims="$(probe_dims "$f" || true)"
      dur="$(fmt_dur "$(probe_dur "$f" || true)")"
      detail="${dur}${dims:+ $dims}"
      note="extract frames before judging it" ;;
    mp3|wav|m4a|aac|flac|ogg)
      kind="audio"
      detail="$(fmt_dur "$(probe_dur "$f" || true)")"
      note="usable as music or VO bed" ;;
    pdf)
      kind="doc"
      pages="$(pdf_pages "$f" || true)"
      detail="${pages:+${pages} pages}"; detail="${detail:-$(human_size "$f")}"
      note="read it — brand rules and verbatim copy live here" ;;
    txt|md|csv|json|srt|vtt|rtf)
      kind="text"
      detail="$(awk 'END { print NR " lines" }' "$f" 2>/dev/null || human_size "$f")"
      note="read it in full" ;;
    ttf|otf|woff|woff2)
      kind="font"; note="usable directly in a Remotion composition" ;;
    psd|ai|sketch|fig|xd|indd)
      kind="design"
      note="! cannot be read — ask for a PNG/SVG export"
      UNREADABLE=$((UNREADABLE + 1)) ;;
    zip|rar|7z)
      kind="archive"; note="! unpack it first, then rescan"
      UNREADABLE=$((UNREADABLE + 1)) ;;
  esac

  printf '%-30s %-6s %-16s %s\n' "$rel" "$kind" "$detail" "$note"
done < <(find "$INPUT" -type f ! -name '.*' -print0 | sort -z)

echo
if [ "$COUNT" -eq 0 ]; then
  echo "input/ is empty — nothing supplied. Say so in brief.md rather than assuming."
  exit 0
fi

echo "${COUNT} file(s) against a ${TARGET} frame."
[ "$UNREADABLE" -eq 0 ] || echo "${UNREADABLE} file(s) you cannot open — ask for an export before promising to use them."
echo "Every file above must end up in brief.md: what you took from it, or why you did not."
