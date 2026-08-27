#!/usr/bin/env bash
# Create (or reuse) a Python virtualenv in the current working directory and
# install the tools a video job needs.
#
#   ./setup_python_env.sh                     # ./.venv with edge-tts
#   ./setup_python_env.sh yt-dlp openai-whisper
#   ./setup_python_env.sh --dir tools/.venv edge-tts
#
# Prints the venv's bin directory on stdout. Call tools by that path —
# `source .venv/bin/activate` does not survive between agent shell calls.
set -euo pipefail

VENV_DIR=".venv"
# Only used when the interpreters already on this machine turn out to be
# unusable and uv has to fetch a managed one.
PYTHON_PIN="${IDEA_TO_VIDEO_PYTHON:-3.12}"
PKGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) VENV_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --dir=*) VENV_DIR="${1#--dir=}"; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) PKGS+=("$1"); shift ;;
  esac
done

# The script deletes and rebuilds $VENV_DIR, so refuse any path where that would
# mean something other than "throw away a virtualenv".
case "${VENV_DIR%/}" in
  ""|.|..|/) echo "--dir must name a directory, not '$VENV_DIR'" >&2; exit 1 ;;
esac
if [ -e "$VENV_DIR" ] && [ ! -e "$VENV_DIR/pyvenv.cfg" ]; then
  echo "$VENV_DIR exists and is not a virtualenv — refusing to replace it" >&2
  exit 1
fi

# edge-tts is the default because it is the one Python dependency the narration
# work always needs and it costs nothing to install.
[ ${#PKGS[@]} -gt 0 ] || PKGS=(edge-tts)

# A venv whose interpreter cannot import ssl is useless here — every tool this
# skill installs has to fetch something over HTTPS. macOS pyenv builds break
# this way routinely, when Homebrew retires the openssl they were compiled
# against, and the failure surfaces much later as a confusing ImportError.
venv_is_usable() {
  [ -x "$VENV_DIR/bin/python" ] && "$VENV_DIR/bin/python" -c 'import ssl' >/dev/null 2>&1
}

# uv first: it is fast and brings its own interpreters. But it resolves a
# version from ~/.python-version and UV_PYTHON before it looks at what is
# installed, so a stale pyenv name up in $HOME makes it fail on a machine with
# perfectly good Python. --python overrides that discovery on the second try.
# --seed puts pip in the venv so the pip fallback below has something to run.
try_uv()        { command -v uv >/dev/null 2>&1 && uv venv --seed "$VENV_DIR" >&2; }
try_uv_pinned() { command -v uv >/dev/null 2>&1 && uv venv --seed --python "$PYTHON_PIN" "$VENV_DIR" >&2; }
try_python3()   { command -v python3 >/dev/null 2>&1 && python3 -m venv "$VENV_DIR" >&2; }

if venv_is_usable; then
  echo "reusing venv: $VENV_DIR" >&2
else
  # Guarded with if, not &&: a bare false compound would trip `set -e`.
  if [ -e "$VENV_DIR" ]; then
    echo "existing $VENV_DIR has no working ssl — rebuilding" >&2
  fi
  BUILT=""
  for strategy in try_uv try_uv_pinned try_python3; do
    rm -rf "$VENV_DIR"
    "$strategy" || continue
    if venv_is_usable; then BUILT="$strategy"; break; fi
    echo "${strategy#try_}: venv cannot import ssl — trying the next option" >&2
  done
  if [ -z "$BUILT" ]; then
    echo "could not build a working venv. Install uv (curl -LsSf https://astral.sh/uv/install.sh | sh)" >&2
    echo "or repair python3, then rerun. Track C needs no Python at all." >&2
    exit 1
  fi
  echo "created venv: $VENV_DIR (${BUILT#try_})" >&2
fi

PY="$VENV_DIR/bin/python"

# Reruns are common — the agent calls this again when a later beat needs another
# tool — so only install what is actually absent.
MISSING=()
for pkg in "${PKGS[@]}"; do
  # Strip version pins and extras: "edge-tts>=7.0" and "foo[bar]" both query "edge-tts"/"foo".
  name="$(printf '%s' "$pkg" | sed -e 's/[][<>=!~;].*//' -e 's/[[:space:]]*$//')"
  if "$PY" -c 'import importlib.metadata as m, sys; m.version(sys.argv[1])' "$name" >/dev/null 2>&1; then
    echo "already installed: $name" >&2
  else
    MISSING+=("$pkg")
  fi
done

install_missing() {
  if command -v uv >/dev/null 2>&1; then
    uv pip install --python "$PY" "${MISSING[@]}" >&2 && return 0
    echo "uv pip install failed — falling back to pip" >&2
  fi
  "$PY" -m pip install --quiet --upgrade pip >&2
  "$PY" -m pip install "${MISSING[@]}" >&2
}

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "nothing to install" >&2
elif ! install_missing; then
  echo "could not install: ${MISSING[*]}" >&2
  exit 1
fi

# Keep the venv out of version control without the user having to notice it
# exists. Only for a relative path inside this repo — an explicit --dir pointing
# elsewhere is not ours to ignore.
case "$VENV_DIR" in
  /*|*..*) ;;
  *)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      ENTRY="${VENV_DIR%/}/"
      if [ ! -f .gitignore ] || ! grep -qxF "$ENTRY" .gitignore; then
        # A .gitignore whose last line lacks a newline would otherwise absorb our entry.
        if [ -f .gitignore ] && [ -n "$(tail -c 1 .gitignore 2>/dev/null)" ]; then
          printf '\n' >> .gitignore
        fi
        printf '%s\n' "$ENTRY" >> .gitignore
        echo "added ${ENTRY} to .gitignore" >&2
      fi
    fi
    ;;
esac

BIN="$(cd "$VENV_DIR/bin" && pwd)"
echo "ready: $BIN" >&2
echo "call tools by path (e.g. ${VENV_DIR}/bin/edge-tts) — do not activate" >&2
echo "$BIN"
