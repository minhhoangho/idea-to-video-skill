# Trimming — cutting the start or end of animations

Three different things get called trimming. They are not interchangeable.

## Trimming a media file

`startFrom` and `endAt` on `<OffthreadVideo>` and `<Audio>`, measured in frames of the *composition*:

```tsx
<OffthreadVideo src={staticFile('clip.mp4')} startFrom={60} endAt={210} />
```

The clip begins 2 seconds in (at 30fps) and stops after 5 seconds of playback. Nothing is re-encoded; this is a playback window.

## Trimming a sequence

`<Sequence from={} durationInFrames={}>` controls when children exist. Children see their own local frame starting at 0 — which is what you want, and also the thing that surprises people who expect composition frames.

## Trimming an animation's tail

An animation that finishes at frame 40 in a 90-frame scene needs no trimming; `extrapolateRight: 'clamp'` holds the end value. Reach for a negative `from` when you want to *start* mid-animation:

```tsx
<Sequence from={-20}>{/* enters already 20 frames in */}</Sequence>
```

## The mistake to avoid

Do not trim by conditionally returning `null` from a component based on `useCurrentFrame()` when the element also animates — you get a hard pop instead of an exit. Give it a real exit (`Reveal`'s `exitAt`) or wrap it in a `<Sequence>` whose end coincides with a cut, where a pop is invisible.
