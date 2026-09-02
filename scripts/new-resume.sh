#!/bin/bash
# Create a driver: a resume is a selection, never a copy.
#
#   ./new-resume.sh <profile> <template> <content> [outfile]
#   ./new-resume.sh alex classic backend SDE/Alex_SDE.tex
#
# Copying an existing driver is the thing this exists to prevent -- a copied
# driver carries wording with it, and the two copies then drift.
set -euo pipefail

if [ $# -lt 3 ]; then
  sed -n '2,9p' "$0" | sed 's/^# \?//'
  exit 1
fi

PROFILE="$1"; TEMPLATE="$2"; CONTENT="$3"
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTFILE="${4:-$(printf '%s_%s.tex' "$(echo "${PROFILE:0:1}" | tr '[:lower:]' '[:upper:]')${PROFILE:1}" "$CONTENT")}"

for f in "profiles/$PROFILE.tex" "templates/$TEMPLATE.tex" "content/$CONTENT.tex"; do
  if [ ! -f "$REPO/$f" ]; then
    echo "missing: $f" >&2
    echo "available:" >&2
    ls "$REPO/$(dirname "$f")" 2>/dev/null | sed 's/^/  /' >&2
    exit 1
  fi
done

if [ -e "$REPO/$OUTFILE" ]; then
  echo "refusing to overwrite existing $OUTFILE" >&2
  exit 1
fi

# Switches the chosen content actually reads, so the driver declares exactly
# those and no stale ones.
switches=$(grep -o '\\ifResume[A-Za-z]*' "$REPO/content/$CONTENT.tex" | sort -u | sed 's/\\if//')

mkdir -p "$(dirname "$REPO/$OUTFILE")"
{
  printf '%% %s resume: %s profile, %s template, %s content.\n' \
    "$(basename "$OUTFILE" .tex)" "$PROFILE" "$TEMPLATE" "$CONTENT"
  printf '\\documentclass[letterpaper,11pt]{article}\n\n'
  printf '\\newif\\ifResumeTimes\n\\ResumeTimesfalse\n'
  for s in $switches; do
    [ "$s" = "ResumeTimes" ] && continue
    printf '\\newif\\if%s\n\\%strue\n' "$s" "$s"
  done
  printf '\n\\input{profiles/%s.tex}\n' "$PROFILE"
  printf '\\input{templates/%s.tex}\n\n' "$TEMPLATE"
  printf '\\begin{document}\n\\ResumeHeader\n\\input{content/%s.tex}\n\\end{document}\n' "$CONTENT"
} > "$REPO/$OUTFILE"

echo "created $OUTFILE"
echo "render it with: scripts/preview.sh $OUTFILE"
