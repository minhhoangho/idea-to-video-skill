/**
 * The things that actually carry meaning on screen: titles, lists, numbers,
 * comparisons, captions.
 *
 * All of them read their sizes from `layout(useVideoConfig())`, so the same
 * scene re-cuts from 9:16 to 1:1 to 16:9 without a second set of numbers.
 */

import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { colors, easing, font, layout, series, springs } from '../theme';
import { Reveal, Stagger } from './primitives';

/** The opening statement. One idea, large, nothing else competing with it. */
export const HeroTitle: React.FC<{
  children: React.ReactNode;
  at?: number;
  align?: 'left' | 'center';
  color?: string;
}> = ({ children, at = 0, align = 'left', color = colors.text }) => {
  const L = layout(useVideoConfig());
  return (
    <Reveal at={at} distance={56} preset="soft">
      <div
        style={{
          fontFamily: font.family,
          fontSize: L.type.hero,
          fontWeight: font.headline.weight,
          lineHeight: font.headline.lineHeight,
          letterSpacing: font.headline.letterSpacing,
          textAlign: align,
          color,
        }}
      >
        {children}
      </div>
    </Reveal>
  );
};

/**
 * Kinetic typography: lines arriving one after another.
 *
 * The staggered arrival is what makes text feel spoken rather than pasted —
 * rule 3 applied to the one element every video has.
 */
export const KineticLines: React.FC<{
  lines: string[];
  at?: number;
  step?: number;
  /** Highlight colour for words wrapped in *asterisks*. */
  accent?: string;
}> = ({ lines, at = 0, step, accent = colors.accent }) => {
  const L = layout(useVideoConfig());
  return (
    <Stagger at={at} step={step} distance={34}>
      {lines.map((line, i) => (
        <div
          key={i}
          style={{
            fontFamily: font.family,
            fontSize: L.type.headline,
            fontWeight: font.headline.weight,
            lineHeight: 1.12,
            letterSpacing: font.headline.letterSpacing,
            color: colors.text,
            marginBottom: L.space.xs,
          }}
        >
          {line.split(/(\*[^*]+\*)/g).map((part, j) =>
            part.startsWith('*') && part.endsWith('*') ? (
              <span key={j} style={{ color: accent }}>
                {part.slice(1, -1)}
              </span>
            ) : (
              part
            ),
          )}
        </div>
      ))}
    </Stagger>
  );
};

/**
 * A number that counts up. The most reliable attention device in short-form,
 * and the one most often ruined by linear interpolation — hence the easing.
 */
