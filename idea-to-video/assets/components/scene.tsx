/**
 * The five-layer stack from motion rule 5, as one component.
 *
 * Skipping the top layers — grade, grain, vignette — is the single most common
 * reason generated video looks digital and cheap. Making them the default
 * costs nothing per scene and removes the chance of forgetting.
 */

import React from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { colors, easing } from '../theme';
import { Grade, Grain, SafeArea, Vignette } from './primitives';

/**
 * Layer 1: a slow-drifting mesh gradient. A flat background color is the other
 * half of why AI video reads as flat — a real grade always has some gradient in
 * it, even when nobody could describe what.
 */
export const Backdrop: React.FC<{
  from?: string;
  to?: string;
  /** Seconds for one full drift cycle. Long on purpose: motion you notice is too fast. */
  periodSeconds?: number;
}> = ({ from = colors.accent, to = colors.accentAlt, periodSeconds = 14 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = (frame / (fps * periodSeconds)) * Math.PI * 2;
  const x1 = 30 + Math.sin(t) * 18;
  const y1 = 25 + Math.cos(t * 0.8) * 15;
  const x2 = 70 + Math.cos(t * 0.6) * 20;
  const y2 = 75 + Math.sin(t * 0.7) * 12;

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      <AbsoluteFill
        style={{
          background:
            `radial-gradient(60% 55% at ${x1}% ${y1}%, ${from}55 0%, transparent 70%),` +
            `radial-gradient(55% 50% at ${x2}% ${y2}%, ${to}44 0%, transparent 70%)`,
        }}
      />
    </AbsoluteFill>
  );
};

/**
 * Wrap every scene in this.
 *
 *   <Scene media={<MediaPlate src="hero.jpg" />}>
 *     <HeroTitle>Ba giây đầu quyết định</HeroTitle>
 *   </Scene>
 *
 * `children` land inside the safe area with the grade already beneath them and
 * the grain already above — the layer order the rules ask for, without a scene
 * file having to restate it.
 */
export const Scene: React.FC<{
  children?: React.ReactNode;
  /** Footage or stills for layer 2. Omit for a pure motion-graphics scene. */
  media?: React.ReactNode;
  backdrop?: React.ReactNode;
  grain?: boolean;
  vignette?: boolean;
  grade?: boolean;
  /** Turn off when the scene positions its own content absolutely. */
  safe?: boolean;
  style?: React.CSSProperties;
}> = ({
  children,
  media,
  backdrop,
  grain = true,
  vignette = true,
  grade = true,
  safe = true,
  style,
}) => (
  <AbsoluteFill style={style}>
    {backdrop ?? <Backdrop />}
    {media}
    {grade ? <Grade /> : null}
    {safe ? <SafeArea>{children}</SafeArea> : children}
    {vignette ? <Vignette /> : null}
    {grain ? <Grain /> : null}
  </AbsoluteFill>
);

/**
 * A scene-to-scene wipe that is not a crossfade. Place it at the *start* of the
 * incoming scene; it covers the cut for a few frames and leaves.
 *
 * Crossfades between motion-graphics scenes almost always look like a mistake,
 * because both scenes are still animating underneath each other.
 */
export const WipeIn: React.FC<{ color?: string; frames?: number }> = ({
  color = colors.bg,
  frames,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const len = frames ?? Math.round(fps * 0.5);
  const y = interpolate(frame, [0, len], [0, -110], {
    easing: easing.outExpo,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  if (frame > len) return null;
  return (
    <AbsoluteFill
      style={{ backgroundColor: color, transform: `translateY(${y}%)`, zIndex: 50 }}
    />
  );
};
