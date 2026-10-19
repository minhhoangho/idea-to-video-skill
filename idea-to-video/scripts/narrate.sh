#!/usr/bin/env bash
# Turn a job's script.md into narration audio plus the timing config that drives
# the Remotion composition. No API keys: edge-tts is free and runs from ./.venv.
#
#   ./narrate.sh <job> --voice vi-VN-NamMinhNeural
#   ./narrate.sh <job> --voice en-US-AndrewNeural --fps 30 --rate +8% --pitch -4Hz
#   ./narrate.sh --voices vi              # list the voices for a language
#   ./narrate.sh <job> --audition vi-VN-HoaiMyNeural,vi-VN-NamMinhNeural
#   ./narrate.sh --audition en-US-AvaNeural,en-US-BrianNeural --text "Hi there."
#                                         # one short sample per voice, to let
#                                         # the user listen and pick
#
# Reads  <job>/script.md                     one "## <scene-id>" heading per scene
# Writes <job>/project/public/audio/<id>.mp3
#        <job>/project/src/audioConfig.ts    id, file, duration, frames, from,
#                                            text, per-word timing
#        <job>/project/src/narration.ts      types + musicVolume(), if missing
#        <job>/voice-samples/<voice>.mp3     --audition only; nothing else written
#
# Audio decides scene length, never the other way round — that is the whole
# point of running this before building the composition.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

JOB=""
PROJECT=""
VOICE="en-US-AndrewNeural"
RATE="+0%"
PITCH="+0Hz"
AUDITION=""
SAMPLE_TEXT=""
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
    --pitch) PITCH="${2:?--pitch needs e.g. -4Hz}"; shift 2 ;;
    --pitch=*) PITCH="${1#--pitch=}"; shift ;;
    --audition) AUDITION="${2:?--audition needs voice names, comma-separated}"; shift 2 ;;
    --audition=*) AUDITION="${1#--audition=}"; shift ;;
    --text) SAMPLE_TEXT="${2:?--text needs a sentence}"; shift 2 ;;
    --text=*) SAMPLE_TEXT="${1#--text=}"; shift ;;
    --fps) FPS="${2:?--fps needs a number}"; shift 2 ;;
    --fps=*) FPS="${1#--fps=}"; shift ;;
    --pad-frames) PAD_FRAMES="${2:?--pad-frames needs a number}"; shift 2 ;;
    --pad-frames=*) PAD_FRAMES="${1#--pad-frames=}"; shift ;;
    --project) PROJECT="${2:?--project needs a path}"; shift 2 ;;
    --project=*) PROJECT="${1#--project=}"; shift ;;
    --voices) LIST_LANG="${2:?--voices needs a language prefix, e.g. vi}"; shift 2 ;;
    --voices=*) LIST_LANG="${1#--voices=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) [ -z "$JOB" ] || { echo "unexpected argument: $1" >&2; exit 1; }; JOB="$1"; shift ;;
  esac
done

case "$FPS$PAD_FRAMES" in *[!0-9]*|"") echo "--fps and --pad-frames must be numbers" >&2; exit 1 ;; esac

# edge-tts lives in the workspace venv. Bootstrap it rather than making the
# caller remember a setup step they will only need once. The venv's python is
# what matters: word timings come from the edge_tts module, not the CLI.
if .venv/bin/python -c 'import edge_tts' >/dev/null 2>&1; then
  BIN=".venv/bin"
else
  echo "edge-tts not found in ./.venv — building it" >&2
  BIN="$("$SCRIPT_DIR/setup_python_env.sh" edge-tts)"
fi

UPGRADED=0
upgrade_edge_tts() {
  if command -v uv >/dev/null 2>&1; then
    uv pip install --quiet --python "$BIN/python" -U edge-tts >&2 && return 0
  fi
  "$BIN/python" -m pip install --quiet -U edge-tts >&2
}

if [ -n "$LIST_LANG" ]; then
  "$BIN/edge-tts" --list-voices | awk -v p="$(printf '%s' "$LIST_LANG" | tr '[:upper:]' '[:lower:]')" \
    'NR <= 2 || tolower($1) ~ "^" p "-"'
  exit 0
fi

# Pull "## <id>" headings and the prose beneath each. HTML comments, blockquote
# notes and horizontal rules are editorial scaffolding, not narration — a stray
# "> remember to shorten this" read aloud is a genuinely embarrassing failure.
scene_records() {
  awk '
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
' "$1"
}

