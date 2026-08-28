# Text animation

## Per-line

The default, and the one that reads as deliberate. `KineticLines` in the component library does it: each line is a `Reveal` offset by a stagger.

## Per-word

```tsx
{text.split(' ').map((word, i) => (
  <span key={i} style={{ display: 'inline-block' }}>
    <Reveal at={i * 2}>{word}&nbsp;</Reveal>
  </span>
))}
```

`display: inline-block` is required — a `transform` on an inline element does nothing. The non-breaking space keeps words apart once they are inline-blocks.

Two frames per word at 30fps is fast enough to feel like speech. Four is a dramatic reading.

## Per-character

Reserve for short strings — a logo, a number, a single word. Character-by-character on a full sentence reads as a typewriter effect whether you intended one or not, and it takes far too long.

## Typewriter

```tsx
const chars = Math.floor(interpolate(frame, [0, 45], [0, text.length], {
  extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
}));
return <>{text.slice(0, chars)}</>;
```

Add a blinking caret driven by `Math.floor(frame / 15) % 2` — without it the text looks like it is loading rather than being typed.

Reserve the whole width from the start (a fixed-height container, or a hidden full-string copy) or the layout shifts as characters arrive.

## What to avoid

- Animating `letter-spacing` or `font-size` — both trigger layout on every frame and are slow.
- Animating `filter: blur()` on large text: expensive, and it usually reads as a mistake.
- Everything arriving at once. Rule 3 exists because simultaneous arrival is the most recognisable sign of a generated video.
