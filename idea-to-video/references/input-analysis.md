# Reading what the user supplied

## Why this exists

The difference between a generic video and *theirs* is mostly sitting on their disk already: the real logo, the actual product photos, the brand guide with the hex codes, the competitor clip they keep sending people. A skill that only ever asks questions in prose will invent a palette that is close to their brand and wrong, which is worse than obviously wrong — it ships, and then someone notices.

So every job has an `input/` folder, the user is told about it by name, and nothing in it is ever ignored in silence.

## The folder contract

```
video-projects/2026-08-28-adidas/
├── input/      # theirs — read-only, you never write here
└── assets/     # yours — sourced, generated, converted
```

`input/` is the user's. **Never modify, move, rename, convert or delete anything inside it.** When a file needs processing — a PNG cropped, a video trimmed, a font subsetted — copy it into `assets/` and work on the copy. The original stays as evidence of what you were given, which is what makes a revision three weeks later cheap instead of archaeological.

This is also why `input/` is not merged into `assets/`. Six weeks on, "did the client give us this logo or did we make it?" is a question with real consequences.

## Ask once, early, with a real path

The job folder is created at the end of Phase 1, before the clarification round, precisely so that Phase 2 can name a path that already exists. A folder the user has to create themselves is a folder that stays empty.

Put this line in the Phase 2 message, always, even when the idea mentions no assets:

> If you have a logo, product photos, a brand guide, or a reference video, drop them in
> `video-projects/2026-08-28-adidas/input/` — I'll read whatever is there.
> *(default: nothing — I'll propose a palette and build the visuals)*

Then **carry on**. Do not block waiting for files. The default is "nothing supplied", and a user who has nothing should not have to say so before you can work.

## Scan, then read

```bash
scripts/scan_input.sh video-projects/2026-08-28-adidas --target 1080x1920
```

One table: file, kind, detail, note. It flags images too small for the target frame, and files you cannot open at all. Run it before doing anything else with the folder — it is faster than probing six files by hand and it catches the resolution problem *before* you build a composition around a 200px logo.

Then actually open things. The scan tells you what is there; it does not tell you what is in it.

## What each kind gives you

| Kind | What you extract | How |
|---|---|---|
| **Logo** (SVG/PNG) | The mark itself, its clear-space, whether it has a dark-background variant | Look at it. An SVG is the best case — it scales. A PNG under 25% of frame width will not survive a hero placement. |
| **Product / brand photos** | Palette, lighting character, whether the product is shot on white or in context | Look at them, then pull a palette (below). Photos also tell you the tone the brand already uses, which usually beats the tone you were about to invent. |
| **Brand guide** (PDF) | Hex codes, type family and weights, logo misuse rules, tagline verbatim | Read it. On a long guide the pages that matter are the palette, typography and logo-usage ones — go there first. |
| **Reference video** | Pacing, cut rhythm, hook structure, type treatment | `scripts/inspect_frames.sh <file> <job>/frames/ref/` then look at the sheet. Count the cuts in the first 5 seconds; that number is the pacing they are asking for without saying so. |
| **Audio** | Whether they already have a track, its length and mood | Duration decides the video's length as often as the brief does. |
| **Fonts** (TTF/OTF) | The actual typeface, usable directly in Remotion | Check the licence before shipping — a font in `input/` is not automatically a font they may embed. |
| **Text / script** | Verbatim copy, claims, legal wording | Read it in full. Copy the user wrote is copy you do not rewrite without saying you did. |
| **PSD / AI / Sketch / Figma** | Nothing — you cannot open them | Ask for a PNG or SVG export. Say this early, not after they have waited. |

## Pulling a palette from an image

```bash
ffmpeg -v error -i "$JOB/input/hero.jpg" \
  -vf "scale=80:-1,palettegen=max_colors=6" -y "$JOB/frames/palette.png"
```

Then look at `palette.png` and read the swatches. Six colors is enough — a video needs a background, a text color, one accent and maybe a secondary. Write the hex codes into `brief.md` §6 rather than keeping them in your head, and say which image they came from.

If a brand guide gives explicit hex codes, those win over anything sampled from a photo. Sampling is what you do when nobody wrote the codes down.

## The accounting rule

**Every file in `input/` is either used or explicitly declined, in writing, in `brief.md`.**

```markdown
## Supplied references

| File | What I took from it |
|---|---|
| logo.svg | The mark. Used at 38% frame width in beats 1 and 4. |
| brand-guide.pdf | Palette (#0B0B0B / #F5F5F5 / #E1FF41) and Inter Black for headlines. |
| hero.jpg | Nothing — 640×480, too soft for a full-frame background. Said so, proposed a gradient instead. |
| mockup.psd | Could not open. Asked for a PNG export; proceeded without it. |
```

A file the user took the trouble to supply and never heard about again is the fastest way to lose their trust in the whole process. Declining a file with a reason is fine. Silence is not.

## Rescan before you render

Files arrive late — someone finds the logo after they have already answered your questions. Run the scan a second time immediately before building, and compare against what you scanned in Phase 1.

If something new appeared *after* the creative direction was agreed, say what it changes:

> Your brand guide arrived after we picked Direction B. Two things move: headline type
> becomes Inter Black instead of my proposal, and the accent goes #E1FF41. Pacing and
> structure are unchanged. Say the word if you'd rather I hold the original look.

Then let the user decide. Do not quietly rebuild around the new file, and do not quietly ignore it.

## When the files contradict the brief

The file wins on **facts** — the logo is whatever the file says it is, the hex code is whatever the guide says, the legal line is whatever the copy deck says. The user wins on **intent** — if the guide is corporate-blue and they asked for something loud, they are allowed to want that.

When the two genuinely collide, surface it in one sentence and let them answer:

> Your guide fixes the accent at navy, but you asked for high-energy neon. I can keep the
> navy and get the energy from pacing, or use the neon and break the guide. Which?
