# Extracting frames from a video

Two entirely different jobs share this name.

## QA — looking at your own render

```bash
scripts/inspect_frames.sh "$JOB/out/promo_1080x1920_v1.mp4" "$JOB/frames"
```

One frame per second, first and last, plus a contact sheet. This is the non-negotiable step before delivery: extract frames, *look at them*, fix what is wrong, re-render. See `qa-and-delivery.md`.

Clear `frames/` between renders. Inspecting a stale frame from the previous version and declaring the video fixed is an easy mistake with a confident wrong conclusion.

## Studying a reference clip

When the user drops a competitor video in `input/`:

```bash
scripts/inspect_frames.sh "$JOB/input/reference.mp4" "$JOB/frames/ref"
```

Count the cuts in the first five seconds. That number is the pacing they are asking for without being able to say so.

## A poster frame

```bash
ffmpeg -v error -ss 2.5 -i input.mp4 -frames:v 1 -update 1 poster.png
```

`-ss` before `-i` seeks quickly and approximately; after `-i` it is exact and slow. For a thumbnail the fast form is fine.

## Inside a composition

To show a still from a video as an image, do not extract it — put an `<OffthreadVideo>` in a one-frame `<Sequence>`, or use `<Still>` and render that composition as a PNG. Extracting to disk and re-importing adds a file to manage for no benefit.
