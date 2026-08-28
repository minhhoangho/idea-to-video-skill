# Timing — interpolate, spring, easing

## interpolate

Maps a frame range onto a value range.

```tsx
const opacity = interpolate(frame, [0, 20], [0, 1], {
  easing: Easing.bezier(0.16, 1, 0.3, 1),
  extrapolateLeft: 'clamp',
  extrapolateRight: 'clamp',
});
```

**Always pass both `extrapolate` options.** The default is `'extend'`, which keeps computing past the range — an opacity that reaches 1 at frame 20 carries on to 3.5 at frame 90, and the element silently over-brightens or flies off screen.

Multi-stop ranges work and are the clean way to write hold-then-leave:

```tsx
interpolate(frame, [0, 15, 75, 90], [0, 1, 1, 0], { extrapolateRight: 'clamp' });
```

Input ranges must be strictly increasing, and both arrays must be the same length.

## Easing

`Easing.bezier(...)` covers almost everything. Named helpers exist (`Easing.out(Easing.cubic)`, `Easing.inOut(Easing.quad)`) but a bezier is easier to reason about and easier to keep consistent across a project.

**Linear is the loudest tell of generated video.** If you pass no easing you get linear. The theme's `easing` object exists so no scene file has to make this decision twice.

## spring

Physical motion, and the better default for anything entering.

```tsx
const s = spring({ frame: frame - at, fps, config: { damping: 200, stiffness: 220, mass: 0.6 } });
```

- `damping: 200` with no overshoot is the workhorse for text.
- Lower damping (10–15) overshoots — right for a logo, wrong for a paragraph.
- `spring` returns roughly 0→1 but **can exceed 1** while overshooting. Clamp it if you are driving opacity: `Math.min(1, s)`.

`springTiming` and `measureSpring` let you find how long a spring actually takes, which matters when a later element has to wait for it.

## Everything derives from fps

Write `Math.round(fps * 0.4)`, never `12`. A composition switched from 30 to 60 fps with hardcoded frame counts plays every animation at half speed, and the failure looks like bad taste rather than a bug.
