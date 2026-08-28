# GIFs

```bash
npm i @remotion/gif
```

```tsx
import { Gif } from '@remotion/gif';

<Gif src={staticFile('reaction.gif')} width={480} height={270} fit="cover" />
```

A plain `<img src="x.gif">` animates on wall-clock time, so in a render it freezes on whatever frame the browser happened to be showing. `<Gif>` maps the GIF's own timeline onto `useCurrentFrame()`, which is what makes it deterministic.

`getGifDurationInSeconds()` reads the length, for sizing a Sequence around it.

## Rendering *to* a GIF

```bash
npx remotion render Main out/loop.gif --codec=gif --every-nth-frame=2 --width=640
```

GIF has a 256-colour palette, so gradients band badly — the mesh backdrop this skill uses by default is close to a worst case. For a looping clip on the web, prefer WebM or a muted mp4; reach for GIF only when the destination genuinely cannot take video.
