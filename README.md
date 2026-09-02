# resume-versioning

A Claude Code skill for LaTeX resume repos where one set of wording has to
become several documents.

## The problem

You have one resume. Then you need it under a different name for a different
email account. Then a version aimed at one kind of
role and a version aimed at another. Then someone tells you a different
visual template performs better, and you want that layout for one of them.

The obvious move is to copy the file and edit. Do that twice and you have four
documents that share 90% of their text, and no way to tell which copy has the
current wording. They drift. A metric gets updated in one and not the others.
An old inflated number survives in a file you forgot about.

This skill keeps the wording in exactly one place.

## The structure

Every resume is a selection, never a copy:

```
profiles/<person>.tex  ×  templates/<layout>.tex  ×  content/<target>.tex
```

| Directory | Holds | One file per |
|---|---|---|
| `profiles/` | name, email, phone, links | identity |
| `templates/` | all layout, implementing a shared command interface | visual style |
| `content/` | wording only, zero layout markup | target |
| drivers | a selection of the three, plus switches | finished resume |
| `CONTENT_LIBRARY/` | archived and candidate wording, in Markdown | topic |

A driver is about twelve lines:

```latex
\documentclass[letterpaper,11pt]{article}

\newif\ifResumeTimes
\ResumeTimesfalse

\input{profiles/example.tex}
\input{templates/classic.tex}

\begin{document}
\ResumeHeader
\input{content/example-role.tex}
\end{document}
```

Adding a person is one file. Adding a target is one file. Adding a visual
template means implementing the command interface in
[references/INTERFACE.md](references/INTERFACE.md) — after which every existing
resume can render in it.

## Install

```bash
git clone <this repo> ~/.claude/skills/resume-versioning
```

Claude Code picks it up automatically. Ask it to set up a resume repo, add a
variant, or change a bullet, and it will follow the conventions here.

To scaffold a repo without Claude:

```bash
~/.claude/skills/resume-versioning/scripts/init.sh ~/my-resume
```

## Verification

The reason this is a skill and not a blog post: restructuring a resume repo
should not change what any resume looks like, and that is checkable.

```bash
./scripts/verify.sh
```

renders every driver at git HEAD and again in the working tree, then compares
the decompressed PDF content streams:

```
NAME                  HEAD              WORKING           STATUS
Example_Resume        97080675e88112c4  97080675e88112c4  IDENTICAL
Second_Resume         5cfb6ff174e44187  cc42fc296a5e29eb  CHANGED
```

Anything `CHANGED` is either an edit you meant or a regression. There is no
third case.

```bash
./scripts/preview.sh          # render everything to build/
./scripts/preview.sh Example_Resume.tex
```

## Requirements

- `tectonic` for local rendering (`brew install tectonic`, or see
  [tectonic-typesetting.github.io](https://tectonic-typesetting.github.io))
- `python3` for the PDF fingerprint
- `git`

Local rendering is optional. If the repo lives in Overleaf, Overleaf compiles
it and none of the above is needed — the scripts exist so you can see a change
without pushing first.

## Overleaf

Overleaf projects are git remotes, so the repo can live there and be edited
locally. Two things to know, both handled by `preview.sh`:

- Overleaf resolves `\input{dir/file.tex}` from the project root; `tectonic`
  resolves it from the main file's directory.
- Overleaf runs pdfLaTeX; `tectonic` runs XeTeX, which lacks the pdfTeX
  primitives `glyphtounicode` needs.

Because of the second point, a local render is a good check but not proof of
Overleaf output. See [references/overleaf.md](references/overleaf.md).

## Provenance

The two bundled templates are adaptations of existing community resume
templates, not original designs. In both cases the visual settings come from
upstream; the `\resume*` command definitions are this project's own
implementation of its interface.

- `assets/templates/classic.tex` — from
  [Jake Gutierrez's resume](https://github.com/jakegut/resume) (MIT), itself
  based on [sb2nov/resume](https://github.com/sb2nov/resume)
- `assets/templates/engineering.tex` — adapted from the
  [r/EngineeringResumes](https://www.reddit.com/r/EngineeringResumes/wiki/)
  community wiki template

See [NOTICE](NOTICE) for full attribution and license terms.

## License

MIT — see [LICENSE](LICENSE).
