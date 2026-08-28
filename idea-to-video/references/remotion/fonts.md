# Fonts

## Google Fonts

```bash
npm i @remotion/google-fonts
```

```tsx
import { loadFont } from '@remotion/google-fonts/Inter';
const { fontFamily } = loadFont('normal', { weights: ['400', '800'] });
```

`loadFont` blocks rendering until the font is ready, which is the point — text measured against a fallback and then reflowed produces a one-frame jump that looks like a glitch.

Load only the weights you use. Each one is a download on every render worker.

## Local fonts

The right choice when the user supplied a brand font in `input/`. Copy it into `public/fonts/` and load it:

```tsx
import { staticFile, delayRender, continueRender } from 'remotion';

const waitForFont = delayRender('loading brand font');
const font = new FontFace('BrandSans', `url(${staticFile('fonts/Brand-Black.woff2')})`);
font.load().then(() => {
  document.fonts.add(font);
  continueRender(waitForFont);
}).catch(() => continueRender(waitForFont));
```

**The `catch` matters.** Without it a missing font hangs the render forever instead of falling back and finishing.

Do this once at module scope, not inside a component — a `useEffect` runs per frame worker and re-registers the font thousands of times.

## Licensing

A font in the user's `input/` is not automatically a font they may embed in a video. Check before shipping, and say so in the brief if you are unsure.

## Why not a `<link>` tag

A stylesheet link is fetched asynchronously with nothing blocking the frame capture. You get the fallback font on early frames and the real one later — the classic "the first second uses Times New Roman" bug.
