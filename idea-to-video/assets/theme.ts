/**
 * Design tokens for a Remotion project.
 * Rule 9 of the motion rules: nothing in a scene file hardcodes a color,
 * an easing curve, or a duration. Everything routes through here, so a
 * palette swap is one edit instead of forty.
 *
 * Copy to src/theme.ts and fill from section 6 of the brief.
 */

import { Easing } from 'remotion';

export const colors = {
  bg: '#0A0A0F',
  bgElevated: '#14141C',
  text: '#FFFFFF',
  textMuted: 'rgba(255,255,255,0.62)',
  accent: '#6366F1',
  accentAlt: '#00D4FF',
} as const;

export const font = {
  family: 'Inter, system-ui, sans-serif',
  headline: { weight: 800, lineHeight: 1.0, letterSpacing: '-0.02em' },
  body: { weight: 400, lineHeight: 1.45, letterSpacing: '0em' },
  /** Sizes as a fraction of composition height — keeps 9:16 and 16:9 in sync. */
  scale: { hero: 0.085, headline: 0.062, body: 0.034, caption: 0.055 },
} as const;

/** Rule 1: never linear. These are the only easings allowed. */
export const easing = {
  outExpo: Easing.bezier(0.16, 1, 0.3, 1),
  outQuint: Easing.bezier(0.22, 1, 0.36, 1),
  inOut: Easing.bezier(0.65, 0, 0.35, 1),
  /** For exits — faster, slightly aggressive. */
  inQuint: Easing.bezier(0.64, 0, 0.78, 0),
} as const;

/** Spring presets. `snappy` for text, `soft` for large shapes, `bouncy` for logos. */
export const springs = {
  snappy: { damping: 200, stiffness: 220, mass: 0.6 },
  soft: { damping: 200, stiffness: 90, mass: 1 },
  bouncy: { damping: 12, stiffness: 140, mass: 0.8 },
} as const;

/**
 * Rule 8: all timing derives from fps. Call these with useVideoConfig().fps
 * instead of writing frame counts inline.
 */
export const timing = (fps: number) => ({
  enter: Math.round(fps * 0.6),
  /** Rule 4: exits run ~60% of the entrance. */
  exit: Math.round(fps * 0.36),
  /** Rule 3: sibling offset. */
  stagger: Math.round(fps * 0.13),
  hold: Math.round(fps * 1.2),
  transition: Math.round(fps * 0.5),
});

/** Rule 5: the five-layer stack, top to bottom. Intensities, not booleans. */
export const layers = {
  grainOpacity: 0.055,
  vignetteStrength: 0.35,
  gradeWarmth: 0.06,
  meshDriftSeconds: 14,
} as const;

/** Rule 7: idle breathe. Amplitude in scale units, period in seconds. */
export const idle = { amplitude: 0.015, periodSeconds: 4 } as const;

/** Platform safe areas as fractions of composition height. */
export const safeArea = { top: 0.08, bottom: 0.15, side: 0.08 } as const;