ERRLOG="$(mktemp)"
trap 'rm -f "$ERRLOG"' EXIT

# speak <voice> <text> <out>: synthesise one utterance, leaving its text/words
# JSON in SPOKEN. Returns 1 once RETRIES attempts have failed, with the last
# error in ERRLOG. The upstream service intermittently returns nothing
# ("NoAudioReceived") for a request that succeeds on the next try, so a single
# failure is not a real failure. </dev/null matters too: without it the child
# consumes the heredoc feeding the scene loop and every scene after the first
# silently disappears. --rate=/--pitch= are passed joined, because argparse
# reads a separate "-10%" as an unknown option.
speak() {
  local attempt=1
  while :; do
    rm -f "$3"
    if SPOKEN="$("$BIN/python" -I "$SCRIPT_DIR/tts_words.py" --voice "$1" --rate="$RATE" \
         --pitch="$PITCH" --text "$2" --out "$3" </dev/null 2>"$ERRLOG")" && [ -s "$3" ]; then
      return 0
    fi
    # A 403 on the websocket handshake is not transient: the service rotated
    # what it accepts and only a newer edge-tts speaks the new handshake. A
    # venv built weeks ago keeps failing, so upgrade once and go again.
    if [ "$UPGRADED" = "0" ] && grep -q 'WSServerHandshakeError: 403' "$ERRLOG"; then
      UPGRADED=1
      echo "rejected with 403 — upgrading edge-tts… " >&2
      upgrade_edge_tts || echo "    upgrade failed; run: $BIN/python -m pip install -U edge-tts" >&2
      continue
    fi
    [ "$attempt" -lt "$RETRIES" ] || return 1
    printf 'retry %d… ' "$attempt" >&2
    attempt=$((attempt + 1))
    sleep 2
  done
}

# Auditioning reads one sentence in each candidate voice and stops there: the
# user picks by ear, which no description of a voice substitutes for. It uses
# the real opening line when there is a script, so they judge the voice on the
# words it will actually say.
if [ -n "$AUDITION" ]; then
  if [ -z "$SAMPLE_TEXT" ] && [ -n "$JOB" ] && [ -f "$JOB/script.md" ]; then
    SAMPLE_TEXT="$(scene_records "$JOB/script.md" | awk -F'\t' '$2 != "" { print $2; exit }')"
  fi
  [ -n "$SAMPLE_TEXT" ] || { echo "--audition needs --text \"...\" or a <job> with script.md" >&2; exit 1; }
  OUTDIR="${JOB:-.}/voice-samples"
  mkdir -p "$OUTDIR"
  echo "rate: $RATE   pitch: $PITCH" >&2
  OK=0
  for V in $(printf '%s' "$AUDITION" | tr ',' ' '); do
    printf '  %-36s ' "$V" >&2
    if speak "$V" "$SAMPLE_TEXT" "$OUTDIR/$V.mp3"; then
      echo "$OUTDIR/$V.mp3" >&2; OK=$((OK + 1))
    else
      echo "FAILED — $(tail -1 "$ERRLOG")" >&2
    fi
  done
  [ "$OK" -gt 0 ] || exit 1
  echo "$OUTDIR"
  exit 0
fi

[ -n "$JOB" ] || { echo "usage: narrate.sh <job> --voice <name>   (or --voices <lang>)" >&2; exit 1; }
SCRIPT_MD="$JOB/script.md"
[ -f "$SCRIPT_MD" ] || { echo "no $SCRIPT_MD — write the narration script first" >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo "ffprobe not found — install ffmpeg" >&2; exit 1; }

PROJECT="${PROJECT:-$JOB/project}"
AUDIO="$PROJECT/public/audio"
mkdir -p "$AUDIO" "$PROJECT/src"

RECORDS="$(scene_records "$SCRIPT_MD")"

[ -n "$RECORDS" ] || { echo "no '## <scene-id>' sections found in $SCRIPT_MD" >&2; exit 1; }

# Checking what will actually be spoken costs nothing; discovering that an
# editorial note got read aloud costs a re-render.
if [ "$DRY_RUN" = "1" ]; then
  printf '%s\n' "$RECORDS" | awk -F'\t' '{ printf "## %s\n%s\n\n", $1, ($2 == "" ? "(empty — will be skipped)" : $2) }'
  exit 0
fi

