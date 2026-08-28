#!/usr/bin/env bash
# Turn a job's script.md into narration audio plus the timing config that drives
# the Remotion composition. No API keys: edge-tts is free and runs from ./.venv.
#
#   ./narrate.sh <job> --voice vi-VN-NamMinhNeural
#   ./narrate.sh <job> --voice en-US-AndrewNeural --fps 30 --rate +8%
#   ./narrate.sh --voices vi              # list the voices for a language
#
# Reads  <job>/script.md                     one "## <scene-id>" heading per scene
# Writes <job>/project/public/audio/<id>.mp3
#        <job>/project/src/audioConfig.ts    id, file, duration, frames, from
#
# Audio decides scene length, never the other way round — that is the whole
# point of running this before building the composition.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

JOB=""
PROJECT=""
VOICE="en-US-AndrewNeural"
RATE="+0%"
FPS=30
PAD_FRAMES=6          # ~0.2s at 30fps, so a scene does not cut on the last syllable
RETRIES=3
LIST_LANG=""
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --voice) VOICE="${2:?--voice needs a name}"; shift 2 ;;
    --voice=*) VOICE="${1#--voice=}"; shift ;;
    --rate) RATE="${2:?--rate needs e.g. +8%}"; shift 2 ;;
    --rate=*) RATE="${1#--rate=}"; shift ;;
    --fps) FPS="${2:?--fps needs a number}"; shift 2 ;;
    --fps=*) FPS="${1#--fps=}"; shift ;;
    --pad-frames) PAD_FRAMES="${2:?--pad-frames needs a number}"; shift 2 ;;
    --pad-frames=*) PAD_FRAMES="${1#--pad-frames=}"; shift ;;
    --project) PROJECT="${2:?--project needs a path}"; shift 2 ;;
    --project=*) PROJECT="${1#--project=}"; shift ;;
    --voices) LIST_LANG="${2:?--voices needs a language prefix, e.g. vi}"; shift 2 ;;
    --voices=*) LIST_LANG="${1#--voices=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) [ -z "$JOB" ] || { echo "unexpected argument: $1" >&2; exit 1; }; JOB="$1"; shift ;;
  esac
done

case "$FPS$PAD_FRAMES" in *[!0-9]*|"") echo "--fps and --pad-frames must be numbers" >&2; exit 1 ;; esac

# edge-tts lives in the workspace venv. Bootstrap it rather than making the
# caller remember a setup step they will only need once.
if [ -x ".venv/bin/edge-tts" ]; then
  EDGE=".venv/bin/edge-tts"
elif command -v edge-tts >/dev/null 2>&1; then
  EDGE="edge-tts"
else
  echo "edge-tts not found — building ./.venv" >&2
  EDGE="$("$SCRIPT_DIR/setup_python_env.sh" edge-tts)/edge-tts"
fi

if [ -n "$LIST_LANG" ]; then
  "$EDGE" --list-voices | awk -v p="$(printf '%s' "$LIST_LANG" | tr '[:upper:]' '[:lower:]')" \
    'NR <= 2 || tolower($1) ~ "^" p "-"'
  exit 0
fi

[ -n "$JOB" ] || { echo "usage: narrate.sh <job> --voice <name>   (or --voices <lang>)" >&2; exit 1; }
SCRIPT_MD="$JOB/script.md"
[ -f "$SCRIPT_MD" ] || { echo "no $SCRIPT_MD — write the narration script first" >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo "ffprobe not found — install ffmpeg" >&2; exit 1; }

PROJECT="${PROJECT:-$JOB/project}"
AUDIO="$PROJECT/public/audio"
mkdir -p "$AUDIO" "$PROJECT/src"