export const StatCounter: React.FC<{
  to: number;
  from?: number;
  at?: number;
  /** Frames the count takes. Defaults to ~1.2s. */
  frames?: number;
  prefix?: string;
  suffix?: string;
  decimals?: number;
  label?: string;
}> = ({ to, from = 0, at = 0, frames, prefix = '', suffix = '', decimals = 0, label }) => {
  const frame = useCurrentFrame();
  const config = useVideoConfig();
  const L = layout(config);
  const len = frames ?? Math.round(config.fps * 1.2);
  const value = interpolate(frame - at, [0, len], [from, to], {
    easing: easing.outExpo,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <Reveal at={at} preset="soft" distance={28}>
      <div style={{ fontFamily: font.family, color: colors.text }}>
        <div
          style={{
            fontSize: L.type.hero,
            fontWeight: font.headline.weight,
            lineHeight: 1,
            // Tabular figures stop the number jittering sideways as digits change.
            fontVariantNumeric: 'tabular-nums',
          }}
        >
          {prefix}
          {value.toFixed(decimals)}
          {suffix}
        </div>
        {label ? (
          <div style={{ fontSize: L.type.body, color: colors.textMuted, marginTop: L.space.xs }}>
            {label}
          </div>
        ) : null}
      </div>
    </Reveal>
  );
};

/** A list where each row lands on its own beat. */
export const BulletList: React.FC<{
  items: React.ReactNode[];
  at?: number;
  step?: number;
  marker?: 'dot' | 'number' | 'none';
}> = ({ items, at = 0, step, marker = 'dot' }) => {
  const L = layout(useVideoConfig());
  return (
    <Stagger at={at} step={step} distance={26}>
      {items.map((item, i) => (
        <div
          key={i}
          style={{
            display: 'flex',
            alignItems: 'baseline',
            gap: L.space.sm,
            marginBottom: L.space.sm,
            fontFamily: font.family,
            fontSize: L.type.body,
            lineHeight: font.body.lineHeight,
            color: colors.text,
          }}
        >
          {marker === 'none' ? null : (
            <span
              style={{
                color: colors.accent,
                fontWeight: 800,
                minWidth: marker === 'number' ? L.space.md : undefined,
              }}
            >
              {marker === 'number' ? `${i + 1}.` : '•'}
            </span>
          )}
          <span>{item}</span>
        </div>
      ))}
    </Stagger>
  );
};

/** Numbered steps with a connecting rule — for "how it works" beats. */
export const ProcessSteps: React.FC<{
  steps: { title: string; detail?: string }[];
  at?: number;
  step?: number;
}> = ({ steps, at = 0, step }) => {
  const L = layout(useVideoConfig());
  return (
    <Stagger at={at} step={step} distance={30}>
      {steps.map((s, i) => (
        <div key={i} style={{ display: 'flex', gap: L.space.md, marginBottom: L.space.md }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div
              style={{
                width: L.space.lg,
                height: L.space.lg,
                borderRadius: 9999,
                background: series[i % series.length],
                color: colors.bg,
                fontFamily: font.family,
                fontWeight: 800,
                fontSize: L.type.body * 0.8,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              {i + 1}
            </div>
            {i < steps.length - 1 ? (
              <div style={{ flex: 1, width: 2, background: colors.textMuted, opacity: 0.3 }} />
            ) : null}
          </div>
          <div style={{ fontFamily: font.family, paddingBottom: L.space.sm }}>
            <div style={{ fontSize: L.type.body, fontWeight: 700, color: colors.text }}>
              {s.title}
            </div>
            {s.detail ? (
              <div style={{ fontSize: L.type.body * 0.82, color: colors.textMuted }}>
                {s.detail}
              </div>
            ) : null}
          </div>
        </div>
      ))}
    </Stagger>
  );
};

/** Before/after, us/them, old/new. Two panels, the second arriving late. */
export const ComparisonPair: React.FC<{
  left: { label: string; body: React.ReactNode };
  right: { label: string; body: React.ReactNode };
  at?: number;
  /** Extra frames before the right panel lands, so the contrast registers. */
  beat?: number;
}> = ({ left, right, at = 0, beat }) => {
  const config = useVideoConfig();
  const L = layout(config);
  const gap = beat ?? Math.round(config.fps * 0.45);

  const panel = (side: { label: string; body: React.ReactNode }, accent: string) => (
    <div
      style={{
        flex: 1,
        background: colors.bgElevated,
        borderTop: `4px solid ${accent}`,
        borderRadius: L.radius.md,
        padding: L.space.md,
        fontFamily: font.family,
      }}
    >
      <div
        style={{
          fontSize: L.type.body * 0.75,
          textTransform: 'uppercase',
          letterSpacing: '0.08em',
          color: accent,
          fontWeight: 700,
          marginBottom: L.space.xs,
        }}
      >
        {side.label}
      </div>
      <div style={{ fontSize: L.type.body, color: colors.text, lineHeight: font.body.lineHeight }}>
        {side.body}
      </div>
    </div>
  );

  return (
    <div style={{ display: 'flex', gap: L.space.sm, width: '100%' }}>
      <Reveal at={at} distance={30}>
        {panel(left, colors.textMuted)}
      </Reveal>
      <Reveal at={at + gap} distance={30}>
        {panel(right, colors.accent)}
      </Reveal>
    </div>
  );
};

/**
 * Burned-in captions sized for a phone.
 *
 * The plate matters more than the font: over unpredictable footage a drop
 * shadow disappears and a stroke alone thins out at small sizes.
 */
export const Caption: React.FC<{
  children: React.ReactNode;
  at?: number;
  plate?: boolean;
}> = ({ children, at = 0, plate = true }) => {
  const frame = useCurrentFrame();
  const config = useVideoConfig();
  const L = layout(config);
  const enter = spring({ frame: frame - at, fps: config.fps, config: springs.snappy });

  return (
    <div
      style={{
        position: 'absolute',
        left: L.safe.side,
        right: L.safe.side,
        bottom: L.safe.bottom,
        display: 'flex',
        justifyContent: 'center',
        opacity: enter,
        transform: `translateY(${(1 - enter) * 18}px)`,
      }}
    >
      <div
        style={{
          fontFamily: font.family,
          fontSize: L.type.caption,
          fontWeight: 800,
          lineHeight: 1.15,
          letterSpacing: '-0.01em',
          textAlign: 'center',
          color: colors.text,
          padding: plate ? `${L.space.xs}px ${L.space.sm}px` : 0,
          borderRadius: plate ? L.radius.sm : 0,
          background: plate ? 'rgba(0,0,0,0.72)' : 'transparent',
          textShadow: plate ? 'none' : '0 2px 8px rgba(0,0,0,0.9)',
          maxWidth: '92%',
        }}
      >
        {children}
      </div>
    </div>
  );
};
