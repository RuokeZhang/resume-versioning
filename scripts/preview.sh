#!/bin/bash
# Render resume drivers to PDF locally, without Overleaf.
#
#   ./preview.sh                          # every driver in the repo
#   ./preview.sh Example_Resume.tex       # just one
#   OUT=/tmp/x ./preview.sh               # choose the output directory
#
# Requires tectonic (brew install tectonic).
#
# Two differences from Overleaf are handled here. Both are easy to rediscover
# the hard way, which is why rendering should go through this script rather
# than a bare `tectonic` call:
#
#   - Overleaf resolves \input from the project root; tectonic resolves it
#     from the main file's directory. So the driver is staged at a temp root.
#   - Overleaf runs pdfLaTeX; tectonic runs XeTeX, which has no \pdfgentounicode
#     or \pdfglyphtounicode. They are stubbed in the staged copy only. The real
#     files keep them, so Overleaf output is unaffected.
set -euo pipefail

# REPO may be set explicitly (verify.sh renders a detached worktree this way);
# otherwise use the repo containing the current directory.
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
OUT="${OUT:-$REPO/build}"

if ! command -v tectonic >/dev/null; then
  echo "tectonic not found. Install with: brew install tectonic" >&2
  exit 1
fi

mkdir -p "$OUT"

# Directories holding retired standalone resumes. They declare their own
# \documentclass, so without this they are picked up as drivers and rendered
# on every run. Override with EXCLUDE="LEGACY|old|drafts".
EXCLUDE="${EXCLUDE:-LEGACY|legacy|archive|ARCHIVE}"

drivers=("$@")
if [ ${#drivers[@]} -eq 0 ]; then
  # Any .tex declaring a documentclass is a driver; templates and content are
  # not. The optional ./ matters: GNU grep prefixes matches with ./ and BSD
  # grep does not, so anchoring on it silently disables every exclusion on
  # macOS.
  while IFS= read -r f; do drivers+=("${f#./}"); done < <(
    cd "$REPO" && grep -rl '\\documentclass' --include='*.tex' . \
      | grep -vE "^(\./)?(templates|content|profiles)/" \
      | grep -vE "^(\./)?($EXCLUDE)/" | sort
  )
fi

if [ ${#drivers[@]} -eq 0 ]; then
  echo "no drivers found under $REPO" >&2
  exit 1
fi

# rsync is not installed on every minimal Linux image; fall back to tar, which
# is. Both need to skip .git and build/ -- copying them is slow and pointless.
stage_repo() {  # stage_repo() <src> <dest>
  if command -v rsync >/dev/null; then
    rsync -a --exclude .git --exclude build "$1/" "$2/"
  else
    (cd "$1" && tar --exclude=.git --exclude=build -cf - .) | (cd "$2" && tar -xf -)
  fi
}

status=0
for driver in "${drivers[@]}"; do
  label=$(basename "$driver" .tex)
  stage=$(mktemp -d)
  stage_repo "$REPO" "$stage"
  awk '/\\documentclass/ && !done {
         print
         print "\\newcount\\pdfgentounicode"
         print "\\providecommand{\\pdfglyphtounicode}[2]{}"
         done=1; next
       } {print}' "$stage/$driver" > "$stage/__main.tex"

  if tectonic -X compile "$stage/__main.tex" --outdir "$stage" >"$stage/log.txt" 2>&1; then
    cp "$stage/__main.pdf" "$OUT/$label.pdf"
    echo "ok    $OUT/$label.pdf"
  else
    echo "FAIL  $driver"
    grep -iE "^error|! " "$stage/log.txt" | head -5 || true
    status=1
  fi
  rm -rf "$stage"
done
exit $status
