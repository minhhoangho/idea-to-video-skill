# Track B — Narrated video (script → voice → composition)

Use this track when meaning is carried by a *voice*: faceless storytelling, top-N lists, news recaps, explainers, motivational content, long-form repurposed to short. The video is built in Remotion exactly as Track A is; what makes it Track B is that **the narration audio is generated first and everything else is timed to it**.

Requires Node.js 18+, ffmpeg, and the workspace `./.venv`. **No API keys.** The script is written by you in the conversation, the voice comes from `edge-tts`, and the timing comes from `ffprobe`. Nothing here calls a paid service or needs a credential.

## The pipeline

```
you write script.md              ← in the conversation, no API call
        ↓  scripts/narrate.sh <job> --voice <name>
edge-tts  →  project/public/audio/01-hook.mp3 …
        ↓  ffprobe measures each file
project/src/audioConfig.ts   { id, file, durationInSeconds, frames, from, text, words }
        ↓  scripts/scaffold_remotion.sh --narrated  (Root/Main already wired)
Remotion <Sequence from={s.from} durationInFrames={s.frames}>
        ↓  scripts/render.sh <job>
MP4 with word-synced captions, -14 LUFS, QA report
```

The direction of that arrow is the whole trick. **Audio decides scene length.** Write a composition with hardcoded durations and you get scenes that cut while the voice is mid-sentence, or hold three seconds of silence at the end — the two failures that make narrated video feel amateur, and the two that are impossible once timing is derived.

## Before running

The script *is* the video on this track. Get it right before spending render time.

Write the narration from the brief, show it to the user, and only proceed once they approve — unless they said "you pick", in which case the script is yours to approve: run on it, and include it in the delivery so they can still change it. Read it aloud in your head against the target duration:

| Language | Speaking rate | 60s of video |
|---|---|---|
| Vietnamese | 3.5–4 words/s | ~220 words |
| English | 2.5–3 words/s | ~170 words |
| Chinese | 4–5 chars/s | ~270 characters |

These are speaking rates, not reading rates. A script that looks short on the page usually runs long.

## script.md

One `##` heading per scene. The heading is the scene id — it becomes the audio filename and the key you look up in the composition. Everything under it is spoken verbatim.

```markdown
# adidas-promo — narration script

<!-- Comments are stripped. So are > blockquote notes and --- rules,
     so you can annotate freely without it ending up in the voice-over. -->

## 01-hook
Ba giây đầu quyết định người xem ở lại hay lướt qua.

## 02-problem
Hầu hết video quảng cáo mở đầu bằng logo.
Đó là lý do không ai xem hết.

## 03-cta
Tải ứng dụng ngay hôm nay.
```

Line breaks inside a scene are joined into one utterance — write for readability, not for the synthesiser. Ids are normalised to lowercase kebab-case, so `## 01 Hook` and `## 01-hook` produce the same file.

Check what will actually be spoken before generating anything:

```bash
scripts/narrate.sh <job> --dry-run
```

It costs nothing and catches the embarrassing failure — an editorial note read aloud in the finished video.

## Generating the voice

```bash
scripts/narrate.sh --voices vi                       # what voices exist for a language
scripts/narrate.sh <job> --voice vi-VN-NamMinhNeural
scripts/narrate.sh <job> --voice en-US-AndrewNeural --rate +8% --fps 30
```

**Always pass `--voice` explicitly.** The default is US English; a Vietnamese script read by an English voice is not a subtle error but it is an easy one to ship. Take the language from the brief, list the voices for it, and pick one — then record which voice you used in the brief, because a re-render months later has to match.

`--rate` shifts pace (`+8%` is a useful nudge when a script runs slightly long; past `+15%` it starts to sound rushed). `--pad-frames` (default 6) adds tail silence so a scene never cuts on the last consonant.

The script bootstraps `./.venv` on first run and retries transient upstream failures — `NoAudioReceived` is intermittent and means nothing on its own. If it fails three times in a row, the error printed is the real one.

Rerun `narrate.sh` after *every* change to `script.md`. It is cheap, and a stale `audioConfig.ts` is the single most confusing state this track can be in: the audio says one thing, the timing describes another.

## Wiring it into the composition

