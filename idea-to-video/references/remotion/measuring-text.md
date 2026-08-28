# Measuring and fitting text

```bash
npm i @remotion/layout-utils
```

## The problem

Copy comes from a brief, not from a designer. A headline that fits at 92px in one job overflows in the next, and in a video there is no scrollbar to reveal it — the text is simply cut off, and only a frame inspection catches it.

## fitText

```tsx
import { fitText } from '@remotion/layout-utils';

const { fontSize } = fitText({
  text: title,
  withinWidth: width * 0.84,
  fontFamily: 'Inter',
  fontWeight: '800',
});
```

Cap the result, or a two-word headline becomes absurdly large:

```tsx
const size = Math.min(fontSize, height * 0.085);
```

## measureText

```tsx
const { width: w, height: h } = measureText({ text, fontFamily, fontWeight, fontSize });
```

Use it to decide between one line and two, or to size a caption plate to its content.

## Load the font first

Both functions measure with whatever font is currently available. Call them after the font has loaded, or you measure the fallback and lay out against numbers that are wrong by 10–20%.

## Cheaper alternative

For a fixed layout, `fontSize` as a fraction of composition height (as `theme.ts` does) plus a hard character budget in the brief solves most cases without a measuring pass. Reach for `fitText` when the copy genuinely varies — parameterised videos, data-driven batches.
