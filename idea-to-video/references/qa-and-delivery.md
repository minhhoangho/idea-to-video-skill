# QA and delivery

## Why this phase exists

A render that completes tells you the code ran. It tells you nothing about whether text is cropped, whether a scene is black, whether the subtitle sits under the TikTok UI, or whether the logo is off-centre. Those failures are invisible from the terminal and obvious from a single frame. So look at frames — always, including on "small" changes.

## The loop

```
render → extract frames → inspect → fix → re-render
```

Repeat until the checklist below passes. Two iterations is normal. If you are on the fourth, the problem is in the brief, not the code — go back and re-propose.

## Extracting frames

`scripts/inspect_frames.sh <video> <outdir>` pulls a frame every second plus the first and last, and clears the output directory first. Run it against the job's own folders:

```bash
scripts/inspect_frames.sh "$JOB/out/<slug>_1080x1920_v2.mp4" "$JOB/frames"
```

For targeted checks:

```bash
ffmpeg -ss 00:00:02 -i "$VIDEO" -frames:v 1 "$JOB/frames/hook.png"
ffmpeg -i "$VIDEO" -vf fps=1 "$JOB/frames/f_%03d.png"
ffmpeg -i "$VIDEO" -vf "fps=1,scale=320:-1,tile=5x4" "$JOB/frames/sheet.png"
```

**Clear `frames/` between renders.** Inspecting a leftover frame from the previous version produces a confident, wrong verdict — and it is an easy mistake to make, because a stale frame looks exactly like a fresh one.

Always inspect at minimum: the hook frame (≈1s), one frame inside each beat, every transition boundary, and the final frame.

## Checklist

**Frame**
- No text within 10% of any edge; nothing within the bottom 15% on vertical
- Nothing cropped by the aspect ratio, including logo corners
- No black or near-empty frames except intentional ones
- Contrast readable at phone size — squint test, or downscale to 320px wide and re-check

**Motion**
- No element moves at constant speed
- Siblings do not arrive on the same frame
- Every element that entered also exits
- Stills have visible Ken Burns drift
- Nothing sits perfectly frozen for more than ~2s

**Text**
- Spelling of every on-screen word matches the text sheet exactly — check names and brand casing character by character
- Captions never overlap each other or the CTA
- Line breaks fall at sensible points, not mid-phrase

**Audio**
- Narration is not clipped at either end
- Music ducks under narration and does not return abruptly
- Video ends on a resolved note, not mid-phrase
- Total duration matches the brief within ±1s

**Output**
- Correct dimensions and fps
- File size sane for the platform (under ~50MB for a 60s vertical)
- Plays from the first frame with no leading black

## Delivery format

Keep it short. The user wants the file, not a report.

```
Video is ready.
File: /abs/path/video-projects/2026-08-27-barbershop-promo/out/barbershop-promo_1080x1920_v2.mp4
Specs: 20s · 1080×1920 · 30fps · subtitles, background music
Content: question hook → three features → app-download CTA

Three things worth upgrading:
1. …
2. …
3. …
```

Present the file with whatever file-delivery tool the surface provides; a path alone is unreachable on mobile.

Then close the loop on the workspace: update the job's row in `video-projects/INDEX.md` with the shipped version and status, and append an entry to the job's `NOTES.md` saying what changed in this version and why. Two lines of bookkeeping that make the next request cheap.

## Revision requests

When the user asks for a change, first say what it touches: a text change is a re-render, a pacing change re-times every downstream beat, an aspect-ratio change may need re-composed layouts. Then make the change, re-run the QA loop on the affected frames only, and deliver. Do not re-open the brief for a one-line edit.
