/**
 * Types and helpers for the narrated track (Track B).
 *
 * The data lives in audioConfig.ts, which scripts/narrate.sh regenerates after
 * every script change. This file is the stable half: scaffold_remotion.sh
 * --narrated copies it into src/, and narrate.sh does too if it runs first.
 */

import { FPS, SCENES } from './audioConfig';

export type NarrationWord = {
  text: string;
  /** Milliseconds from the start of the scene's own audio. */
  startMs: number;
  endMs: number;
};

export type NarrationScene = {
  /** Scene id, from the script.md heading. */
  id: string;
  /** Path for staticFile(), relative to public/. */
  file: string;
  durationInSeconds: number;
  /** Audio length rounded up, plus tail padding. */
  frames: number;
  /** Cumulative offset — pass straight to <Sequence from={}>. */
  from: number;
  /** Exactly what was spoken. Captions come from here, not from a transcript. */
  text: string;
  /** Per-word timing as the TTS reported it. Feed to <WordCaptions>. */
  words: NarrationWord[];
};

export const sceneById = (id: string): NarrationScene => {
  const found = SCENES.find((s) => s.id === id);
  if (!found) throw new Error(`no narration scene '${id}' — rerun narrate.sh`);
  return found;
};

/**
 * Music volume at a composition frame: ducked under the voice, up where there
 * is none. Use it on an <Audio> placed at the composition root, not inside a
 * scene's <Sequence>, so the frame it receives is the composition frame.
 *
 *   <Audio src={staticFile('audio/music.mp3')} volume={(f) => musicVolume(f)} />
 *
 * It ramps rather than steps. The short pad between scenes then reads as a
 * breath instead of the music lurching up and straight back down.
 */
export const musicVolume = (
  frame: number,
  { under = 0.18, full = 0.5, rampSeconds = 0.5 } = {},
): number => {
  let gap = Infinity;
  for (const s of SCENES) {
    const end = s.from + Math.ceil(s.durationInSeconds * FPS);
    gap = Math.min(gap, frame < s.from ? s.from - frame : frame > end ? frame - end : 0);
  }
  return under + (full - under) * Math.min(1, gap / (FPS * rampSeconds));
};
