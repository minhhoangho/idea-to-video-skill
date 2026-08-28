# Images

```tsx
import { Img, staticFile } from 'remotion';

<Img src={staticFile('images/logo.png')} style={{ width: '100%' }} />
```

**Use `<Img>`, never a bare `<img>`.** `<Img>` blocks the frame from being captured until the image has decoded. A plain `<img>` renders whenever it happens to be ready, which produces frames where the image is missing — intermittently, and usually only in the final render rather than in the Studio.

The same applies to CSS `background-image`: the renderer cannot wait for it. If you need a background image, put an `<Img>` in an `<AbsoluteFill>` with `objectFit: 'cover'` underneath your content.

## Sizing

```tsx
<Img src={...} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
```

`cover` crops, `contain` letterboxes. For a logo, `contain` inside a fixed-width box is almost always right; `cover` on a logo crops the mark.

## Remote images

`<Img src="https://…">` works, but the fetch happens during render, on every frame worker. A flaky host turns into a failed render an hour in. Download into `public/` first — this is also why the skill copies files out of the job's `input/` rather than referencing them from elsewhere.

## Resolution

An image narrower than the box it fills gets upscaled and looks soft, and on a 1080×1920 composition that threshold is higher than people expect. `scan_input.sh` reports the fraction of frame width each supplied image can cover, precisely so this is caught before a composition is built around it.
