# Video

```tsx
import { OffthreadVideo, staticFile } from 'remotion';

<OffthreadVideo src={staticFile('clip.mp4')} style={{ width: '100%', objectFit: 'cover' }} />
```

## OffthreadVideo vs Video

**Use `<OffthreadVideo>` in anything that will be rendered.** It extracts the exact frame with ffmpeg instead of asking a `<video>` element to seek, which is both faster and free of the off-by-one-frame flicker that `<Video>` produces under parallel rendering.

`<Video>` is for the `<Player>` in a browser, where an actual video element is what you want.

## Props that matter

```tsx
<OffthreadVideo
  src={staticFile('clip.mp4')}
  startFrom={30}          // skip the first second at 30fps
  endAt={210}
  volume={0}              // muted b-roll under narration
  playbackRate={1.25}
  muted
/>
```

`volume` also accepts a function of frame, for ducking — see `audio.md`.

## Transparency

WebM with VP8/VP9 alpha, or ProRes 4444, plays with transparency. H.264 has no alpha channel; a "transparent" mp4 will composite as black. See `transparent-videos.md`.

## Getting the length right

A composition sized to a video needs the video's real duration, which is only knowable after probing the file. Use `calculateMetadata` with `parseMedia`, not a guess. See `get-video-duration.md`.

## Common failures

| Symptom | Cause |
|---|---|
| Flicker on video layers | `<Video>` instead of `<OffthreadVideo>` |
| First frames black | Decoder not ready — add `premountFor` on the enclosing Sequence |
| Audio out of sync after speed change | `playbackRate` changes audio pitch and length; generate the audio separately instead |
| Render slows to a crawl | Several 4K clips composited at once; downscale the sources first |
