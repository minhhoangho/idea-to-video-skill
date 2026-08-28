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

Nothing is required; with an empty `input/` it proposes a palette and uses stock imagery. But a brand guide gets you the real hex codes instead of a close guess, and every file you supply is accounted for in `brief.md` — used, or declined with a reason.

```
My Remotion video looks flat and generic — fix it
```

```
Turn last week's blog post into a faceless short with voice-over
```

### What happens next

**1. It asks — once.** Up to six questions in a single message, every one carrying a default so you can reply `use the defaults` and move on. It will not ask about anything your sentence already answered. If you want zero questions, say `you pick` and it runs on defaults and explains each choice afterwards.

**2. It proposes.** Two or three named directions that differ in *structure* — different opening two seconds, different pacing, different way of carrying the message — not three adjectives for the same video. One is recommended, with the reason tied to your goal. You pick, or say `you choose`.

**3. It builds.** Creates a job folder, writes the brief, picks the engine, renders.

**4. It checks its own work.** Extracts frames with ffmpeg, looks at them for cropped text, dead frames, subtitle collisions and safe-area violations, fixes, re-renders.

**5. It delivers** the file path plus two or three concrete upgrades you might want next.

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
        └── barbershop-promo_1080x1920_v2.mp4
```

Renders are versioned and never overwritten, and dimensions are in the filename because most jobs ship in more than one aspect ratio. `NOTES.md` is what makes "redo last month's one, but square" a five-minute re-render instead of a fresh interview.

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
├── .github/workflows/          # CI: syntax, frontmatter, reference and script checks
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
│   └── qa-and-delivery.md      # frame inspection checklist, handover format
├── assets/
│   ├── brief-template.md
│   ├── theme.ts                # Remotion design tokens
│   └── storyboard-template.md
└── scripts/
    ├── new_project.sh          # create a job folder, seed brief.md, register it
    ├── scan_input.sh           # inventory the reference material you dropped in
    ├── setup_python_env.sh     # create/reuse ./.venv for edge-tts and friends
    ├── narrate.sh              # script.md → voice-over + audioConfig.ts timing
    ├── scaffold_remotion.sh    # bootstrap a Remotion project inside a job
    └── inspect_frames.sh       # extract frames for the QA pass
```

`SKILL.md` loads whenever the skill triggers; the reference files load only when the relevant track is chosen. That is deliberate — it keeps the always-on cost small.

---

## The three tracks

| Track | Use when | Gives you |
|---|---|---|
| **A — Remotion** | The video is *about* something specific: a brand, a product, exact words and colors | Deterministic React-rendered motion graphics. Exact text, exact colors, re-renderable forever |
| **B — Narrated** | Meaning is carried by a *voice*: faceless content, recaps, explainers | Script → free local TTS → every scene timed to the audio → burned captions → MP4 |
| **C — Storyboard** | No terminal, or you want the plan not the file | Brief, timed script, shot list, verbatim text sheet, asset queries |

The agent picks and tells you why. When it is genuinely torn it will say so and let you break the tie.

---

## Making it yours

Three edits worth doing before real use:

**Your brand in `assets/theme.ts`.** Palette, type, motion character. Saves repeating it every job.

**Your defaults in `references/discovery.md`.** The nine-slot table sets what the agent assumes when you stay silent. If you always make 9:16 at 24fps in a specific language, encode that and the question round gets shorter.

**Your voice in `references/track-narrated.md`.** Narration defaults to a US English voice. If you work in another language, pin the voice name there — `scripts/narrate.sh --voices vi` lists what is available for a language — along with the caption font that suits it.

---

## Development

```bash
./scripts/build.sh                      # package the bundle
bash -n idea-to-video/scripts/*.sh      # syntax check
./install.sh && # re-install, then start a new Claude Code session
```

CI runs on every push: shell syntax, executable bits, `SKILL.md` frontmatter, whether every path referenced in the docs actually exists, and an end-to-end run of the workspace scripts. That last check is the one that catches real breakage — the docs and the scripts drifting apart is the failure mode this skill is most prone to.

Bump the version in `SKILL.md` frontmatter and add a `CHANGELOG.md` entry when you change behaviour.

## License

MIT — see [LICENSE](LICENSE).
