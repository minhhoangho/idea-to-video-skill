# Track C — Storyboard package (no render environment)

Use this when there is no terminal, no Node/ffmpeg, or the user explicitly wants the plan rather than the file. The deliverable is a package someone else — a human editor, another agent, or the user in Claude Code later — can execute without asking a single follow-up question.

Say plainly at the start what you are producing and why: *"I can't render a file in this environment, so I'll hand you the full script, shot list and asset prompts — ready to run in Claude Code or to pass to an editor. If you open Claude Code with this skill installed, I can render it directly."*

## Where it goes

Even with nothing to render, create the job folder (`scripts/new_project.sh <slug>`) if a filesystem is available, and write `brief.md`, `script.md` and `storyboard.md` into it. The package is the deliverable for this track, so it deserves the same home as an MP4 — and it means the render, whenever it happens, starts from files rather than from scrollback.

With no filesystem at all, deliver the same documents inline in the conversation, clearly separated, so they can be copied into files later.

## What the package contains

1. **The brief** — filled from `assets/brief-template.md`. Non-negotiable; everything else derives from it.
2. **Narration script** — timed, with word counts per beat and a running timecode. Mark emphasis and pauses.
3. **Shot list** — one row per shot: timecode in/out, what is on screen, camera or motion behaviour, on-screen text verbatim, audio cue.
4. **On-screen text sheet** — every word that appears, exactly as it should appear, so nobody retypes it and introduces a typo.
5. **Asset requirements** — what has to be sourced or supplied: logo files, product screenshots, stock search terms, music character.
6. **Execution notes** — which track to use, composition size, fps, and the specific motion rules that matter for this piece.

`assets/storyboard-template.md` has the tables. Fill them; do not hand over an empty template.

## Shot list format

| # | In–Out | On screen | Motion | Text (verbatim) | Audio |
|---|---|---|---|---|---|
| 1 | 0:00–0:02 | Dark ground, single question | Type-on, 4f stagger | "How long does booking take you?" | Impact, music in |
| 2 | 0:02–0:07 | App mockup, three steps | Slide in from left, 5f stagger | "Three taps. Done." | Soft whoosh |

Timecodes must sum to the agreed duration. If they do not, the storyboard is wrong — fix it before delivering, and tell the user which beat you shortened.

## Stock search terms

The skill fetches no stock itself — the user sources these. So give literal search queries they can paste into whatever library they use, rather than descriptions: `"barber shop interior slow motion"`, not "a nice salon shot". Two or three alternatives per shot, because the first query often returns nothing usable.

## Handoff

Close with the exact command the user would run to turn the package into a file, and offer to run it yourself if they move to an environment that supports it. That sentence is what turns a document into a next step.
