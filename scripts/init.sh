#!/bin/bash
# Scaffold a resume repo with the four-axis layout.
#
#   ./init.sh [dir]
#
# Creates profiles/, templates/, content/, CONTENT_LIBRARY/ and one example
# driver, then renders it to prove the toolchain works. Existing files are
# never overwritten, so this is safe to run inside a repo that already has
# some of the structure.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$(cd "$HERE/../assets" && pwd)"
TARGET="${1:-.}"

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

copy() {  # copy() <src> <dest-relative>
  if [ -e "$TARGET/$2" ]; then
    echo "keep    $2"
  else
    mkdir -p "$(dirname "$TARGET/$2")"
    cp "$1" "$TARGET/$2"
    echo "create  $2"
  fi
}

copy "$ASSETS/templates/classic.tex"              templates/classic.tex
copy "$ASSETS/templates/engineering.tex"          templates/engineering.tex
copy "$ASSETS/profiles/example.tex"               profiles/example.tex
copy "$ASSETS/content/example-role.tex"           content/example-role.tex
copy "$ASSETS/CONTENT_LIBRARY/README.md"          CONTENT_LIBRARY/README.md
copy "$ASSETS/CONTENT_LIBRARY/EXPERIENCE/Example.md" CONTENT_LIBRARY/EXPERIENCE/Example.md
copy "$HERE/../references/INTERFACE.md"           templates/INTERFACE.md
copy "$HERE/preview.sh"                           scripts/preview.sh
copy "$HERE/verify.sh"                            scripts/verify.sh
copy "$HERE/new-resume.sh"                        scripts/new-resume.sh
copy "$HERE/pdfhash.py"                           scripts/pdfhash.py
chmod +x "$TARGET"/scripts/*.sh 2>/dev/null || true

if [ ! -e "$TARGET/.gitignore" ]; then
  printf 'build/\n*.aux\n*.log\n*.out\n*.synctex.gz\n' > "$TARGET/.gitignore"
  echo "create  .gitignore"
fi

if [ ! -e "$TARGET/Example_Resume.tex" ]; then
  cat > "$TARGET/Example_Resume.tex" <<'EOF'
% Example driver: example profile, classic template, example-role content.
\documentclass[letterpaper,11pt]{article}

\newif\ifResumeTimes
\ResumeTimesfalse
\newif\ifResumeIncludeEarlyRoles
\ResumeIncludeEarlyRolestrue

\input{profiles/example.tex}
\input{templates/classic.tex}

\begin{document}
\ResumeHeader
\input{content/example-role.tex}
\end{document}
EOF
  echo "create  Example_Resume.tex"
fi

echo
echo "Structure:"
echo "  profiles/   one file per identity"
echo "  templates/  one file per visual style; see templates/INTERFACE.md"
echo "  content/    one file per target role -- wording only, no layout"
echo "  *.tex       drivers: a selection of the three"
echo
if command -v tectonic >/dev/null; then
  echo "Rendering the example to check the toolchain ..."
  (cd "$TARGET" && REPO="$TARGET" ./scripts/preview.sh Example_Resume.tex)
else
  echo "Install tectonic to render locally: brew install tectonic"
fi
