# Overleaf

Overleaf projects are git remotes, so a resume repo can live in Overleaf while
being edited locally.

```
https://git@git.overleaf.com/<project-id>
```

The password is an Overleaf **git token** (Account Settings → Git integration),
not the account password. If pushing needs credentials the user has not cached,
give them the command to run themselves rather than trying to capture a secret.

## What the bridge does and does not do

- It syncs **one branch only**. Pushing a side branch does not appear in the
  Overleaf UI. There is no branch-based review.
- It cannot **create** a project. There is no push-to-create. A new project must
  be made in the web UI first; only then does it have a git URL.
- Overleaf resolves `\input{dir/file.tex}` from the **project root**, so paths
  in drivers should be written root-relative.

## Previewing a restructure without touching the live project

Because the bridge is single-branch, the way to show a user a before/after is a
second project:

1. Ask the user to create a blank project and send its git URL. They must do
   this — it cannot be automated.
2. Clone it, copy in the working tree, commit, push.
3. Delete the placeholder `main.tex`. With several drivers present, the user
   picks one via **Menu → Main document**.

Leave the live project untouched until they have looked and approved.

## Before pushing to the live project

Pushing publishes. Confirm first unless the user has clearly authorised that
specific push — approval to push to a preview project is not approval to
overwrite the real one.

Local `tectonic` rendering cannot fully prove Overleaf output, because Overleaf
runs pdfLaTeX and the preview script stubs pdfTeX primitives for XeTeX. State
this plainly and ask the user to confirm in Overleaf rather than claiming the
output is verified.

## Keeping build output out of the project

Overleaf shows every committed file. Add a `.gitignore`:

```
build/
*.aux
*.log
*.out
*.synctex.gz
```
