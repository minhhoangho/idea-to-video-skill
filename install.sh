#!/usr/bin/env bash
# Install the idea-to-video skill for Claude Code.
#
#   ./install.sh              # user-wide, ~/.claude/skills
#   ./install.sh --project    # this repo only, ./.claude/skills
#   ./install.sh --uninstall
#
set -euo pipefail

SKILL="idea-to-video"
SRC="$(cd "$(dirname "$0")" && pwd)/${SKILL}"
DEST_ROOT="${HOME}/.claude/skills"
SCOPE="user-wide"

for arg in "$@"; do
  case "$arg" in
    --project) DEST_ROOT="$(pwd)/.claude/skills"; SCOPE="this project" ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

DEST="${DEST_ROOT}/${SKILL}"

if [ "${UNINSTALL:-0}" = "1" ]; then
  [ -d "$DEST" ] || { echo "not installed at $DEST"; exit 0; }
  rm -rf "$DEST"
  echo "removed $DEST"
  exit 0
fi

[ -f "${SRC}/SKILL.md" ] || { echo "SKILL.md not found in ${SRC}" >&2; exit 1; }

mkdir -p "$DEST_ROOT"
if [ -d "$DEST" ]; then
  echo "replacing existing install at $DEST"
  rm -rf "$DEST"
fi
cp -r "$SRC" "$DEST"
chmod +x "$DEST"/scripts/*.sh

echo "installed ${SKILL} (${SCOPE}) → ${DEST}"
echo

# Report what's available, since the skill's capability depends on it.
have() { command -v "$1" >/dev/null 2>&1; }
echo "Track A (motion graphics):"
have node && echo "  node    $(node --version)" || echo "  node    MISSING — install Node.js 18+"
have ffmpeg && echo "  ffmpeg  present" || echo "  ffmpeg  MISSING — needed to verify renders"
echo "Track B (stock + voice-over):"
have uv && echo "  uv      present" || echo "  uv      MISSING — curl -LsSf https://astral.sh/uv/install.sh | sh"
have python3 && echo "  python3 $(python3 --version 2>&1 | cut -d' ' -f2)" || echo "  python3 MISSING — needed for ./.venv when uv is absent"
echo
echo "Track C (storyboard) needs nothing and always works."
echo "Start a new Claude Code session, then check /skills."
