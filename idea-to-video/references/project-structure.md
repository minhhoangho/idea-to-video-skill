# Project structure — where the work lives

## Why this exists

A video job is not one file. It is a brief, a script, sourced assets, a composition, a pile of QA frames, and three or four renders that differ in ways nobody will remember next week. Left unmanaged, that lands as `video.mp4`, `video2.mp4`, `video_final.mp4`, `video_final_REAL.mp4` in whatever directory happened to be open.

So every job gets one dated folder under a single workspace root, and nothing about the job lives outside it. The payoff is concrete: the user can hand the folder to someone else, come back in a month and know which render shipped, and re-render a variant without re-answering a single question.

## The layout

Create `video-projects/` in the user's working directory the first time this skill produces anything. Never create it inside the skill directory — the skill is installed code, the projects are the user's data.

```
video-projects/
├── INDEX.md                        # one line per job, newest first
├── _shared/                        # reused across jobs
│   ├── brand/                      # logo files, fonts, palette.md
│   └── music/
├── _archive/                       # delivered jobs moved out of the way
└── 2026-08-27-barbershop-promo/    # one job
    ├── brief.md                    # source of truth (assets/brief-template.md)
    ├── NOTES.md                    # decision log + revision history
    ├── script.md                   # narration, one "## <scene-id>" per scene
    ├── storyboard.md               # Track C, or the shot list for any track
    ├── input/                      # THEIRS — reference material, read-only
    ├── project/                    # Remotion source (+ generated audioConfig.ts)
    ├── assets/                     # YOURS — sourced or generated media
    ├── frames/                     # QA extractions — disposable, gitignorable
    └── out/                        # renders, versioned, never overwritten
        ├── barbershop-promo_1080x1920_v1.mp4
        └── barbershop-promo_1080x1920_v2.mp4
```

`scripts/new_project.sh <slug>` creates this skeleton and appends the row to `INDEX.md`. Run it at the end of Phase 1 — before the clarification round, so that round can hand the user a real `input/` path instead of asking them to describe their brand in prose.

## input/ and assets/ are not the same folder

`input/` holds what the user gave you. `assets/` holds what you fetched or made. The split looks pedantic until the revision six weeks later, when "did the client supply this logo or did we draw it?" turns into an hour of guessing.

**Never write into `input/`.** No cropping in place, no format conversion, no tidy-up rename, no deletion. When a supplied file needs processing, copy it into `assets/` and process the copy — the original stays as the record of what you were handed.

`scripts/scan_input.sh <job> --target <WxH>` inventories the folder in one table and flags images too small for the target frame. `references/input-analysis.md` covers what to extract from each kind of file, and the rule that every one of them is either used or declined in writing.

## Tooling sits beside the workspace, not inside it

```
<working directory>/
├── .venv/                          # Python tools — one venv for every job
└── video-projects/                 # the tree above
```

`scripts/setup_python_env.sh` creates `./.venv` in the user's working directory and reuses it forever after — `edge-tts` by default, plus whatever a job asks for. It gitignores itself.

One venv at this level rather than one per job is a deliberate trade: jobs stop being byte-for-byte reproducible, but the user gets a single directory they can see, inspect and delete, instead of a copy of the same packages buried in every job folder. Log any package beyond the default in the job's `NOTES.md` so the trade stays cheap.

Call tools by path — `.venv/bin/edge-tts` — never `source .venv/bin/activate`. Activation dies with the shell that ran it, so the next command silently runs on system Python.

## Naming

**Job folder:** `YYYY-MM-DD-<slug>`. The date is the start date and never changes, even across revisions weeks later — it is how the user finds the job again.

**Renders:** `<slug>_<width>x<height>_v<N>.mp4`. Dimensions in the filename because the same job usually ships in two or three aspect ratios, and nothing is more annoying than opening four files to find the square one.

**Never overwrite a render.** Increment `v`. Renders are cheap; a lost approved cut is not. Record in `NOTES.md` which version was delivered and why the previous one was replaced.

## INDEX.md

One table, newest first, maintained by the agent on every job:

```markdown
| Date | Job | Track | Output | Status |
|---|---|---|---|---|
| 2026-08-27 | barbershop-promo | A | 20s · 1080×1920 · v2 | delivered |
| 2026-08-14 | q3-recap | B | 90s · 1080×1920 · v1 | archived |
```

This is what "manage all the products" means in practice. Update it when a job is created, when a version is delivered, and when a job is archived — three moments, not a running log.

## NOTES.md

Short, append-only, one entry per session. It carries the two things the brief cannot: what changed and why.

```markdown
## 2026-08-27 · v1
Direction B chosen (high-speed neon). Hook is the counting-up number.
Assumption: no logo supplied, used a wordmark in Inter Black.

## 2026-08-28 · v2
Client wants the price removed and the CTA held 1s longer.
Beat 4 extended 2s → 3s, total 20s → 21s. Delivered v2.
```

When a user returns with "can you redo the one from last month but square", this file is what makes the answer a five-minute re-render instead of a fresh interview.

## Working rules

- **Read `brief.md` before touching anything** in an existing job folder. It outranks your memory of the conversation.
- **Rescan `input/` before every build.** Files arrive late. A logo that showed up after the direction was agreed changes something — say what, and let the user decide.
- **Corrections go into `brief.md`**, not just into the code. A brief that drifts from what was built is worse than no brief.
- **`frames/` is disposable.** Clear it between renders so you are never inspecting stale frames from the previous version — a genuinely easy mistake that produces confident wrong QA verdicts.
- **Shared assets go in `_shared/`**, referenced not copied, so a brand palette change propagates instead of being re-fixed in six jobs.
- **Python tools come from `./.venv`**, never system pip and never a second venv invented on the spot. If it is missing, `scripts/setup_python_env.sh` builds it; if it is broken, delete it and rerun.
- **Archive on delivery**, once the user confirms they have the file: `mv <job> _archive/` and update `INDEX.md`. Do not archive on your own initiative — a job is not finished until the user says it is.

## If the user already has a structure

Ask once, use theirs. A project with an existing `assets/` and `renders/` convention does not need a competing one, and imposing this layout on top of it creates exactly the mess it was meant to prevent. Map the concepts — brief, source, output, notes — onto whatever they already use, and say what you mapped where.
