---
name: log-app
description: |
  Log a job application by recording which resume commit + driver (.tex) was
  submitted for which job. Appends one row to a local CSV so a future you can
  reconstruct exactly which PDF went to which company. Invoke when the user
  says "log this application", "/log-app", or provides a commit SHA + driver
  + job title. Companion to the resume-versioning skill.
allowed-tools: ["Read", "Write", "Edit", "Bash"]
---

# log-app

A resume repo built with `resume-versioning` renders many PDFs from one source.
After downloading a PDF and submitting it, you almost immediately forget which
commit + driver produced it. This skill turns that memory into one CSV row.

## Configuration

Two paths, both overridable via environment:

| Variable | Default | Meaning |
|---|---|---|
| `RESUME_OVERLEAF_DIR` | `~/Documents/RESUME/overleaf` | Local clone of the resume repo (Overleaf remote or otherwise). Read-only for this skill. |
| `RESUME_APPLICATIONS_CSV` | `~/Documents/RESUME/applications.csv` | Where the log rows are appended. Kept **outside** any published repo — it contains private application data. |

Resolve them once at the start of a run:

```bash
: "${RESUME_OVERLEAF_DIR:=$HOME/Documents/RESUME/overleaf}"
: "${RESUME_APPLICATIONS_CSV:=$HOME/Documents/RESUME/applications.csv}"
```

If `RESUME_OVERLEAF_DIR` does not exist, stop and tell the user to clone their
resume repo there or export the variable. Do not guess.

If `RESUME_APPLICATIONS_CSV` does not exist, create it with the header
`date,sha,driver,job_title,link,notes,pdf_path` before appending.

## Inputs

The user typically invokes this skill with **a job URL + a PDF path** — that
is the primary shape of the call. Both go straight into the row; do not
re-ask for what was already handed over.

- **pdf_path** — absolute path to the submitted PDF. **Almost always provided
  in the invocation.** Record it verbatim in the `pdf_path` column. Do not
  verify content, do not "look up" the file — just store the path.
- **job link** — the URL the user pasted. Fetch it to derive the job title
  (see step 5).
- **commit SHA + driver** — derive from the PDF: read its content and match
  against the resume repo (see step 4). Do not ask the user for these; they
  are inferable.
- **job title** — usually derived from the URL. Only ask if the fetch fails.

Only ask for something when it is genuinely missing. Never re-ask for the
pdf_path or link — they were in the invocation.

## Steps

1. **Sync the clone** so the SHA is resolvable:
   ```
   git -C "$RESUME_OVERLEAF_DIR" fetch --quiet
   ```

2. **Verify the SHA exists**:
   ```
   git -C "$RESUME_OVERLEAF_DIR" cat-file -e <sha>^{commit}
   ```
   If it fails, tell the user the SHA is not in the repo. Do not proceed.

3. **Resolve the SHA to its 12-char short form** for the log:
   ```
   git -C "$RESUME_OVERLEAF_DIR" rev-parse --short=12 <sha>
   ```

4. **Identify the (SHA, driver) that produced the PDF** by *content*, not by
   filename. The user renames PDFs freely after downloading, so
   `Ruoke_SDE_ML_March27.pdf` may contain MLE content, and so on. Read the
   PDF, then match distinctive fingerprints against `git log`:
   - **Persona** — name, email, phone in the header identifies which
     `profiles/*.tex` was used.
   - **Content structure** — SDE vs SDE-ML vs MLE variant is distinguishable
     from LinkedIn title ("Software Engineer Intern" vs "Machine Learning
     Engineer Intern"), whether Shanghai AI Lab / Virtual Hybrid appear,
     whether PUBLICATIONS is above or below PROJECTS, and the SKILLS row
     layout.
   - **Distinctive bullets** — `git log -S "<phrase>" --all` with a phrase
     copied from the PDF (a metric, a project bullet) usually pins the
     commit that introduced the exact wording.
   - **Cross-check with mtime** — the PDF's file mtime should land within
     minutes of the identified commit's timestamp. Strong sanity signal.

   Then confirm the driver file exists at that commit:
   ```
   git -C "$RESUME_OVERLEAF_DIR" ls-tree -r --name-only <sha> \
     | grep -E '\.tex$' | grep -Ev '^(content|templates|profiles|fonts)/'
   ```

5. **Fetch the URL** to get the job title (WebFetch). If the fetch redirects
   (e.g. Greenhouse `boards.greenhouse.io/embed/...` → `job-boards...`),
   follow the redirect. Never fabricate a title from the URL slug unless
   the fetch fails outright.

6. **Notes are optional** — leave empty unless the user provided some in the
   invocation.

7. **Append one CSV row** to `$RESUME_APPLICATIONS_CSV`. Fields:
   - `date` — today's date in `YYYY-MM-DD`
   - `sha` — 12-char short SHA
   - `driver` — path relative to the repo root, e.g. `SDE/Roxie_SDE_ML_Mar2027.tex`
   - `job_title` — as provided
   - `link` — as provided, or empty
   - `notes` — as provided, or empty
   - `pdf_path` — absolute path to the submitted PDF, from the invocation.
     Record verbatim.

   Quote any field containing a comma, double-quote, or newline (RFC 4180):
   wrap in `"..."` and escape internal `"` as `""`.

8. **Confirm** with one line: `Logged: <company/role snippet> @ <sha> using <driver>`.

## Do not

- Do not commit, push, checkout, or otherwise mutate the resume repo. Only
  `git fetch` and read-only queries.
- Do not put `$RESUME_APPLICATIONS_CSV` inside the resume repo or any other
  repo intended for publication. The default lives next to (not inside) the
  Overleaf clone for exactly this reason.
- Do not overwrite existing rows. Always append.
- Do not fabricate a link, company name, or role from the SHA or driver name.
  Ask the user.

## Recovering an old application

To find which PDF was submitted to a past job:

```bash
grep -F "<company>" "$RESUME_APPLICATIONS_CSV"
```

Take the `sha` and `driver` columns, then re-render:

```bash
git -C "$RESUME_OVERLEAF_DIR" checkout <sha> -- <driver>
# ... compile via Overleaf, tectonic, or resume-versioning's scripts/preview.sh
```

The row is the whole receipt: the source state and the file that was rendered.