```bash
scripts/scaffold_remotion.sh --narrated <slug> 1080 1920 30 "$JOB/project"
```

That writes a `Root.tsx` whose length and fps come from `audioConfig.ts` — never a literal — and a `Main.tsx` that maps over `SCENES`, giving each scene its own `<Sequence>` and `<Audio>` so the voice and the visuals cannot drift apart. It runs before or after `narrate.sh`; until narration exists, a placeholder config keeps the project compiling and the render fails with "no narration yet".

Your part is `src/scenes/index.tsx` (rename it from `.ts` once it holds JSX): one component per `## <id>` heading, keyed by the normalised id `narrate.sh` printed.

```tsx
export const SCENE_COMPONENTS: Record<string, React.FC<{ scene: NarrationScene }>> = {
  '01-hook': Hook,
  '02-problem': Problem,
};
```

Inside a scene component, animate against the scene's own `frames`, not the composition's total. `useCurrentFrame()` inside a `<Sequence>` is already relative to that sequence's start, which is what makes this pattern hold together when a script edit shifts every later scene.

A scene id with no component fails the render with its name, rather than playing the voice over a blank sequence — which would read as a render bug, not a missing file.

## Captions — word-synced, no transcription

`narrate.sh` asks the TTS for word boundaries while it speaks, so every scene in `audioConfig.ts` carries `words: { text, startMs, endMs }[]` — exact timings, not an estimate. Put them on screen with:

```tsx
<Scene>
  …
  <WordCaptions words={scene.words} />
</Scene>
```

Three words a page, the spoken word in the accent colour, the last page leaving just before the cut. `perPage` raises the count on 16:9, where a line holds more. `scene.text` is the exact sentence spoken, for anything that needs the full line.

No `whisper`, no API key, no drift. Caption styling rules that survive mobile are in `remotion/captions.md`.

## Visuals

Two sources, in order of preference:

1. **What the user supplied.** Footage and photos in the job's `input/` are specific to them in a way stock never is. `scan_input.sh` tells you what is usable at the target resolution; `input-analysis.md` covers the rest.
2. **Motion graphics.** With nothing supplied, build the visuals — type, shape, gradient, data. This is Track A's craft applied under a voice, and `track-remotion.md` plus the ten motion rules still govern.

There is no stock-footage fetch on this track, deliberately: it required an API key, and generic b-roll was always the weakest part of the output. If the user genuinely wants stock, ask them to drop clips into `input/` — they choose better shots than a keyword search does.

## Music

Place a track in `public/audio/` and add it to `Main.tsx` at the composition root — outside the scene `<Sequence>`s, so it plays continuously — ducked under the narration with the helper in `src/narration.ts`:

```tsx
import { musicVolume } from './narration';

<Audio src={staticFile('audio/music.mp3')} volume={(f) => musicVolume(f)} />
```

Music at a constant level under speech is the most common audio mistake on this track. `musicVolume` sits at roughly a third under the voice and ramps back up where there is none; `{ under, full, rampSeconds }` tune it. `render.sh` then normalises the whole mix to -14 LUFS, so set the balance here and leave the absolute level to it.

## Common failures

| Symptom | Cause |
|---|---|
| Scene cuts mid-sentence | Composition uses a hardcoded duration instead of `scene.frames` |
| Silence at the end of a scene | `script.md` edited without rerunning `narrate.sh` — stale `audioConfig.ts` |
| Wrong language voice | `--voice` omitted, so the US English default was used |
| An editorial note is spoken | Written as plain text instead of a comment or blockquote; `--dry-run` would have caught it |
| `NoAudioReceived` | Transient upstream failure. The script retries three times; if it persists, rerun later |
| `WSServerHandshakeError: 403` | Not transient: an old edge-tts the service no longer accepts. The script upgrades it once and retries; by hand, `.venv/bin/python -m pip install -U edge-tts` |
| "no component for scene 'x'" | `SCENE_COMPONENTS` has no entry for that id — use the normalised id `narrate.sh` printed |
| "no narration yet" | `audioConfig.ts` is still the scaffold placeholder — run `narrate.sh` |
| Captions wrap to two lines | `perPage` too high for the frame width; 3 suits 9:16 |
