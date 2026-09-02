# The content library

`content/` holds the wording that is live right now. `CONTENT_LIBRARY/` holds
everything else: what was live before, what was drafted and not chosen, and the
verified facts underneath it all.

|  | `content/` | `CONTENT_LIBRARY/` |
|---|---|---|
| Format | LaTeX | Markdown |
| Compiled | yes, into the PDF | no, reference only |
| Holds | the one active version | every variant, with status |

Without the library, replaced wording is simply gone, and the numbers in it get
re-derived from memory the next time someone asks "what was the impact again?"
That is where invented metrics come from.

## File shape

One file per topic, under `EXPERIENCE/`, `PROJECTS/`, or `RESEARCH/`.

```markdown
# <Company or project>

## Canonical facts

- Dates: <start> - <end>
- Title: <exact title per role family>
- Approved impact: <the one number the user has confirmed>

## ACTIVE - <role> v<n> - <YYYY-MM-DD>

- <bullet as it appears in content/>

## ARCHIVED - <role> v<n-1> - <YYYY-MM-DD>

- <the wording this replaced>

## CANDIDATE - <label>

- <drafted, not selected>

<what must be confirmed before this can be used>

## DO NOT USE

- `<claim>` conflicts with the approved `<claim>`.
```

## Statuses

| Status | Meaning |
|---|---|
| `ACTIVE` | Currently in `content/`. Should match it verbatim. |
| `ARCHIVED` | Was live, safe to restore. Always dated. |
| `CANDIDATE` | Drafted, never shipped. Note what needs confirming. |
| `DO NOT USE` | Contradicts an approved fact. Never reuse. |

## Replacing wording

1. Copy the outgoing text into the topic file as `ARCHIVED`, dated today.
2. Add the replacement as the new `ACTIVE`, noting which resumes use it.
3. Write it into `content/`.
4. Render and confirm the change is limited to the resumes intended.

Do step 1 first. After `content/` is overwritten the old wording is only in git
history, and nobody goes looking there.

### An archive contains sentences

The single most common way this fails is writing down *what changed* instead of
*what it said*:

```markdown
## ARCHIVED - v3 - 2026-08-14        <-- useless

Shortened to one-line bullets after the page overflowed.
```

That is a changelog entry. The wording it describes no longer exists anywhere a
person will find it. The next time someone asks for "the longer version", it has
to be rewritten from memory — which is exactly how a number drifts.

```markdown
## ARCHIVED - v3 - 2026-08-14        <-- an archive

Shortened to one-line bullets after the page overflowed.

- Patrolled 40 acres of lettuce and kale on a dawn-and-dusk rotation, cutting
  after-hours nibble incidents by 87% across two growing seasons.
- Designed a dew-collection ritual that funnelled overnight condensation onto
  the seedling rows, raising survival through two dry summers.
```

The note is fine. The note **plus the text** is the requirement.

### Cut for length is not cut for cause

Wording removed because a page overflowed should be filed as `CANDIDATE`, with
the reason recorded:

```markdown
## CANDIDATE - dropped for length - 2026-09-01

Cut only to fit one page, not because the wording is wrong. Restore if a
shorter entry elsewhere frees up the room.

- <the bullet, verbatim>
```

Filing it as `ARCHIVED` implies it was superseded, and filing it nowhere means
the next person to find space will write something weaker in its place.

## The `DO NOT USE` section

This is the most valuable part of the library and the easiest to skip.

When two files state different numbers for the same accomplishment, one is
wrong. Record both, mark the wrong one, and say why. An agent asked to "make
this bullet stronger" will otherwise find the bigger number in an old file and
reintroduce it, and an inflated metric on a resume is a serious problem.

Never resolve such a conflict alone. Ask which value is correct, then record the
answer as a canonical fact so the question is settled permanently.
