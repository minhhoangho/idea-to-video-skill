# Creative direction — proposing options that are actually different

## The principle

Three options that differ only in adjective ("energetic" / "professional" / "minimal") give the user nothing to decide with. A real option changes the *structure* of the video: what happens in the first two seconds, how many cuts there are, whether a voice carries the meaning or the typography does.

So build each direction from three levers pulled in different combinations: **hook type**, **information carrier**, and **pacing**. If two of your directions share all three, one of them is filler — cut it.

## Proposal template

```
### Direction A — "<name>"
- Hook (0–2s): <what literally happens on screen>
- Visual language: <palette, type, motion character>
- Pacing: <cuts per 10s>, structure <beat structure>
- Sound: <music character + narration yes/no>
- Trade-off: <what this buys, what it costs>
```

Then one recommendation line: *"I'd go with A — your goal is <goal>, and A puts <element> in the first two seconds, the only stretch you can count on people watching."*

## Hook formulas (first 2 seconds)

The hook is the only part of the video most viewers watch, so it deserves its own decision.

| Formula | Shape | Best for |
|---|---|---|
| **Direct question** | Full-screen question type-on, hard cut to answer | Explainer, educational |
| **Cost of the problem** | A number counting up / a mess on screen | B2B, product promo |
| **Contradiction** | Statement, beat, reversal | Faceless storytelling |
| **Motion tease** | Logo/object enters with spring overshoot before context | Brand, when the brand is known |
| **In medias res** | Start mid-action, explain after | Tutorial, demo |
| **Negative space** | Silence + one word, then everything floods in | Premium, minimal |

Avoid the "Hi everyone, today we're going to..." opener. It spends the only guaranteed attention on nothing.

## Beat structures by duration

**15s (4 beats)** — Hook 2s · Claim 5s · Proof 5s · CTA 3s
**30s (5 beats)** — Hook 2s · Problem 6s · Solution 10s · Proof 8s · CTA 4s
**60s (6 beats)** — Hook 3s · Setup 8s · Point 1 · Point 2 · Point 3 (12s each) · Close 10s
**90s+ faceless** — Hook 4s · Premise 10s · 4–6 narrative beats · Resolution 12s · CTA 6s

Each beat is one idea and at least one visual change. If a beat runs longer than 12s without a cut, a camera move, or a new element, it will feel dead — split it or add motion.

## Pacing reference

| Feel | Cuts per 10s | Where it fits |
|---|---|---|
| Contemplative | 1–2 | Luxury, documentary, meditation |
| Standard | 3–4 | Explainer, corporate, product |
| Energetic | 5–7 | Reels, promo, youth brands |
| Frantic | 8+ | Meme, hype, trailer — hard to sustain past 20s |

Match music BPM to cut rate and land cuts on the beat. A cut that misses the beat by 3 frames reads as sloppy even to viewers who cannot say why.

## Palette pairings

Pick one and commit — three colors plus two neutrals, never more.

- **Dark tech** — near-black `#0A0A0F` base, electric accent (`#6366F1` or `#00D4FF`), white text. Reads well on mobile, hides asset quality issues.
- **Warm editorial** — cream `#FAF7F2`, ink `#1A1A1A`, one warm accent `#C1440E`. Trustworthy, print-like, good for education.
- **Clinical bright** — white base, single saturated brand color, generous whitespace. Good for SaaS and data.
- **Neon night** — deep purple/blue gradient, two neon accents, glow. High energy, easy to overdo — use only if the pacing is energetic too.

## Typography

One family, two weights, three sizes. Bold or Black for headlines (they carry motion better), Regular for body. Set line-height tight on headlines (0.95–1.05) and open on body (1.4). Keep headlines under 6 words per screen on vertical.

## Sound

Sound is half the perceived production value and the first thing agents skip.

- Music sets the pacing — pick it before you time the cuts, not after.
- Duck music 8–12 dB under narration, with a 200ms fade, not a hard drop.
- Give each major transition a single whoosh or impact. Two per transition is noise.
- End on a resolved note, not a fade-out mid-phrase.
- If there is narration, silence the music for the final 0.5s after the last word so the CTA lands.

## Diagnosing flat video

When the user says an existing video looks generic, check in this order — the fix is almost always in the top three:

1. **Linear interpolation.** Everything moves at constant speed. Replace with springs or `easeOutExpo`-class bezier curves, clamped.
2. **Simultaneous entrance.** Every element arrives on the same frame. Stagger by 3–6 frames.
3. **Single-property animation.** Elements only fade. Animate 2–3 properties together — opacity + translateY + scale.
4. **No exits.** Elements pop out or just cut. Exits should exist and run roughly 60% of the entrance duration.
5. **Flat background.** A solid color with nothing happening. Add a slow-drifting gradient, subtle grain, and a vignette.
6. **Dead stills.** Static images with no Ken Burns push or drift.
7. **No idle motion.** Elements that sit still between beats look frozen. Add a slow sine-wave breathe (1–2% scale, 3–5s period).
8. **Uniform pacing.** Every beat the same length. Vary it — tension comes from contrast.
