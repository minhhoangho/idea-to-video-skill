---
name: idea-to-video
description: Turn a short idea, topic, or one-line prompt into a finished video. Use this skill whenever the user wants to make or fix a video — a Reel/Short/TikTok, promo, explainer, product demo, logo or brand animation, kinetic typography, animated captions, or a faceless narrated video — even when they name no tool and give only one sentence like "make me a video about X" or "30s clip for our app launch". Also use it when the user mentions Remotion, motion graphics, b-roll, voice-over, text-to-speech, storyboard, video script, shot list, or asks why an existing generated video looks flat or generic. The skill runs one short clarification round, proposes 2–3 creative directions with a recommendation, then produces the video — or a production-ready storyboard package when no render environment exists. It needs no API keys of any kind.
compatibility: Works in any Claude surface and needs no API keys. Full rendering needs a terminal with Node.js 18+ and ffmpeg; narrated video also uses edge-tts from a local ./.venv created by scripts/setup_python_env.sh. Without a terminal the skill degrades gracefully to the storyboard track.
metadata:
  version: "2.0.0"
---

# Idea → Video

The user brings one sentence. This skill turns it into a video that a real editor would sign off on.

Most AI video output fails for one of two reasons: the agent guessed at intent instead of asking, or it shipped linear fades and called it motion design. This skill fixes both — a disciplined clarification round up front, then hard craft rules and a self-verification loop at the end.

## The loop

Run these five phases in order. Never skip 2 or 3, never merge 2 and 3 into one message.

1. **Understand** — mine the user's sentence for what is already decided, then create the job folder.
2. **Clarify** — one consolidated question round, every question carrying a default, plus the `input/` path.
3. **Propose** — read whatever they supplied, then 2–3 named creative directions, one explicitly recommended.
4. **Produce** — pick the engine, build, render.
5. **Verify & deliver** — inspect actual frames, fix, hand over the file plus upgrade suggestions.

## Non-negotiables

- **One clarification round, not an interrogation.** Ask at most 6 questions, in a single message, each with a stated default so the user can reply "use the defaults" and move on. A second round is allowed only if the answers opened a genuinely new fork.
- **Never ask what the idea already answers.** "15s vertical intro for a barbershop booking app" has already given you duration, aspect ratio, format and subject. Asking again reads as not listening.
- **Every unstated choice becomes a visible assumption.** When you decide something the user did not, say so in one line with the alternative you rejected. Silence about a choice is the failure mode this skill exists to prevent.
- **Propose before you produce, and keep proposing while you produce.** See "Proposal discipline" below.
- **Never silently ignore a supplied file.** Everything in the job's `input/` is either used or declined in writing, with a reason, in `brief.md`. A user who hands over a logo and never hears about it again learns not to bother.
- **Never ship an unverified render.** Extract frames, look at them, fix what is wrong, re-render. A render that completed is not a render that is good.
- **Never print API keys, tokens, or full config files** into the conversation, even when debugging.

## Phase 1 — Understand

Before asking anything, extract from the user's message: subject, audience, platform, duration, aspect ratio, language, tone, whether there is a script, whether there are brand assets, whether narration is wanted.

Then classify the request into one of four shapes, because the shape decides which questions matter:

| Shape | Looks like | What actually matters |
|---|---|---|
| **Brand / promo** | logo reveal, product launch, app intro | brand assets, exact copy, palette, CTA |
| **Explainer / educational** | "explain X in 60 seconds", tutorial | script accuracy, pacing, how much text on screen |
| **Faceless content** | storytelling, top-5, news recap, motivation | narration voice, b-roll source, subtitle style |
| **Repair / upgrade** | "my video looks flat", "add captions" | what exists now, what specifically feels wrong |

Read `references/discovery.md` for the full question bank keyed to these shapes.

Then create the job folder — `scripts/new_project.sh <slug>` — before you ask anything. It exists this early for one reason: the clarification round in Phase 2 has to name a real `input/` path the user can drop files into, and a folder they would have to create themselves is a folder that stays empty. Only do this once Phase 1 has established the request really is a video job; do not leave dated folders behind for conversations that were only questions.

