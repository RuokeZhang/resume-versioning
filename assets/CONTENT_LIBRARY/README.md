# Resume Content Library

Reference material, not compiled. `content/experience/` holds reusable active
work entries, while `content/projects/` keeps each target's project set in one
file. Target composition files select those pieces. This library holds
everything else, so replaced wording and the facts underneath it are never
lost.

## Structure

- `EXPERIENCE/` — one file per company or internship
- `PROJECTS/` — project descriptions and links
- `RESEARCH/` — papers and research contributions

## Variant statuses

- `ACTIVE` — currently in `content/`; should match it verbatim
- `ARCHIVED` — previously live, safe to restore, always dated
- `CANDIDATE` — drafted but not selected; note what needs confirming
- `DO NOT USE` — contradicts an approved fact; never reuse

## Maintenance rule

Before replacing active wording:

1. Copy the outgoing wording into the relevant library file as `ARCHIVED`.
2. Record its role target and archive date.
3. Add the replacement as the new `ACTIVE` variant.
4. Keep verified numbers and links in the file's `Canonical facts` section.
5. Never resolve conflicting metrics by guessing; ask, then record the answer.

Do step 1 first. Once `content/` is overwritten, the old wording exists only in
git history, and nobody looks there.
