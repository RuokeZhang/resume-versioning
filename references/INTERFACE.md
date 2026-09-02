# Template command interface

Every template implements this command set. Content files use only these
commands, which is what lets one content file render under any template.

Adding a template means implementing **all** of it. A missing command produces
an "Undefined control sequence" error only for the resumes that happen to use
it, so check the whole table rather than compiling one driver.

## Structural

| Command | Meaning |
|---|---|
| `\ResumeHeader` | Name and contact block. Reads the identity macros below. |
| `\resumeSubHeadingListStart` / `...End` | Opens/closes the list holding entries. May be a no-op if the layout sets entries as plain paragraphs. |
| `\resumeItemListStart` / `...End` | Opens/closes a bullet list inside an entry. |
| `\resumeItemListStartTight` | Bullet list flush against the heading above it. |

## Entries

| Command | Args |
|---|---|
| `\resumeSubheading` | `{org}{date}{title}{location}` — job or role entry |
| `\resumeEducation` | `{school}{date}{degree}` — a degree is not a job title, and layouts that italicise job titles must not italicise this |
| `\resumePublication` | `{title}{venue}{status note}` — titles are long; some layouts must break the note onto its own line |
| `\resumeProjectHeading` | `{title}{date}` |
| `\resumeSubSubheading` | `{title}{date}` |
| `\resumeItem` | `{text}` — one bullet |
| `\resumeProjectTitle` | `{text}` — sub-project header inside an entry's bullet list |

`\resumeEducation` and `\resumePublication` exist because a layout can need to
render them differently from `\resumeSubheading` even though all three are
"a bold thing, a date, and a subtitle". Collapsing them back into one command
is a false economy — it is exactly what forces a content fork later.

## Spacing

| Command | Meaning |
|---|---|
| `\resumeSectionGap` | Trailing gap after a section body. |
| `\resumeTighten{<len>}` | Negative leading hint. **A template may ignore it.** |

One place it is routinely needed: in a dense layout, `\resumeSubheading`
opens with a small negative skip and `\resumeProjectHeading` does not, so two
project headings in a row sit further apart than two job entries do. Put a
`\resumeTighten` between consecutive project headings rather than editing the
template — an airier layout ignores the hint and needs no such correction.

`\resumeTighten` is the escape hatch for hand-tuned kerning. One layout's
`\vspace{-10pt}` between a heading and its bullets can be correct there and
overlap text badly elsewhere. Content states the hint; each template decides
whether to honour it. A dense layout defines it as `\vspace{#1}`; an airy one
defines it as `{}`.

## Identity macros

Set by `profiles/<person>.tex`, consumed by `\ResumeHeader`:

`\ResumeName`, `\ResumeEmail`, `\ResumePhone`, `\ResumeLinkedInName`,
`\ResumeLinkedInURL`

Put **every** contact detail here. A phone number hardcoded in a template is
invisible until someone adds a second identity and the wrong number ships.

## Layout switches

Set by the driver before `\input`-ing a template. Templates declare their own
with `\providecommand` so drivers can override:

| Switch | Typical use |
|---|---|
| `\ifResume<Feature>` | Include or drop an optional entry, read by a content file |
| `\Resume<Thing>Skip` | Spacing knob where two content sets were tuned differently |

## Driver shape

```latex
\documentclass[letterpaper,11pt]{article}

\newif\ifResumeIncludeEarlyRoles
\ResumeIncludeEarlyRolestrue

\newcommand{\ResumeFont}{carlito}

\input{profiles/example.tex}
\input{templates/classic.tex}

\begin{document}
\ResumeHeader
\input{content/example-role.tex}
\end{document}
```

That is the whole file. Anything longer is content leaking into a driver.

## Fonts

A driver names a face; the template inputs it. The name is all the driver
provides, because font packages must load **after** `fontenc` — a driver that
inputs the font itself loads it too early, which changes the encoding setup
and silently shifts the metrics of every line.

```latex
\newcommand{\ResumeFont}{carlito}   % before \input{templates/...}
```

Omit it and the template falls back to `sourcesans`.

| File | Face | Notes |
|---|---|---|
| `sourcesans` | Source Sans Pro | humanist sans; the default |
| `carlito` | Carlito | metric-compatible with **Calibri** |
| `lato` | Lato | slightly narrower than Source Sans |
| `helvetica` | Helvetica clone | closest free stand-in for Arial |
| `roboto` | Roboto | neutral, holds up small |
| `caladea` | Caladea | metric-compatible with **Cambria** |
| `times` | newtxtext | the conservative choice |
| `charter` | XCharter | sturdier serif, more open than Times |
| `garamond` | EB Garamond | old-style; runs small |

Calibri and Cambria are proprietary Microsoft fonts and cannot be bundled.
Carlito and Caladea are free clones with the **same metrics**, so a document
laid out for Calibri keeps its line breaks under Carlito.

Adding a face means one file in `fonts/` that defines `\ResumeFontName` and
loads the packages:

```latex
% fonts/<name>.tex
\usepackage{<package>}
\renewcommand{\familydefault}{\sfdefault}   % sans faces only
```

Changing the face changes line breaks, so re-run `scripts/verify.sh` and look
at the render: a bullet that fitted two lines in one face may need three in
another.
