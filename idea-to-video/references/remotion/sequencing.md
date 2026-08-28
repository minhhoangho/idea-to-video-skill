# Sequencing — Sequence and Series

## Sequence

Shifts time for its children and, by default, unmounts them outside its window.

```tsx
<Sequence from={90} durationInFrames={60}>
  <Hook />
</Sequence>
```

Inside `<Hook>`, `useCurrentFrame()` returns 0 at composition frame 90, and `useVideoConfig().durationInFrames` returns 60 — the sequence's length, not the composition's. That relativity is what lets a scene component be written once and dropped anywhere in the timeline.

- `from` may be negative, which starts the child mid-animation.
- Omit `durationInFrames` and the child runs to the end of the composition.
- `layout="none"` removes the wrapping `<AbsoluteFill>` when you need the child to sit in a flex parent.
- `premountFor={30}` mounts the child early, invisible, so videos and fonts are ready when it appears. This is the fix for "the first 5 frames of the clip are black".

## Series

Sequential scenes without hand-computing offsets.

```tsx
<Series>
  <Series.Sequence durationInFrames={60}><Hook /></Series.Sequence>
  <Series.Sequence durationInFrames={120}><Body /></Series.Sequence>
  <Series.Sequence durationInFrames={45} offset={-15}><Cta /></Series.Sequence>
</Series>
```

`offset` overlaps or gaps a scene against the previous one — negative overlaps, which is how you cross a transition without recomputing every later `from`.

Prefer `Series` when scenes are strictly one-after-another. Prefer explicit `Sequence` with a beat table when scenes overlap freely, or when the offsets come from generated data — as they do on the narrated track, where `audioConfig.ts` supplies `from` and `frames` per scene.

## Loop

```tsx
<Loop durationInFrames={30} times={4}><Pulse /></Loop>
```

Inside, the frame resets each iteration. Useful for idle motion; not a substitute for `Breathe`, which is continuous rather than restarting.
