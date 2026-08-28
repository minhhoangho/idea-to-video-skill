/**
 * One import for every scene file:
 *
 *   import { Scene, HeroTitle, KineticLines, Caption } from '../components';
 *
 * Compose from these rather than re-animating from scratch. Consistency across
 * scenes is most of what makes a video feel authored rather than assembled.
 */

export { Reveal, Stagger, KenBurns, Breathe, Grain, Vignette, Grade, SafeArea } from './primitives';
export { Backdrop, Scene, WipeIn } from './scene';
export {
  HeroTitle,
  KineticLines,
  StatCounter,
  BulletList,
  ProcessSteps,
  ComparisonPair,
  Caption,
} from './content';
export { MediaPlate, DeviceFrame, LogoLockup } from './media';
