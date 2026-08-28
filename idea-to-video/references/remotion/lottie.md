# Lottie

```bash
npm i @remotion/lottie lottie-web
```

```tsx
import { Lottie, LottieAnimationData } from '@remotion/lottie';

const [data, setData] = useState<LottieAnimationData | null>(null);
const [handle] = useState(() => delayRender('loading lottie'));

useEffect(() => {
  fetch(staticFile('animation.json'))
    .then((r) => r.json())
    .then((d) => { setData(d); continueRender(handle); })
    .catch(() => continueRender(handle));
}, [handle]);

if (!data) return null;
return <Lottie animationData={data} loop={false} playbackRate={1} />;
```

The component drives the animation from `useCurrentFrame()`, so it renders deterministically — which a raw `lottie-web` player would not.

`getLottieMetadata(data)` gives `durationInFrames` and the animation's own fps, for sizing a Sequence around it.

## Frame-rate mismatch

A Lottie exported at 60fps in a 30fps composition plays at half speed unless you set `playbackRate={2}`. Check the metadata rather than assuming; this is the most common Lottie complaint and it looks like the file is broken.

## When it is worth it

An icon animation or a logo sting a designer already made in After Effects. Do not reach for Lottie to do something the primitives already do — a fade-in from a JSON file is a dependency and a fetch for no gain.
