# idea-to-video

A Claude agent skill that turns one sentence into a finished video — and asks the right questions first.

Most "AI video" output fails one of two ways. The agent guesses at what you meant and builds the wrong thing competently, or it builds the right thing with linear fades and calls it motion design. This skill addresses both: a single disciplined clarification round before anything is built, then hard craft rules plus a render → inspect → fix loop so the agent verifies its own output instead of shipping blind.

It works in any project, with or without a render environment.

---

## Installation

### Claude Code — all projects

```bash
git clone https://github.com/minhhoangho/idea-to-video-skill.git
cd idea-to-video-skill
./install.sh
```

Start a new Claude Code session and check `/skills` — `idea-to-video` should be listed. The installer also reports which tracks your machine can actually run.

### Claude Code — one project, shared with a team

From inside the project you want it in:

```bash
/path/to/idea-to-video-skill/install.sh --project
```

That writes to `./.claude/skills/idea-to-video/`. Commit it and everyone on the repo gets the skill. Add `video-projects/` to that project's `.gitignore` unless you want renders in version control.

To remove either install: `./install.sh --uninstall` (add `--project` for the project-scoped one).

### Claude Desktop / claude.ai

```bash
./scripts/build.sh        # writes dist/idea-to-video.skill
```

Then Settings → Capabilities → Skills → upload it.

Note the ceiling: those surfaces have no terminal, so the skill runs its Track C path and hands you a complete script, shot list and asset brief rather than an MP4. That is the honest answer, not a workaround — you then run it in Claude Code to get the file.

### Prerequisites

Only needed for actual rendering; the skill degrades gracefully without them.

| For | You need |
|---|---|
| Track A — motion graphics | Node.js 18+, ffmpeg |
| Track B — narrated video | the above, plus Python 3 for `edge-tts` (installed on demand) |
| Track C — storyboard | nothing |

**No API keys, for any track.** The script is written in the conversation, the voice-over comes from `edge-tts` running locally for free, and footage comes from whatever you supply. Nothing here asks you for a credential.

```bash
node --version && ffmpeg -version | head -1   # Track A and B
```

Python tools — `edge-tts` and anything a job adds later — go into a `.venv` in *your* working directory, created on demand by `scripts/setup_python_env.sh`. One venv for every job, gitignored automatically, safe to delete whenever. Nothing is installed into system Python.

If the voice service starts answering 403 to an older `edge-tts`, `narrate.sh` upgrades it inside that venv once and retries, so a venv built months ago keeps working.

---

## Using it

Talk normally. The skill triggers on video intent — you do not invoke it by name.

```
Make me a 20-second vertical video for my barbershop booking app
```

```
Explain how JWT auth works in 60 seconds, for junior devs
```

### Giving it your own material

Before it asks you anything, the skill creates a job folder and tells you its `input/` path. Drop whatever you have in there — logo, product photos, brand guide PDF, a competitor clip you like the pacing of, a script draft — and it reads all of it before proposing a direction.

```
video-projects/2026-08-28-adidas/
├── input/      ← yours. Never modified, never deleted.
└── assets/     ← what the skill fetched or generated
```

Nothing is required; with an empty `input/` it proposes a palette and builds the visuals as motion graphics (there is no stock library, by design). But a brand guide gets you the real hex codes instead of a close guess, and every file you supply is accounted for in `brief.md` — used, or declined with a reason.

```
My Remotion video looks flat and generic — fix it
```

```
Turn last week's blog post into a faceless short with voice-over
```

### What happens next

**1. It asks — once.** Up to six questions in a single message, every one carrying a default so you can reply `use the defaults` and move on. It will not ask about anything your sentence already answered — when you state the length and aspect ratio up front, it skips the questions entirely and goes straight to proposing. If you want zero questions, say `you pick` and it runs on defaults and explains each choice afterwards.

**2. It proposes.** Two or three named directions that differ in *structure* — different opening two seconds, different pacing, different way of carrying the message — not three adjectives for the same video. One is recommended, with the reason tied to your goal. You pick, or say `you choose`.

**3. It builds.** Creates a job folder, writes the brief, picks the engine, renders.

**4. It checks its own work.** Every render gets an automated ffmpeg report — black or frozen stretches, dead air, loudness against the -14 LUFS platforms expect — then the agent extracts frames and looks at them for cropped text, subtitle collisions and safe-area violations, fixes, re-renders. While iterating it can render drafts without film grain (`render.sh --no-grain`), about a third faster.

**5. It delivers** the file path plus two or three concrete upgrades you might want next.

### What comes out, and how long it takes

| | Default |
|---|---|
| Size | 1080×1920 (9:16) at 30 fps; any other size or ratio on request |
| Encoding | H.264 CRF 18, AAC 192 kbps / 48 kHz, loudness normalised to -14 LUFS |
| Length | Whatever the brief says: 15s, 30s, 60s and 90s+ have ready-made beat structures. Narrated videos take their length from the script — roughly 220 Vietnamese or 170 English words per minute |

Measured on an M1 Pro (8 cores) for a 30s, 1080×1920 clip of text and gradient scenes: **about 50s to render** with the full look, about 35s as a no-grain draft, plus ~5s for the QA pass. Narration adds edge-tts time too — one sample took ~15s for ~9s of speech, scenes generated one after another. Footage, large images or 3D scenes render slower, and your own machine will differ — this is a yardstick, not a promise. Time spent by the agent writing and fixing scenes usually outweighs all of it.

### Steering it

