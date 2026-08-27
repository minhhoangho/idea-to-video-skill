#!/usr/bin/env bash
# Package the skill into dist/idea-to-video.skill for upload to
# Claude Desktop / claude.ai (Settings → Capabilities → Skills).
#
#   ./scripts/build.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="idea-to-video"
DIST="${ROOT}/dist"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cd "$ROOT"
[ -f "${SKILL}/SKILL.md" ] || { echo "SKILL.md not found" >&2; exit 1; }

VERSION="$(grep -E '^\s+version:' "${SKILL}/SKILL.md" | head -1 | tr -d ' "' | cut -d: -f2)"
VERSION="${VERSION:-dev}"

cp -r "$SKILL" "$STAGE/"
# README lives at the repo root for GitHub, but ships inside the bundle so a
# .skill install still carries its own instructions.
cp README.md "$STAGE/${SKILL}/README.md"
find "$STAGE" -name '.DS_Store' -delete
chmod +x "$STAGE/${SKILL}"/scripts/*.sh

mkdir -p "$DIST"
rm -f "${DIST}/${SKILL}.skill"
(cd "$STAGE" && zip -qr "${DIST}/${SKILL}.skill" "$SKILL")

echo "built ${DIST}/${SKILL}.skill  (v${VERSION}, $(du -h "${DIST}/${SKILL}.skill" | cut -f1))"
