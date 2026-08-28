# Component library

Copied into every scaffolded project as `src/components/`. Import from the barrel:

```tsx
import { Scene, HeroTitle, KineticLines, Caption } from '../components';
```

## Pick by what the beat has to do

| The beat needs to… | Use | Notes |
|---|---|---|
| Open with one statement | `HeroTitle` | One idea. Competing elements kill a hook. |
| Deliver a line at a time | `KineticLines` | Wrap words in `*asterisks*` to accent them. |
| Land a number | `StatCounter` | Eased, tabular figures, optional label. |
| List features or reasons | `BulletList` | `marker="number"` for ranked lists. |
| Explain a sequence | `ProcessSteps` | Numbered, connected, staggered. |
| Contrast two things | `ComparisonPair` | Right panel lands late so the contrast registers. |
| Show footage or a photo | `MediaPlate` | Auto-detects video, Ken Burns on stills, scrim for legibility. |
| Show a screenshot | `DeviceFrame` | The bezel is what makes it read as an app. |
| Close on the brand | `LogoLockup` | Mark, then wordmark, then CTA — in that order. |
| Burn in narration | `Caption` | Sits above the platform safe area, dark plate by default. |

## Structure every scene the same way

```tsx
import { Scene, HeroTitle, MediaPlate } from '../components';

export const Hook: React.FC = () => (
  <Scene media={<MediaPlate src="images/hero.jpg" />}>
    <HeroTitle>Ba giây đầu quyết định</HeroTitle>
  </Scene>
);
```

`Scene` supplies the five-layer stack from motion rule 5 — backdrop, media, grade, content, vignette and grain — in the right order. That order is not decorative: the grade belongs *over* the media and *under* the text, and getting it backwards is why generated video so often looks washed out.

## The primitives underneath

`Reveal` is the three-property entrance (opacity + translate + scale) with an exit at 60% of the entrance duration. `Stagger` applies it across siblings so you stop hand-writing `at={i * 4}`. `KenBurns`, `Breathe`, `Grain`, `Vignette`, `Grade` and `SafeArea` are the rest of the rules as code.

Reach for these when building something the table above does not cover. Do not animate opacity by hand in a scene file — a video where entrances almost match is worse than one where they obviously differ.

## Two rules that outrank the library

**Sizes come from `layout(useVideoConfig())`, never from literals.** Every token is a fraction of the composition, which is what lets one composition re-cut from 9:16 to 1:1 without a second set of numbers. A hardcoded `fontSize: 64` silently breaks that.

**Timing comes from `fps`.** Write `Math.round(fps * 0.4)`, never `12`. The library already does this internally; scene files have to as well.

## When nothing fits

Write the component, but build it from the primitives and the theme rather than from scratch, and keep it in `src/components/` next to these. A one-off that ignores `theme.ts` is a one-off that looks like a different video.
