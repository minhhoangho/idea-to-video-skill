# Track A — Remotion (code-driven motion graphics)

Use this track when the video is *about* something specific: a brand, a product, an idea with exact words and colors. Remotion renders deterministically from React, so text is exact, colors are exact, and any revision is a re-render rather than a re-generation.

Requires Node.js 18+ and ffmpeg on the machine.

## Scaffold

`create-video@latest` has an interactive CLI that hangs in non-TTY agent shells. Build the project manually instead, or run:

```bash
JOB=$(scripts/new_project.sh <slug>)          # creates the job folder
scripts/scaffold_remotion.sh <slug> 1080 1920 30 "$JOB/project"
```

The scaffold script copies `assets/theme.ts` into the project for you. Manual equivalent, inside an existing job folder:

```bash
mkdir -p "$JOB"/project/src/scenes "$JOB"/project/public/audio "$JOB"/project/public/images
cd "$JOB/project"
cat > package.json <<'EOF'
{
  "name": "video",
  "private": true,
  "scripts": {
    "dev": "remotion studio",
    "render": "remotion render"
  },
  "dependencies": {
    "@remotion/cli": "4.0.*",
    "remotion": "4.0.*",
    "react": "^19",
    "react-dom": "^19"
  },
  "devDependencies": { "typescript": "^5", "@types/react": "^19" }
}
EOF
npm install
```

Copy `assets/theme.ts` into `src/theme.ts` and fill in the palette agreed in the brief.

Composition sizes: 1080×1920 for 9:16, 1080×1080 for 1:1, 1920×1080 for 16:9. Use 30 fps unless the user asked otherwise — 60 fps doubles render time for motion graphics that rarely need it.

## The ten motion rules

These are the difference between "an AI made this" and "an editor made this". Follow all ten.

1. **No linear interpolation, ever.** Use `spring()` or `interpolate()` with a bezier easing, always with `extrapolateLeft: 'clamp', extrapolateRight: 'clamp'`. Linear motion is the single loudest tell of generated video.
2. **Entrances animate 2–3 properties together** — opacity + translateY + scale. One-property fades read as unfinished.
3. **Stagger everything.** Sibling elements enter 3–6 frames apart. Simultaneous arrival looks mechanical.
4. **Exits exist and are faster than entrances**, roughly 60% of the duration. Elements that simply cut away feel abrupt.
5. **Five-layer stack on every scene:** background mesh → media assets → graphics/text → color grade → grain + vignette. Skipping the top two layers is why generated video looks digital and cheap.
6. **Every still gets Ken Burns** (slow scale 1.0→1.08 plus a small drift). Use `<OffthreadVideo>` for footage, never `<Video>` in renders.
7. **Idle elements breathe.** Between beats, apply a sine-wave micro-motion (1–2% scale or 2–4px drift over 3–5 seconds).
8. **All timing derives from `fps`.** Write `fps * 0.4`, never the literal `12`. Magic frame numbers break the moment the composition changes frame rate.
9. **One `theme.ts`.** No inline hex codes, no inline easing curves. Every color, spring preset and duration lives in the theme so a palette change is a one-line edit.
10. **Render → inspect frames → fix → re-render.** Never deliver a file you have not looked at. See `qa-and-delivery.md`.

## Structure

One file per scene under `src/scenes/`, composed in `src/Root.tsx` with `<Sequence>` and explicit `from`/`durationInFrames` derived from the beat structure in the brief. Keep each scene under ~150 lines; if it grows past that, the scene is doing two jobs.

These primitives already exist. `scaffold_remotion.sh` copies `assets/components/` into `src/components/`, so `Reveal`, `Stagger`, `KenBurns`, `Breathe`, `Grain`, `Vignette`, `Grade`, `SafeArea` and a `Scene` wrapper that stacks them in the right order are there before you write a line. On top of them sit `HeroTitle`, `KineticLines`, `StatCounter`, `BulletList`, `ProcessSteps`, `ComparisonPair`, `Caption`, `MediaPlate`, `DeviceFrame` and `LogoLockup`.

`src/components/README.md` maps "what this beat has to do" onto which component to reach for. Read it before writing a scene, and compose from these rather than re-animating from scratch — consistency across scenes is what makes a video feel authored rather than assembled.

Sizes come from `layout(useVideoConfig())` in `theme.ts`, which resolves the fraction-based tokens against the real composition. That indirection is what lets the same scenes re-cut from 9:16 to 1:1 without a second set of numbers, so a hardcoded `fontSize: 64` in a scene file quietly costs you that.

## Captions

For word-synced captions, use `@remotion/captions` with a transcript, or drive them from a timing array in the brief. Style rules that survive mobile: 
- 5–7% of composition height for font size on vertical
- heavy weight, tight tracking
- solid stroke or a dark rounded plate behind, never a drop shadow alone
- positioned in the lower third but above the platform UI safe area (bottom 15% on TikTok/Reels)
- one line at a time on vertical, maximum two

## Audio

Place files in `public/audio/`, load with `staticFile()`. Use `<Audio>` with `volume={}` as a function of frame to duck music under narration. Trim with `startFrom`/`endAt` rather than editing files.

## Render

Renders go to the job's `out/`, versioned and never overwritten (see `project-structure.md`):

```bash
npx remotion render Main ../out/<slug>_1080x1920_v1.mp4 --codec=h264 --crf=18
```

For a preview pass while iterating, render a shorter frame range or scale down:

```bash
npx remotion render Main /tmp/preview.mp4 --frames=0-90 --scale=0.5
```

Previews are scratch — keep them out of `out/`, which holds only renders you would consider delivering.

If the user wants to review interactively and a tunnel is available, `npx remotion studio` on port 3000 lets them scrub and request changes; edits hot-reload.

## Common failures

| Symptom | Cause |
|---|---|
| Render hangs at 0% | Interactive CLI prompt, or a font/asset fetched from network at render time — bundle assets locally |
| Text clipped on mobile | Ignored safe areas; keep 10% margins on vertical, 15% at the bottom |
| Flicker on video layers | Used `<Video>` instead of `<OffthreadVideo>` |
| Animation jumps at scene boundary | `from` offsets not derived from a single beat table |
| Colors look washed | Grade layer applied under the text layer instead of over the media layer |
