# Compositions — declaring what can be rendered

```tsx
export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="Main"
      component={Main}
      durationInFrames={600}
      fps={30}
      width={1080}
      height={1920}
      defaultProps={{ title: 'Hello' }}
    />
    <Still id="Thumbnail" component={Thumb} width={1080} height={1920} />
  </>
);
```

The `id` is what you pass to `remotion render`. Keep it stable — a renamed composition breaks every script and npm alias that referenced it.

## Rules that bite

- `durationInFrames` must be at least 1, and **integer**. A computed duration needs `Math.round`, not `Math.floor` — flooring drops the last frame of the last scene.
- `width` and `height` must be even numbers for h264. 1080×1920, 1080×1080, 1920×1080 are all fine; an odd height fails at the encoder, long after the render looks like it is working.
- Multiple compositions in one project is the normal way to ship several aspect ratios from one set of scenes.

## Deriving the duration

Never hardcode a length that is really the sum of something else. Either compute it from the beat table:

```tsx
durationInFrames={beats.reduce((n, b) => n + Math.round(b.seconds * fps), 0)}
```

or, on the narrated track, from the generated config:

```tsx
import { FPS, TOTAL_FRAMES } from './audioConfig';
```

For a duration that depends on a file the component has to load — a video's length, an audio track — use `calculateMetadata`. See `calculate-metadata.md`.

## Folder

`<Folder name="Scenes">` groups compositions in the Studio sidebar. Cosmetic, but on a project with six aspect ratios it is the difference between finding a composition and hunting for it.
