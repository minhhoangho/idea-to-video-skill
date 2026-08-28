# calculateMetadata — duration and size decided at render time

Some things are not knowable when you write the `<Composition>`: how long the supplied video is, how much narration there turned out to be, what aspect ratio the props ask for.

```tsx
<Composition
  id="Main"
  component={Main}
  schema={schema}
  defaultProps={{ src: 'clip.mp4' }}
  fps={30}
  width={1080}
  height={1920}
  calculateMetadata={async ({ props }) => {
    const { slowDurationInSeconds } = await parseMedia({
      src: staticFile(props.src),
      fields: { slowDurationInSeconds: true },
      acknowledgeRemotionLicense: true,
    });
    return { durationInFrames: Math.round(slowDurationInSeconds * 30) };
  }}
/>
```

Return any of `durationInFrames`, `fps`, `width`, `height`, `props`. It runs once before rendering, not per frame.

`durationInFrames` must be a positive integer — `Math.round`, and guard against a zero-length probe:

```tsx
durationInFrames: Math.max(1, Math.round(seconds * fps))
```

## When you do not need it

On the narrated track, `narrate.sh` has already measured everything and written `TOTAL_FRAMES` into `audioConfig.ts`. Importing a constant is simpler and faster than probing at render time, and it means the number is visible in a file you can read.

Use `calculateMetadata` when the length depends on props that vary per render — the batch case — or on a media file the composition receives rather than one you generated.
