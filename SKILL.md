---
name: resume-versioning
description: |
  Maintain a LaTeX resume repository where one set of wording renders as many
  resumes -- several identities (different names, emails, phone numbers),
  several target roles, and several visual templates -- with the wording stored
  exactly once. Use when asked to "add a resume variant", "add a new
  template/persona/role", "change a resume bullet", "set up a resume repo",
  "tailor my resume", or "push my resume to Overleaf"; and whenever editing
  .tex resume files that share content between documents. Also covers archiving
  replaced wording and refusing to guess at conflicting facts or metrics.
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
---

# Resume versioning

A resume repo drifts when the same wording exists in two files. This skill
keeps it in one, and verifies that restructuring did not silently change any
rendered PDF.

## The four axes

Every resume is a selection, never a copy:

```
profiles/<person>.tex  ×  templates/<layout>.tex  ×  content/<target>.tex  +  switches
```

| Directory | Holds | One file per |
|---|---|---|
| `profiles/` | name, email, phone, links | identity |
| `templates/` | all layout; implements the command interface | visual style |
| `content/` | wording only, zero layout markup | target |
| drivers | a selection of the three, plus switches | finished resume |
| `CONTENT_LIBRARY/` | archived and candidate wording, in Markdown | topic |

A driver is ~12 lines. If a driver contains a sentence that appears on the
printed page, the structure is already broken.

## Invariants

These are the failure modes this layout exists to prevent. Each one has been
hit in practice.

1. **Wording lives only in `content/`.** Never edit wording in a driver, and
   never copy a content file to make a variant. The tempting shortcut --
   "just this one resume needs a different template, I'll copy the file" --
   is what creates two copies that then drift apart independently.

2. **Content carries no layout.** No `\vspace`, no `\begin{itemize}`, no
   `\textbf` used for structure. One template's hand-tuned negative kerning is
   actively wrong under another template's metrics: it overlaps headings with
   body text. Use `\resumeTighten{<len>}`, which a template may ignore.

3. **Archive before replacing.** Copy outgoing wording into the matching
   `CONTENT_LIBRARY/` file and mark it `ARCHIVED` with a date, before writing
   the replacement. See `references/content-library.md`.

4. **Never resolve a conflicting fact by guessing.** Conflicting metrics, dates,
   titles, or URLs across files are drift, and only the user knows which is
   correct. Surface the conflict and ask. Never average, never pick the newer
   file, never pick the one that sounds better.

5. **Verify every structural change by rendering.** A refactor that changes a
   PDF is a bug unless the user asked for that change. See below.

## Tasks

| Request | Do this |
|---|---|
| Set up a new repo | `scripts/init.sh <dir>`, then read `references/INTERFACE.md` |
| Add a person | One new file in `profiles/`. Nothing else. |
| Add a target | One new file in `content/`, plus a driver per person |
| Add a visual template | Implement every command in `references/INTERFACE.md` |
| Add a resume | `scripts/new-resume.sh` -- never copy an existing driver |
| Change wording | Edit `content/`, archive the old text, then verify |
| Preview | `scripts/preview.sh` -- renders locally, no Overleaf needed |
| Check a refactor | `scripts/verify.sh` -- see below |
| Push to Overleaf | `references/overleaf.md` |

## Verifying a structural change

The point of a refactor is that nothing renders differently. `scripts/verify.sh`
renders every driver at git HEAD and again in the working tree, then compares
the decompressed PDF content streams:

```
NAME                  HEAD              WORKING           STATUS
Example_Resume        97080675e88112c4  97080675e88112c4  IDENTICAL
Second_Resume         5cfb6ff174e44187  cc42fc296a5e29eb  CHANGED
```

Report the table. Then, for every `CHANGED` row, either explain the intended
reason or treat it as a regression and fix it. Do not describe a refactor as
complete while an unexplained `CHANGED` row exists.

Byte-identical hashes prove the layout is untouched but say nothing about
whether a *deliberate* change looks good. For those, render to PNG and look at
it:

```bash
sips -s format png -Z 1500 --out out.png build/<name>.pdf   # macOS
pdftoppm -png -r 150 build/<name>.pdf out                   # Linux (poppler)
```

Read the image. Check for overlapping text, bad line wraps, and page overflow.
Hashes cannot catch a heading that now sits on top of a bullet.

## Local rendering is not Overleaf

`scripts/preview.sh` uses `tectonic`, which differs from Overleaf in two ways
that will waste an hour if rediscovered. Both are handled inside the script,
which is why rendering should go through it rather than a bare `tectonic` call.

- Overleaf resolves `\input{dir/file.tex}` from the **project root**; tectonic
  resolves it from the **main file's directory**. The script stages the driver
  at a temporary root.
- Overleaf runs pdfLaTeX; tectonic runs XeTeX, which lacks the pdfTeX
  primitives `glyphtounicode` needs. The script stubs them **for the preview
  only** — the real files keep them, so Overleaf output is unaffected.

Because of the second point, local verification cannot fully prove Overleaf
output. After a structural change, say so and ask the user to confirm in
Overleaf.

## Privacy

Templates and scaffolding in `assets/` are placeholders. When helping a user,
their wording, metrics, and contact details belong in their repo only — never
copy them into this skill, into examples, or into anything published.
