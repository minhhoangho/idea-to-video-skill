/**
 * Anything that puts a real file on screen: the user's footage, their photos,
 * their logo, a screenshot in a device frame.
 *
 * Rule 6 lives here — `<OffthreadVideo>` rather than `<Video>` in renders, and
 * no still ever sits perfectly still.
 */

import React from 'react';
import {
  AbsoluteFill,
  Img,
  OffthreadVideo,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { colors, font, layout, springs } from '../theme';
import { KenBurns } from './primitives';

/**
 * A still or a clip filling layer 2 of the scene stack.
 *
 * `src` is a path inside the project's `public/`, the same string you would
 * pass to `staticFile()`. Files copied out of the job's `input/` belong in
 * `public/images/` — never referenced from `input/` directly, which is the
 * user's folder and read-only.
 */
export const MediaPlate: React.FC<{
  src: string;
  kind?: 'auto' | 'image' | 'video';
  /** Ken Burns zoom for stills. Pass 1 to hold perfectly still (rarely right). */
  zoom?: number;
  /** Dim the media so text on top stays readable. */
  scrim?: number;
  fit?: 'cover' | 'contain';
}> = ({ src, kind = 'auto', zoom = 1.08, scrim = 0.35, fit = 'cover' }) => {
  const isVideo =
    kind === 'video' || (kind === 'auto' && /\.(mp4|mov|webm|m4v|mkv)$/i.test(src));
  const file = staticFile(src);
  const style: React.CSSProperties = { width: '100%', height: '100%', objectFit: fit };

  const inner = isVideo ? (
    // OffthreadVideo, always: <Video> flickers in renders.
    <OffthreadVideo src={file} style={style} />
  ) : (
    <KenBurns to={zoom}>
      <Img src={file} style={style} />
    </KenBurns>
  );

  return (
    <AbsoluteFill>
      {inner}
      {scrim > 0 ? (
        <AbsoluteFill style={{ background: `rgba(0,0,0,${scrim})`, pointerEvents: 'none' }} />
      ) : null}
    </AbsoluteFill>
  );
};

/**
 * A phone shell around a screenshot. The bezel is what makes a UI shot read as
 * "an app" rather than as a rectangle someone pasted in.
 */
export const DeviceFrame: React.FC<{
  src: string;
  at?: number;
  /** Fraction of the composition height the device occupies. */
  height?: number;
}> = ({ src, at = 0, height = 0.62 }) => {
  const frame = useCurrentFrame();
  const config = useVideoConfig();
  const L = layout(config);
  const enter = spring({ frame: frame - at, fps: config.fps, config: springs.soft });

  const h = config.height * height;
  const w = h * 0.49; // roughly a modern phone's aspect
  const bezel = Math.max(6, Math.round(w * 0.028));

  return (
    <div
      style={{
        width: w,
        height: h,
        borderRadius: w * 0.11,
        background: '#0B0B0F',
        padding: bezel,
        boxShadow: `0 ${L.space.sm}px ${L.space.lg}px rgba(0,0,0,0.55)`,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 48}px) scale(${0.92 + enter * 0.08})`,
      }}
    >
      <Img
        src={staticFile(src)}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          borderRadius: w * 0.085,
          display: 'block',
        }}
      />
    </div>
  );
};

/**
 * The end card: mark, wordmark, and one line of call to action.
 *
 * The mark arrives on a bouncy spring and the text follows — the order matters,
 * because a logo and its tagline landing together reads as a static image.
 */
export const LogoLockup: React.FC<{
  /** Path in public/. An SVG is the best case; it scales to any composition. */
  src?: string;
  wordmark?: string;
  cta?: string;
  at?: number;
  /** Fraction of composition width the mark occupies. Under 0.25 disappears on a phone. */
  width?: number;
}> = ({ src, wordmark, cta, at = 0, width = 0.38 }) => {
  const frame = useCurrentFrame();
  const config = useVideoConfig();
  const L = layout(config);
  const mark = spring({ frame: frame - at, fps: config.fps, config: springs.bouncy });
  const text = spring({
    frame: frame - at - Math.round(config.fps * 0.22),
    fps: config.fps,
    config: springs.snappy,
  });

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: L.space.sm,
        fontFamily: font.family,
        textAlign: 'center',
      }}
    >
      {src ? (
        <Img
          src={staticFile(src)}
          style={{
            width: config.width * width,
            opacity: mark,
            transform: `scale(${0.8 + mark * 0.2})`,
          }}
        />
      ) : null}

      {wordmark ? (
        <div
          style={{
            fontSize: L.type.headline,
            fontWeight: 800,
            letterSpacing: '-0.02em',
            color: colors.text,
            opacity: mark,
            transform: `scale(${0.9 + mark * 0.1})`,
          }}
        >
          {wordmark}
        </div>
      ) : null}

      {cta ? (
        <div
          style={{
            fontSize: L.type.body,
            color: colors.textMuted,
            opacity: text,
            transform: `translateY(${(1 - text) * 16}px)`,
          }}
        >
          {cta}
        </div>
      ) : null}
    </div>
  );
};
