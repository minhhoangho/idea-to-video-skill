# Transitions between scenes

`@remotion/transitions` handles the overlap arithmetic that hand-rolled crossfades get wrong.

```bash
npm i @remotion/transitions
```

```tsx
import { TransitionSeries, linearTiming, springTiming } from '@remotion/transitions';
import { fade } from '@remotion/transitions/fade';
import { slide } from '@remotion/transitions/slide';
import { wipe } from '@remotion/transitions/wipe';

<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={90}><Hook /></TransitionSeries.Sequence>
  <TransitionSeries.Transition presentation={slide({ direction: 'from-right' })}
                               timing={springTiming({ config: { damping: 200 } })} />
  <TransitionSeries.Sequence durationInFrames={120}><Body /></TransitionSeries.Sequence>
</TransitionSeries>
```

**The transition eats frames from both neighbours.** A 30-frame transition between two 90-frame scenes yields 150 frames, not 180. Compute the composition length from the same arithmetic or the last scene gets clipped.

## Choosing one

| Presentation | Reads as |
|---|---|
| `fade` | Soft, neutral. Safe over footage, mushy between motion-graphics scenes. |
| `slide` | Directional, energetic. The default for short-form. |
| `wipe` | Graphic, deliberate. Good when the two scenes share a background. |
| `clockWipe` | Stylised. Use once per video at most. |
| `flip` | Playful; easy to overuse. |
| `none` | A hard cut, with the timing still reserved. |

**Between two animating scenes, a hard cut usually beats a crossfade.** Both scenes are still moving underneath a fade, and the result reads as a mistake rather than a choice. `WipeIn` in the component library covers the common case without pulling in the package.

Custom presentations are just components receiving `presentationProgress`; write one when a brand needs a signature transition, not to be clever.
