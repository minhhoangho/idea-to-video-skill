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

/**
 * Categorical colors for data. Ordered so the first three stay distinguishable
 * to the most common forms of color blindness — a chart in a video cannot be
 * hovered for a tooltip, so the colors carry the whole message.
 */
export const series = [
  '#6366F1', '#00D4FF', '#FFB020', '#FF5C7A', '#34D399', '#A78BFA',
] as const;

/** Spacing as a fraction of the short edge, so 9:16 and 16:9 stay proportional. */
export const spacing = { xs: 0.012, sm: 0.022, md: 0.038, lg: 0.06, xl: 0.09 } as const;

/** Corner radii, same fraction basis. */
export const radius = { sm: 0.012, md: 0.022, lg: 0.04, pill: 0.5 } as const;

/**
 * Resolve the fraction-based tokens against a real composition size.
 *
 *   const L = layout(useVideoConfig());
 *   <div style={{ paddingTop: L.safe.top, fontSize: L.type.hero }} />
 *
 * Everything above is a ratio precisely so one composition can be re-cut to
 * another aspect ratio without a second set of numbers. This is the function
 * that turns those ratios into pixels; doing it by hand in a scene file is
 * what makes the re-cut stop being free.
 */
export const layout = ({ width, height }: { width: number; height: number }) => {
  const short = Math.min(width, height);
  const px = (fraction: number) => Math.round(short * fraction);
  return {
    width,
    height,
    isPortrait: height > width,
    safe: {
      top: Math.round(height * safeArea.top),
      bottom: Math.round(height * safeArea.bottom),
      side: Math.round(width * safeArea.side),
    },
    /** Usable box once platform UI is accounted for. */
    content: {
      width: width - 2 * Math.round(width * safeArea.side),
      height: height - Math.round(height * (safeArea.top + safeArea.bottom)),
    },
    type: {
      hero: Math.round(height * font.scale.hero),
      headline: Math.round(height * font.scale.headline),
      body: Math.round(height * font.scale.body),
      caption: Math.round(height * font.scale.caption),
    },
    space: {
      xs: px(spacing.xs), sm: px(spacing.sm), md: px(spacing.md),
      lg: px(spacing.lg), xl: px(spacing.xl),
    },
    radius: { sm: px(radius.sm), md: px(radius.md), lg: px(radius.lg), pill: 9999 },
  };
};

export type Layout = ReturnType<typeof layout>;