You can short-circuit any phase by being specific up front. `30s, 9:16, dark tech look, no voice-over, here's our hex codes` skips most of the questions. Naming a tool (`use Remotion`) skips the engine decision. Everything you supply is one thing it does not have to ask about.

---

## Where your work lives

Renders never land inside the skill. The first time it produces something, it creates a workspace in your current directory:

```
video-projects/
├── INDEX.md                        # every job, newest first, with status
├── _shared/                        # brand assets and music reused across jobs
├── _archive/                       # delivered jobs
└── 2026-08-27-barbershop-promo/
    ├── brief.md                    # source of truth for this job
    ├── NOTES.md                    # what changed between versions, and why
    ├── project/                    # Remotion source or task directory
    ├── assets/
    ├── frames/                     # QA extractions, disposable
    └── out/
        ├── barbershop-promo_1080x1920_v1.mp4
        ├── barbershop-promo_1080x1920_v2.mp4
        └── barbershop-promo_1080x1920_draft.mp4   # --no-grain preview, replaced each time
```

Renders are versioned and never overwritten (the one `_draft` file is the deliberate exception, and is never a deliverable), and dimensions are in the filename because most jobs ship in more than one aspect ratio. `NOTES.md` is what makes "redo last month's one, but square" a five-minute re-render instead of a fresh interview.

If you already have a folder convention, say so — the skill will use yours and tell you what it mapped where.

---

## Repository layout

```
.
├── README.md                   # this file
├── LICENSE
├── CHANGELOG.md
├── install.sh                  # install into ~/.claude/skills or ./.claude/skills
├── scripts/build.sh            # package dist/idea-to-video.skill
└── idea-to-video/              # the skill itself — this is what gets installed
```

Everything under `idea-to-video/` is the deliverable; everything else exists to install, package or verify it.

## What's inside the skill

```
idea-to-video/
├── SKILL.md                    # the five-phase workflow and its non-negotiables
├── references/
│   ├── discovery.md            # question bank by request shape, with defaults
│   ├── creative-direction.md   # hooks, beat structures, palettes, pacing, sound
│   ├── track-remotion.md       # scaffold, the ten motion rules, render loop
│   ├── track-narrated.md       # script → edge-tts → audio-driven composition
│   ├── track-storyboard.md     # no-terminal fallback deliverable
│   ├── input-analysis.md       # reading the reference material you supply
│   ├── project-structure.md    # workspace layout, naming, archiving
│   ├── qa-and-delivery.md      # frame inspection checklist, handover format
│   └── remotion/               # Remotion API, 29 topics + INDEX.md
├── assets/
│   ├── brief-template.md
│   ├── theme.ts                # Remotion design tokens, loads the typeface
│   ├── components/             # motion primitives + content components
│   ├── narration.ts            # narrated-track types, music ducking
│   └── storyboard-template.md
└── scripts/
    ├── new_project.sh          # create a job folder, seed brief.md, register it
    ├── scan_input.sh           # inventory the reference material you dropped in
    ├── setup_python_env.sh     # create/reuse ./.venv for edge-tts and friends
    ├── narrate.sh              # script.md → voice-over, timing, word timings
    ├── tts_words.py            # one scene through edge-tts (used by narrate.sh)
    ├── scaffold_remotion.sh    # bootstrap a Remotion project inside a job
    ├── render.sh               # versioned render, -14 LUFS, then QA (--no-grain for drafts)
    └── inspect_frames.sh       # extract frames + automated QA report
```

`SKILL.md` loads whenever the skill triggers; the reference files load only when the relevant track is chosen. That is deliberate — it keeps the always-on cost small.

---

## The three tracks

| Track | Use when | Gives you |
|---|---|---|
| **A — Remotion** | The video is *about* something specific: a brand, a product, exact words and colors | Deterministic React-rendered motion graphics. Exact text, exact colors, re-renderable forever |
| **B — Narrated** | Meaning is carried by a *voice*: faceless content, recaps, explainers | Script → free local TTS → every scene timed to the audio → word-synced captions → MP4 |
| **C — Storyboard** | No terminal, or you want the plan not the file | Brief, timed script, shot list, verbatim text sheet, asset queries |

The agent picks and tells you why. When it is genuinely torn it will say so and let you break the tie.

---

## Making it yours

Three edits worth doing before real use:

**Your brand in `assets/theme.ts`.** Palette, type, motion character. Saves repeating it every job. Every value is a fraction of the composition rather than a pixel count, which is what lets one set of scenes re-cut from 9:16 to 1:1 for free — keep it that way when you edit.

**Your components in `assets/components/`.** The primitives and content components copied into every project. Add your own here rather than in a single job, and they show up in the next one too.

**Your defaults in `references/discovery.md`.** The nine-slot table sets what the agent assumes when you stay silent. If you always make 9:16 at 24fps in a specific language, encode that and the question round gets shorter.

**Your voice in `references/track-narrated.md`.** Narration defaults to a US English voice. If you work in another language, pin the voice name there — `scripts/narrate.sh --voices vi` lists what is available for a language — along with the caption font that suits it.

---

## Development

```bash
./scripts/build.sh                      # package the bundle
bash -n idea-to-video/scripts/*.sh      # syntax check
./install.sh && # re-install, then start a new Claude Code session
```

There is no CI. Before committing, run the syntax check above and render something small through `scripts/render.sh` — the docs and the scripts drifting apart is the failure mode this skill is most prone to, and only a real run catches it.

Bump the version in `SKILL.md` frontmatter and add a `CHANGELOG.md` entry when you change behaviour.

## License

MIT — see [LICENSE](LICENSE).
