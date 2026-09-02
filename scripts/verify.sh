#!/bin/bash
# Prove a structural change did not alter any rendered resume.
#
#   ./verify.sh            # working tree vs HEAD
#   ./verify.sh <ref>      # working tree vs any commit
#
# Renders every driver at both revisions and compares PDF content-stream
# fingerprints. A refactor should be IDENTICAL everywhere; anything CHANGED is
# either an intended edit or a regression, and must be explained either way.
#
# HEAD is rendered from a detached worktree, so the working tree is never
# stashed, checked out over, or otherwise disturbed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_REF="${1:-HEAD}"

REPO="$(git rev-parse --show-toplevel)"
TMP="$(mktemp -d)"
BASE_TREE="$TMP/base"
cleanup() {
  git -C "$REPO" worktree remove --force "$BASE_TREE" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

# A render failure must be loud. Swallowing preview.sh output and letting
# set -e kill the script leaves the user staring at "rendering ..." with no
# error at all -- and a LaTeX error is by far the likeliest reason to be
# running this in the first place.
render() {  # render() <label> <repo> <outdir>
  if ! REPO="$2" OUT="$3" "$HERE/preview.sh" >"$TMP/$1.log" 2>&1; then
    echo
    echo "$1 failed to render:"
    sed 's/^/  /' "$TMP/$1.log"
    exit 1
  fi
}

echo "rendering $BASE_REF ..."
git -C "$REPO" worktree add --detach --quiet "$BASE_TREE" "$BASE_REF"

# A worktree that exists but is empty produces a confusing "no drivers found"
# from preview.sh, which points at the wrong problem. Fail here instead, with
# something actionable.
if [ -z "$(ls -A "$BASE_TREE" 2>/dev/null)" ]; then
  echo "worktree for $BASE_REF is empty at $BASE_TREE" >&2
  echo "try: git worktree prune, then re-run" >&2
  exit 1
fi

render base "$BASE_TREE" "$TMP/base-pdf"

echo "rendering working tree ..."
render work "$REPO" "$TMP/work-pdf"

echo
printf '%-28s %-18s %-18s %s\n' NAME "${BASE_REF:0:18}" WORKING STATUS
changed=0
added=0
removed=0
for f in "$TMP"/work-pdf/*.pdf; do
  name=$(basename "$f" .pdf)
  base="$TMP/base-pdf/$name.pdf"
  work=$(python3 "$HERE/pdfhash.py" "$f" | awk '{print $1}')
  if [ ! -f "$base" ]; then
    printf '%-28s %-18s %-18s %s\n' "$name" "-" "$work" "NEW"
    added=$((added + 1))
    continue
  fi
  bhash=$(python3 "$HERE/pdfhash.py" "$base" | awk '{print $1}')
  if [ "$bhash" = "$work" ]; then
    printf '%-28s %-18s %-18s %s\n' "$name" "$bhash" "$work" "IDENTICAL"
  else
    printf '%-28s %-18s %-18s %s\n' "$name" "$bhash" "$work" "CHANGED"
    changed=$((changed + 1))
  fi
done

for f in "$TMP"/base-pdf/*.pdf; do
  name=$(basename "$f" .pdf)
  if [ ! -f "$TMP/work-pdf/$name.pdf" ]; then
    printf '%-28s %-18s %-18s %s\n' "$name" "?" "-" "REMOVED"
    removed=$((removed + 1))
  fi
done

echo
summary=""
[ "$changed" -gt 0 ] && summary="$changed changed"
[ "$added" -gt 0 ] && summary="${summary:+$summary, }$added added"
[ "$removed" -gt 0 ] && summary="${summary:+$summary, }$removed removed"

if [ -z "$summary" ]; then
  echo "no rendered output changed"
else
  echo "$summary -- account for each one or treat it as a regression"
fi