echo "voice: $VOICE   rate: $RATE   pitch: $PITCH   fps: $FPS   pad: ${PAD_FRAMES}f" >&2

IDS=(); FILES=(); DURS=(); FRAMES=(); FROMS=(); FIELDS=()
FROM=0

while IFS="$(printf '\t')" read -r RAW_ID TEXT; do
  [ -n "${TEXT:-}" ] || { echo "skipping '$RAW_ID' — no narration text under the heading" >&2; continue; }
  # The id becomes a filename and a TypeScript value, so normalise it once.
  ID="$(printf '%s' "$RAW_ID" | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-*//' -e 's/-*$//')"
  [ -n "$ID" ] || { echo "heading '$RAW_ID' has no usable characters — skipped" >&2; continue; }

  OUT="$AUDIO/$ID.mp3"
  printf '  %-20s ' "$ID" >&2

  if ! speak "$VOICE" "$TEXT" "$OUT"; then
    echo "FAILED after ${RETRIES} attempts" >&2
    sed 's/^/    /' "$ERRLOG" >&2
    echo "    if this says 403, upgrade: $BIN/python -m pip install -U edge-tts" >&2
    echo "    if this says NoAudioReceived it is usually transient — rerun." >&2
    echo "    if it names the voice, list valid ones: narrate.sh --voices <lang>" >&2
    exit 1
  fi
  F_JSON="$SPOKEN"

  DUR="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT" </dev/null | head -1)"
  [ -n "$DUR" ] || { echo "FAILED — no duration from ffprobe" >&2; exit 1; }
  # Round up: a scene one frame short clips the final consonant.
  F="$(awk -v d="$DUR" -v fps="$FPS" -v pad="$PAD_FRAMES" \
       'BEGIN { n = d * fps; printf "%d", (n == int(n) ? n : int(n) + 1) + pad }')"

  IDS+=("$ID"); FILES+=("audio/$ID.mp3"); DURS+=("$DUR"); FRAMES+=("$F"); FROMS+=("$FROM")
  FIELDS+=("$F_JSON")
  FROM=$((FROM + F))
  awk -v d="$DUR" -v f="$F" 'BEGIN { printf "%.2fs  %d frames\n", d, f }' >&2
done <<EOF
$RECORDS
EOF

[ "${#IDS[@]}" -gt 0 ] || { echo "nothing was generated" >&2; exit 1; }

# The type and helpers live in a static file beside the generated data, so the
# shape is defined once and typechecked, not echoed from a shell script.
[ -f "$PROJECT/src/narration.ts" ] || cp "$SCRIPT_DIR/../assets/narration.ts" "$PROJECT/src/"

CONFIG="$PROJECT/src/audioConfig.ts"
{
  echo "// Generated by scripts/narrate.sh — do not edit by hand."
  echo "// Regenerate after every change to script.md; the composition's timing"
  echo "// is derived from these numbers, not the other way round."
  echo "// voice: ${VOICE}   rate: ${RATE}   pitch: ${PITCH}"
  echo
  echo "import type { NarrationScene } from './narration';"
  echo
  echo "export const FPS = ${FPS};"
  echo
  echo "export const SCENES: NarrationScene[] = ["
  i=0
  while [ "$i" -lt "${#IDS[@]}" ]; do
    # The text/words JSON goes through printf %s, never awk -v, which would
    # interpret the backslashes JSON uses for escaping.
    awk -v id="${IDS[$i]}" -v file="${FILES[$i]}" -v d="${DURS[$i]}" \
        -v f="${FRAMES[$i]}" -v from="${FROMS[$i]}" \
        'BEGIN { printf "  { id: \"%s\", file: \"%s\", durationInSeconds: %.2f, frames: %d, from: %d,\n", id, file, d, f, from }'
    printf '    %s },\n' "${FIELDS[$i]}"
    i=$((i + 1))
  done
  echo "];"
  echo
  echo "export const TOTAL_FRAMES = ${FROM};"
} > "$CONFIG"

awk -v n="${#IDS[@]}" -v t="$FROM" -v fps="$FPS" \
  'BEGIN { printf "\n%d scene(s), %d frames total (%.1fs)\n", n, t, t / fps }' >&2
echo "audio:  $AUDIO/" >&2
echo "config: $CONFIG" >&2
echo "next: drive every <Sequence> from SCENES — never hardcode a duration" >&2
echo "$CONFIG"
