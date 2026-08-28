# Rendering

```bash
npx remotion render Main ../out/<slug>_1080x1920_v1.mp4 --codec=h264 --crf=18
```

Renders land in the job's `out/`, versioned, never overwritten.

## Flags worth knowing

| Flag | Effect |
|---|---|
| `--codec=h264` | The default and the right answer for delivery |
| `--crf=18` | Quality; lower is better and larger. 18 is visually lossless, 23 is the default, 28 is visibly soft |
| `--frames=0-90` | Render a slice. Use this constantly while iterating |
| `--scale=0.5` | Half-resolution preview, roughly four times faster |
| `--concurrency=4` | Cap parallel workers when the machine is thrashing |
| `--props=./props.json` | Feed a parameterised composition |
| `--image-format=png` | Required for any render with transparency |
| `--log=verbose` | When a render fails with no useful message |

## Preview versus deliverable

```bash
npx remotion render Main /tmp/preview.mp4 --frames=0-90 --scale=0.5
```

Previews are scratch and belong outside `out/`, which holds only renders you would consider delivering. Iterating at full resolution on the whole timeline is the most common way to waste an hour.

## Studio

```bash
npx remotion studio
```

Scrub, adjust props, hot-reload. When the user can reach it, this is a far better review loop than sending files back and forth.

## Common failures

| Symptom | Cause |
|---|---|
| Hangs at 0% | A `delayRender` that never continues — usually a font or fetch with no `catch` |
| Fails at the encoder | Odd composition width or height |
| Some frames missing an image | A bare `<img>` instead of `<Img>` |
| Much slower than expected | 4K sources, several video layers, or a 3D scene |
| Output plays too fast or slow | Hardcoded frame counts after an fps change |

Then extract frames and actually look at them: `scripts/inspect_frames.sh`. A render that completed is not a render that is good.
