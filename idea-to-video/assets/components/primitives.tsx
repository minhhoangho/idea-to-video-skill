/**
 * The six primitives the motion rules keep referring to, plus the helpers that
 * make them composable.
 *
 * Every entrance in a video should come from `Reveal`, every still from
 * `KenBurns`, every scene from the `Grain`/`Vignette`/`Grade` stack. Writing
 * these once is what makes ten scenes look like one video instead of ten.
 */

import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  random,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { easing, idle, layers, layout, springs } from '../theme';

/**
 * Rule 2 + 4: a three-property entrance and a faster exit.
 *
 * `at` is the frame the element enters, relative to the enclosing Sequence.
 * `exitAt` defaults to "never" — pass the scene length minus a beat when an
 * element should leave before the cut.
 */
export const Reveal: React.FC<{
  children: React.ReactNode;
  at?: number;
  exitAt?: number;
  /** Pixels of upward travel. Negative enters from above. */
  distance?: number;
  preset?: keyof typeof springs;
  style?: React.CSSProperties;
}> = ({ children, at = 0, exitAt, distance = 40, preset = 'snappy', style }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const enter = spring({ frame: frame - at, fps, config: springs[preset] });

  // Rule 4: the exit runs ~60% of the entrance, so it reads as decisive rather
  // than as the entrance played backwards.
  const exitStart = exitAt ?? durationInFrames + 1;
  const exitLen = Math.round(fps * 0.36);
  const exit = interpolate(frame, [exitStart, exitStart + exitLen], [0, 1], {
    easing: easing.inQuint,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const opacity = enter * (1 - exit);
  const y = (1 - enter) * distance + exit * -distance * 0.5;
  const scale = 0.94 + enter * 0.06 - exit * 0.03;

  return (
    <div style={{ ...style, opacity, transform: `translateY(${y}px) scale(${scale})` }}>
      {children}
    </div>
  );
};

/**
 * Rule 3: siblings enter 3–6 frames apart. Wrap a list and stop hand-writing
 * `at={i * 4}` in every scene.
 */
export const Stagger: React.FC<{
  children: React.ReactNode;
  at?: number;
  /** Frames between siblings. Defaults to the theme's stagger. */
  step?: number;
  distance?: number;
}> = ({ children, at = 0, step, distance }) => {
  const { fps } = useVideoConfig();
  const gap = step ?? Math.round(fps * 0.13);
  return (
    <>
      {React.Children.map(children, (child, i) => (
        <Reveal at={at + i * gap} distance={distance}>
          {child}
        </Reveal>
      ))}
    </>
  );
};

/** Rule 6: no still image ever sits perfectly still. */
export const KenBurns: React.FC<{
  children: React.ReactNode;
  /** Total zoom across the scene. 1.08 is the default for a reason: more reads as a push. */
  to?: number;
  /** Drift in pixels, as [x, y]. */
  drift?: [number, number];
}> = ({ children, to = 1.08, drift = [0, -18] }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const t = interpolate(frame, [0, durationInFrames], [0, 1], {
    easing: easing.inOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill
      style={{
        transform: `scale(${1 + (to - 1) * t}) translate(${drift[0] * t}px, ${drift[1] * t}px)`,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

/** Rule 7: between beats, elements breathe rather than freeze. */
export const Breathe: React.FC<{
  children: React.ReactNode;
  amplitude?: number;
  periodSeconds?: number;
}> = ({ children, amplitude = idle.amplitude, periodSeconds = idle.periodSeconds }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = 1 + Math.sin((frame / (fps * periodSeconds)) * Math.PI * 2) * amplitude;
  return <div style={{ transform: `scale(${s})` }}>{children}</div>;
};

/**
 * Rule 5, top layer. Film grain via SVG turbulence — deterministic, so it
 * renders identically on every pass, and cheap enough to leave on every scene.
 */
export const Grain: React.FC<{ opacity?: number }> = ({ opacity = layers.grainOpacity }) => {
  const frame = useCurrentFrame();
  // A fresh seed each frame is what makes it read as grain rather than as a
  // texture stuck to the lens. random() keeps it reproducible across renders.
  const seed = Math.floor(random(`grain-${frame}`) * 1000);
  return (
    <AbsoluteFill style={{ opacity, pointerEvents: 'none', mixBlendMode: 'overlay' }}>
      <svg width="100%" height="100%">
        <filter id={`grain-${frame}`}>
          <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves={3} seed={seed} />
        </filter>
        <rect width="100%" height="100%" filter={`url(#grain-${frame})`} />
      </svg>
    </AbsoluteFill>
  );
};

/** Rule 5: pulls the eye to the centre. Subtle enough that nobody names it. */
export const Vignette: React.FC<{ strength?: number }> = ({
  strength = layers.vignetteStrength,
}) => (
  <AbsoluteFill
    style={{
      pointerEvents: 'none',
      background: `radial-gradient(ellipse at center, rgba(0,0,0,0) 45%, rgba(0,0,0,${strength}) 100%)`,
    }}
  />
);

/**
 * Rule 5: the grade sits *over* the media and *under* the text. Getting that
 * order wrong is why generated video so often looks washed out.
 */
export const Grade: React.FC<{ warmth?: number; tint?: string }> = ({
  warmth = layers.gradeWarmth,
  tint = '#FF9A3C',
}) => (
  <AbsoluteFill
    style={{
      pointerEvents: 'none',
      backgroundColor: tint,
      opacity: warmth,
      mixBlendMode: 'soft-light',
    }}
  />
);

/**
 * Keeps content out of the platform UI. On a 9:16 phone the bottom 15% carries
 * the caption, the share button and the progress bar — text placed there is
 * text nobody reads.
 */
export const SafeArea: React.FC<{
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ children, style }) => {
  const L = layout(useVideoConfig());
  return (
    <AbsoluteFill
      style={{
        paddingTop: L.safe.top,
        paddingBottom: L.safe.bottom,
        paddingLeft: L.safe.side,
        paddingRight: L.safe.side,
        ...style,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