## Phase 2 — Clarify

Send one message. Structure it exactly like this — short preamble, then questions with defaults, then the escape hatch:

```
Before I start, a few things to lock down (reply "default" to any of them):

1. Duration & aspect — 30s vertical 9:16 for Reels? (default: 30s / 9:16)
2. Who is watching — ...? (default: ...)
3. ...

If you have a logo, product photos, a brand guide or a reference video, drop
them in video-projects/<job>/input/ — I'll read whatever is there.
(default: nothing — I'll propose a palette and build the visuals)

If you'd rather I just decide everything, say "you pick" — I'll run the
defaults and explain each choice afterwards.
```

**Include the `input/` line every time**, even when the idea mentions no assets — people forget they have a brand guide until they see the folder. Then carry on without waiting: the default is "nothing supplied", and someone with nothing to add should not have to say so before you can work.

If an interactive option tool is available in the current surface, prefer it over prose bullets — tapping beats typing. Otherwise plain numbered questions are fine.

**Reply in whatever language the user is writing in**, regardless of the language of these files. If the video itself is in a different language from the conversation, confirm both explicitly — this catches the common local-language-conversation / English-video mismatch.

## Phase 3 — Propose

First read what they gave you. `scripts/scan_input.sh <job> --target <WxH>` inventories the job's `input/` in one table, then open the files that matter — the logo, the brand guide, a reference clip. Directions built on their real palette and their real pacing beat directions built on your taste. `references/input-analysis.md` covers what to extract from each kind of file and the rule that nothing goes unmentioned.

Never jump from answers straight to code. Present 2–3 directions that lead to genuinely different videos, not three tones of the same video. Each gets:

- **A name** the user can point at ("Minimal Blackboard", "High-Speed Neon", "Warm Documentary")
- **Hook** — the literal first 2 seconds
- **Visual language** — palette, typography, motion character
- **Pacing** — cuts per 10s, beat structure
- **Sound** — music character, whether there is narration
- **Cost** — render time, asset needs, what could go wrong

Then recommend one in a single sentence with the reason tied to their goal, not to your taste. `references/creative-direction.md` has the templates, hook formulas and beat structures by duration.

Wait for the pick. If the user says "you choose", take your recommendation and state that you are doing so.

## Phase 4 — Produce

### Engine selection

| If the video needs… | Track | Reference |
|---|---|---|
| Exact text, brand colors, logos, UI mockups, data/counters, kinetic typography, anything re-renderable and pixel-controlled | **A — Remotion** | `references/track-remotion.md` |
| Narration carrying the meaning: faceless short-form, recaps, explainers, voice-over with burned captions | **B — Narrated** | `references/track-narrated.md` |
| No terminal available, or the user only wants the plan/script | **C — Storyboard package** | `references/track-storyboard.md` |
| A branded shell around real footage the user supplied | **A + B hybrid** — Remotion composition, narration timed as in Track B | both |

Default to Track A when the video is *about* a brand or an idea, and Track B when a voice carries it. Both render through Remotion; the difference is that Track B generates the narration first and derives every scene length from it. When genuinely torn, say so and let the user break the tie — that tie-break is itself a useful proposal.

**No track needs an API key.** The script is written in the conversation, the voice comes from a free local `edge-tts`, footage comes from what the user supplies. If you ever find yourself about to ask for a credential, you have left the skill.

### Workspace

Every job gets its own dated folder under `video-projects/` in the user's working directory — brief, supplied references, script, source, assets, QA frames and versioned renders in one place, indexed in `video-projects/INDEX.md`. The folder was created back in Phase 1; read `references/project-structure.md` for the layout, naming and archiving rules.

Rescan `input/` before you build. Files arrive late — someone finds the logo after they have already answered your questions. If something new turned up after the direction was agreed, say what it changes and let the user decide, rather than quietly rebuilding or quietly ignoring it.

This is not bookkeeping for its own sake. It is what lets the user come back in a month, see which render shipped, and get a square variant without re-answering a single question.

