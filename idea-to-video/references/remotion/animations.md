# Animations — the one rule everything else rests on

Every animated value in Remotion is a pure function of `useCurrentFrame()`. There is no timeline running, no state advancing: the renderer asks your component "what do you look like at frame 137?" and expects the same answer every time it asks.

```tsx
const frame = useCurrentFrame();
const { fps, durationInFrames, width, height } = useVideoConfig();
```

## What this forbids

- **CSS transitions and `@keyframes`.** They animate against wall-clock time, which does not exist during a render. The frame is captured whenever the browser happens to be, so you get either the start state on every frame or a random smear.
- **Tailwind's `animate-*` classes.** Same reason — they compile to CSS animations.
- **`setInterval`, `requestAnimationFrame`, `useState` counters.** All wall-clock.
- **`Math.random()` and `Date.now()` in render.** Different value per frame means flicker. Use Remotion's `random(seed)`, which is deterministic.

If an element moves and you cannot point at the `useCurrentFrame()` that moves it, it will not move in the output.

## What this enables

Rendering is parallel and resumable precisely because frame 500 does not depend on frame 499. It is also why you can scrub the Studio timeline instantly, and why a failed render can restart mid-way.

## The shape of every animation

```tsx
const progress = spring({ frame: frame - startAt, fps, config: springs.snappy });
return <div style={{ opacity: progress, transform: `translateY(${(1 - progress) * 40}px)` }} />;
```

Offset the frame (`frame - startAt`) rather than wrapping in a `<Sequence>` when you only need to delay one property. Use `<Sequence>` when the element should also unmount.

See `timing.md` for choosing between `spring` and `interpolate`.
