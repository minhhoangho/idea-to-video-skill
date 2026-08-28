# Audio

```tsx
import { Audio, staticFile } from 'remotion';

<Audio src={staticFile('audio/music.mp3')} volume={0.4} />
```

Audio is placed in time by its enclosing `<Sequence>`, exactly like a visual element. An `<Audio>` inside `<Sequence from={90}>` starts at composition frame 90.

## Volume as a function

```tsx
<Audio
  src={staticFile('audio/music.mp3')}
  volume={(f) => interpolate(f, [0, 30], [0, 0.5], { extrapolateRight: 'clamp' })}
/>
```

The argument is the frame **relative to the Sequence**, not the composition. This is the mechanism for ducking music under narration, which is the single audio change that most improves a narrated video:

```tsx
volume={(f) => (isNarrating(f) ? 0.18 : 0.5)}
```

Music held at a constant level under speech is the most common mix mistake in generated video.

## Trimming

`startFrom` and `endAt`, in composition frames — same as video. Prefer this to editing the file, so the source stays intact and a revision is a prop change.

## Rendering audio only

```bash
npx remotion render Main out/audio.mp3 --codec=mp3
```

Useful for checking a voice-over before spending a video render.

## Getting durations

Scene lengths on the narrated track come from `ffprobe` via `scripts/narrate.sh`, which writes them into `audioConfig.ts`. Inside a composition, `parseMedia` can do the same at render time — see `get-audio-duration.md`.
