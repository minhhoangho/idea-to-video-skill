# Remotion reference

Load only the file you need. `track-remotion.md` covers craft — the ten motion rules, structure, the render loop. These cover API.

## Core

| File | Covers |
|---|---|
| [animations.md](animations.md) | `useCurrentFrame`, and why CSS animation cannot work |
| [timing.md](timing.md) | `interpolate`, `spring`, easing, `extrapolate` |
| [sequencing.md](sequencing.md) | `Sequence`, `Series`, `Loop`, `premountFor` |
| [compositions.md](compositions.md) | `Composition`, `Still`, `Folder`, duration rules |
| [transitions.md](transitions.md) | `TransitionSeries`, and when a hard cut is better |
| [trimming.md](trimming.md) | The three different things called trimming |

## Media

| File | Covers |
|---|---|
| [images.md](images.md) | `<Img>` and why never a bare `<img>` |
| [videos.md](videos.md) | `<OffthreadVideo>`, trimming, playback rate |
| [audio.md](audio.md) | `<Audio>`, volume as a function, ducking |
| [gifs.md](gifs.md) | `@remotion/gif`, and rendering to GIF |
| [assets.md](assets.md) | `staticFile` vs `import`, `public/` |
| [transparent-videos.md](transparent-videos.md) | Alpha channels, codecs, `--image-format=png` |

## Text

| File | Covers |
|---|---|
| [fonts.md](fonts.md) | Google Fonts, local fonts, `delayRender` |
| [text-animations.md](text-animations.md) | Per-line, per-word, per-character, typewriter |
| [measuring-text.md](measuring-text.md) | `fitText`, `measureText`, overflow |
| [measuring-dom-nodes.md](measuring-dom-nodes.md) | `getBoundingClientRect` deterministically |

## Captions

| File | Covers |
|---|---|
| [captions.md](captions.md) | Styling for mobile, timing from a script you wrote |
| [import-srt-captions.md](import-srt-captions.md) | `parseSrt`, and what supplied SRT files get wrong |
| [transcribe-captions.md](transcribe-captions.md) | Local whisper for word timestamps — no API key |

## Data and advanced

| File | Covers |
|---|---|
| [charts.md](charts.md) | Hand-drawn SVG, staggered bars, direct labels |
| [maps.md](maps.md) | GeoJSON. The only topic here that can need a key — avoid it |
| [lottie.md](lottie.md) | `@remotion/lottie`, frame-rate mismatch |
| [3d.md](3d.md) | `@remotion/three`, `ThreeCanvas`, render cost |

## Configuration

| File | Covers |
|---|---|
| [parameters.md](parameters.md) | Zod schemas, batch generation |
| [calculate-metadata.md](calculate-metadata.md) | Duration and size decided at render time |
| [tailwind.md](tailwind.md) | Setup, and why every `animate-*` class is broken |

## Files and rendering

| File | Covers |
|---|---|
| [probing-media.md](probing-media.md) | ffprobe vs `parseMedia`, decodability |
| [extract-frames.md](extract-frames.md) | QA frames, studying a reference clip |
| [rendering.md](rendering.md) | CLI flags, preview passes, common failures |

## The four rules underneath all of it

1. Every animated value is a function of `useCurrentFrame()`.
2. No CSS transitions, `@keyframes`, or Tailwind `animate-*` — they do not render.
3. Write durations in seconds times `fps`, never as literal frame counts.
4. Nothing linear. `spring()` or a bezier, always with `extrapolate` clamped.
