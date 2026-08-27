#!/usr/bin/env bash
# Create a job folder in the video-projects workspace and register it in INDEX.md.
#
#   ./new_project.sh barbershop-promo
#   ./new_project.sh barbershop-promo /path/to/workspace
#
# Prints the job directory path on stdout so callers can cd into it.
set -euo pipefail

RAW_SLUG="${1:?usage: new_project.sh <slug> [workspace-root]}"
ROOT="${2:-video-projects}"

# The agent derives the slug from a free-form idea, so it can arrive with
# spaces, capitals or punctuation. It then becomes a directory name, an INDEX.md
# cell and a sed replacement — normalise once here so nothing downstream has to
# escape it. A '/' used to split the job folder in two and abort the sed; a '&'
# used to expand into the matched text and corrupt the brief heading.
SLUG="$(printf '%s' "$RAW_SLUG" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-*//' -e 's/-*$//')"
[ -n "$SLUG" ] || { echo "slug has no usable characters: $RAW_SLUG" >&2; exit 1; }
[ "$SLUG" = "$RAW_SLUG" ] || echo "slug normalised to: $SLUG" >&2

DATE="$(date +%Y-%m-%d)"
JOB="${ROOT}/${DATE}-${SLUG}"

if [ -d "$JOB" ]; then
  echo "job already exists: $JOB" >&2
  echo "$JOB"
  exit 0
fi

mkdir -p "$JOB"/{project,assets,frames,out}
mkdir -p "$ROOT"/_shared/{brand,music} "$ROOT"/_archive

# Workspace index — created once, appended to per job.
INDEX="${ROOT}/INDEX.md"
if [ ! -f "$INDEX" ]; then
  cat > "$INDEX" <<'EOF'
# Video projects

| Date | Job | Track | Output | Status |
|---|---|---|---|---|
EOF
fi
# Insert the new row directly under the header so newest stays first.
awk -v row="| ${DATE} | ${SLUG} | – | – | in progress |" '
  { print }
  /^\|---\|/ && !done { print row; done=1 }
' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"

# Seed the brief from the skill's template so the job starts from structure,
# not from a blank file.
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$SKILL_DIR/assets/brief-template.md" ]; then
  sed "s/<project name>/${SLUG}/; s/<date>/${DATE}/" \
    "$SKILL_DIR/assets/brief-template.md" > "$JOB/brief.md"
fi

cat > "$JOB/NOTES.md" <<EOF
# ${SLUG} — decision log

## ${DATE} · v0
Job created. Brief not yet filled.
EOF

cat > "$JOB/.gitignore" <<'EOF'
frames/
project/node_modules/
out/*.mp4
EOF

echo "created ${JOB}" >&2
echo "next: fill in ${JOB}/brief.md" >&2
echo "$JOB"