# Pull "## <id>" headings and the prose beneath each. HTML comments, blockquote
# notes and horizontal rules are editorial scaffolding, not narration — a stray
# "> remember to shorten this" read aloud is a genuinely embarrassing failure.
RECORDS="$(awk '
  /<!--/            { inc = 1 }
  inc == 1          { if (/-->/) inc = 0; next }
  /^##[[:space:]]+/ { if (id != "") print id "\t" text
                      id = $0; sub(/^##[[:space:]]+/, "", id); text = ""; next }
  /^#/              { next }
  /^>/              { next }
  /^[[:space:]]*(-{3,}|\*{3,})[[:space:]]*$/ { next }
  {
    if (id == "") next
    line = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
    if (line == "") next
    text = (text == "" ? line : text " " line)
  }
  END { if (id != "") print id "\t" text }
' "$SCRIPT_MD")"

[ -n "$RECORDS" ] || { echo "no '## <scene-id>' sections found in $SCRIPT_MD" >&2; exit 1; }

# Checking what will actually be spoken costs nothing; discovering that an
# editorial note got read aloud costs a re-render.
if [ "$DRY_RUN" = "1" ]; then
  printf '%s\n' "$RECORDS" | awk -F'\t' '{ printf "## %s\n%s\n\n", $1, ($2 == "" ? "(empty — will be skipped)" : $2) }'
  exit 0
fi

echo "voice: $VOICE   rate: $RATE   fps: $FPS   pad: ${PAD_FRAMES}f" >&2

ERRLOG="$(mktemp)"
trap 'rm -f "$ERRLOG"' EXIT

IDS=(); FILES=(); DURS=(); FRAMES=(); FROMS=()
FROM=0

while IFS="$(printf '\t')" read -r RAW_ID TEXT; do
  [ -n "${TEXT:-}" ] || { echo "skipping '$RAW_ID' — no narration text under the heading" >&2; continue; }
  # The id becomes a filename and a TypeScript value, so normalise it once.
  ID="$(printf '%s' "$RAW_ID" | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-*//' -e 's/-*$//')"
  [ -n "$ID" ] || { echo "heading '$RAW_ID' has no usable characters — skipped" >&2; continue; }

  OUT="$AUDIO/$ID.mp3"
  printf '  %-20s ' "$ID" >&2

  # The upstream service intermittently returns nothing ("NoAudioReceived") for
  # a request that succeeds on the next try, so a single failure is not a real
  # failure. </dev/null matters too: without it edge-tts consumes the heredoc
  # feeding this loop and every scene after the first silently disappears.
  ATTEMPT=1
  while :; do
    rm -f "$OUT"
    if "$EDGE" --voice "$VOICE" --rate "$RATE" --text "$TEXT" --write-media "$OUT" \
         </dev/null >/dev/null 2>"$ERRLOG" && [ -s "$OUT" ]; then
      break
    fi
    if [ "$ATTEMPT" -ge "$RETRIES" ]; then
      echo "FAILED after ${RETRIES} attempts" >&2
      sed 's/^/    /' "$ERRLOG" >&2
      echo "    if this says NoAudioReceived it is usually transient — rerun." >&2
      echo "    if it names the voice, list valid ones: narrate.sh --voices <lang>" >&2
      exit 1
    fi
    printf 'retry %d… ' "$ATTEMPT" >&2
    ATTEMPT=$((ATTEMPT + 1))
    sleep 2
  done

  DUR="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT" </dev/null | head -1)"
  [ -n "$DUR" ] || { echo "FAILED — no duration from ffprobe" >&2; exit 1; }
  # Round up: a scene one frame short clips the final consonant.
  F="$(awk -v d="$DUR" -v fps="$FPS" -v pad="$PAD_FRAMES" \
       'BEGIN { n = d * fps; printf "%d", (n == int(n) ? n : int(n) + 1) + pad }')"

  IDS+=("$ID"); FILES+=("audio/$ID.mp3"); DURS+=("$DUR"); FRAMES+=("$F"); FROMS+=("$FROM")
  FROM=$((FROM + F))
  awk -v d="$DUR" -v f="$F" 'BEGIN { printf "%.2fs  %d frames\n", d, f }' >&2
done <<EOF
$RECORDS
EOF

[ "${#IDS[@]}" -gt 0 ] || { echo "nothing was generated" >&2; exit 1; }

CONFIG="$PROJECT/src/audioConfig.ts"
{
  echo "// Generated by scripts/narrate.sh — do not edit by hand."
  echo "// Regenerate after every change to script.md; the composition's timing"
  echo "// is derived from these numbers, not the other way round."
  echo
  echo "export const FPS = ${FPS};"
  echo
  echo "export type NarrationScene = {"
  echo "  /** Scene id, from the script.md heading. */"
  echo "  id: string;"
  echo "  /** Path for staticFile(), relative to public/. */"
  echo "  file: string;"
  echo "  durationInSeconds: number;"
  echo "  /** Audio length rounded up, plus tail padding. */"
  echo "  frames: number;"
  echo "  /** Cumulative offset — pass straight to <Sequence from={}>. */"
  echo "  from: number;"
  echo "};"
  echo
  echo "export const SCENES: NarrationScene[] = ["
  i=0
  while [ "$i" -lt "${#IDS[@]}" ]; do
    awk -v id="${IDS[$i]}" -v file="${FILES[$i]}" -v d="${DURS[$i]}" \
        -v f="${FRAMES[$i]}" -v from="${FROMS[$i]}" \
        'BEGIN { printf "  { id: \"%s\", file: \"%s\", durationInSeconds: %.2f, frames: %d, from: %d },\n", id, file, d, f, from }'
    i=$((i + 1))
  done
  echo "];"
  echo
  echo "export const TOTAL_FRAMES = ${FROM};"
  echo
  echo "export const sceneById = (id: string): NarrationScene => {"
  echo "  const found = SCENES.find((s) => s.id === id);"
  echo "  if (!found) throw new Error(\`no narration scene '\${id}' — rerun narrate.sh\`);"
  echo "  return found;"
  echo "};"
} > "$CONFIG"

awk -v n="${#IDS[@]}" -v t="$FROM" -v fps="$FPS" \
  'BEGIN { printf "\n%d scene(s), %d frames total (%.1fs)\n", n, t, t / fps }' >&2
echo "audio:  $AUDIO/" >&2
echo "config: $CONFIG" >&2
echo "next: drive every <Sequence> from SCENES — never hardcode a duration" >&2
echo "$CONFIG"