Python tooling lives *beside* that workspace, not inside it. `scripts/setup_python_env.sh` creates `./.venv` in the working directory once, and every job reuses it — one visible, deletable directory instead of a venv per job or packages dumped into system Python. Call tools by path (`.venv/bin/edge-tts`); activation does not survive between shell calls.

If the user already has a folder convention, use theirs and say what you mapped where.

### While producing

Write the brief into the job folder first (from `assets/brief-template.md`), so the decisions survive context loss and the user can correct them in one place. Corrections go back into `brief.md`, not only into the code.

`scaffold_remotion.sh` gives you `theme.ts` and a component library already in place — `src/components/README.md` maps "what this beat has to do" onto what to reach for. Build scenes by composing those, not by animating from scratch; that is what makes ten scenes look like one video. For narrated work, write `script.md` and run `scripts/narrate.sh <job> --voice <name>` *before* building the composition, so scene lengths come from the audio rather than from a guess.

`references/remotion/INDEX.md` indexes the API reference. Load the one topic you need.

Give one short progress note per phase, not a running commentary. Do not stop to ask permission for things already agreed in the brief.

## Phase 5 — Verify & deliver

Rendering is not finishing. Run the loop in `references/qa-and-delivery.md`:

1. Render.
2. Extract frames (`scripts/inspect_frames.sh`) at the hook, each transition, and the final CTA.
3. Actually look at them. Check text safe-areas, contrast, cropped elements, empty frames, subtitle collisions.
4. Fix and re-render. Repeat until clean.
5. Deliver: absolute file path, duration, aspect ratio, one-line description of what it contains. Then update `INDEX.md` and append the version entry to the job's `NOTES.md`.

Close every delivery with 2–3 concrete upgrades ("add word-synced captions", "swap the hook for a direct question", "cut 9:16 and 1:1 from the same composition") — the user's next request is usually one of them.

## Proposal discipline

The user asked for a collaborator, not an order-taker. Concretely, at every phase:

- **When you choose,** name the choice and the alternative: "I went dark-background because white text holds up better on phones; a light version would suit the website better."
- **When you hit a constraint,** surface it before it becomes a surprise: "Five features in 15 seconds gives each one 3 seconds — I'd cut to three features or stretch to 25s."
- **When you spot something better than what was asked,** offer it once, then follow the user's call. Do not quietly substitute your version.
- **When something fails,** report the stage, the short error, and the log path — then repair and retry once before escalating to the user.

## Files

```
idea-to-video/
├── SKILL.md
├── references/
│   ├── discovery.md            # question bank by request shape, with defaults
│   ├── creative-direction.md   # proposal templates, hooks, beats, palettes, sound
│   ├── track-remotion.md       # scaffold, 10 motion rules, render loop
│   ├── track-narrated.md       # script → edge-tts → audio-driven composition
│   ├── track-storyboard.md     # no-terminal fallback deliverable
│   ├── input-analysis.md       # reading the user's supplied reference material
│   ├── project-structure.md    # video-projects/ workspace layout and naming
│   ├── qa-and-delivery.md      # frame inspection checklist, handover format
│   └── remotion/               # Remotion API, 29 topics + INDEX.md, load on demand
├── assets/
│   ├── brief-template.md       # the single source of truth for a job
│   ├── theme.ts                # Remotion design tokens
│   └── storyboard-template.md
├── scripts/
│   ├── new_project.sh          # create a job folder + register it in INDEX.md
│   ├── scan_input.sh           # inventory the user's input/ before proposing
│   ├── setup_python_env.sh     # create/reuse ./.venv for edge-tts and friends
│   ├── narrate.sh              # script.md → voice-over + audioConfig.ts timing
│   ├── scaffold_remotion.sh    # non-interactive Remotion project bootstrap
│   └── inspect_frames.sh       # ffmpeg frame extraction for verification
└── README.md                   # install and usage, for humans
```

Renders land in the user's `video-projects/` workspace and Python tools in the user's `./.venv`, never inside this skill directory.
