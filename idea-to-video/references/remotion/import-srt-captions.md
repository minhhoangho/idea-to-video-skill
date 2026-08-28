# Importing SRT subtitles

When the user supplies a subtitle file — often the case for repurposed long-form video.

```bash
npm i @remotion/captions
```

```tsx
import { parseSrt } from '@remotion/captions';
import { staticFile, delayRender, continueRender } from 'remotion';

const [captions, setCaptions] = useState<Caption[]>([]);
const [handle] = useState(() => delayRender('loading captions'));

useEffect(() => {
  fetch(staticFile('captions.srt'))
    .then((r) => r.text())
    .then((input) => { setCaptions(parseSrt({ input }).captions); continueRender(handle); })
    .catch(() => continueRender(handle));
}, [handle]);
```

The `catch` that still calls `continueRender` is not optional — without it a missing or malformed file hangs the render indefinitely rather than failing.

Each caption carries `startMs`, `endMs` and `text`. Convert to frames with `(ms / 1000) * fps`.

## Reality of supplied SRT files

- Timings are frequently off by a fixed offset. Check the first and last cue against the audio before trusting the middle.
- Line breaks inside a cue are meaningful to the person who wrote them; preserve them rather than collapsing to one line.
- Cue text often contains HTML-ish tags (`<i>`, `{\an8}`). Strip them, or they render literally.

## Simpler alternative

Loading at module scope avoids the state dance entirely if the file is small: import it as raw text through the bundler and parse once. Reach for `fetch` + `delayRender` only when the file must stay in `public/`.
