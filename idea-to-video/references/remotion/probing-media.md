# Probing media files

Two ways to learn a file's duration, dimensions or codec. Pick by *when* you need to know.

## Before the render — ffprobe

```bash
ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 clip.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 clip.mp4
```

This is what `scripts/scan_input.sh` and `scripts/narrate.sh` use. The answer lands in a file you can read — `audioConfig.ts`, or the scan table — which makes the composition simpler and the numbers reviewable.

**Prefer this.** A duration you can see in a file beats one computed invisibly at render time.

## During the render — parseMedia

```tsx
import { parseMedia } from '@remotion/media-parser';

const { slowDurationInSeconds, dimensions } = await parseMedia({
  src: staticFile('clip.mp4'),
  fields: { slowDurationInSeconds: true, dimensions: true },
  acknowledgeRemotionLicense: true,
});
```

Use inside `calculateMetadata` when the file arrives as a prop and cannot be probed in advance — the batch-generation case. Request only the fields you need; `slowDurationInSeconds` reads the whole file and is named that way as a warning.

## In the browser — mediabunny

For a `<Player>` embedded in a web app, where there is no shell and no build step, `mediabunny` reads duration, dimensions and decodability client-side. Irrelevant to a CLI render, which is what this skill does.

## Checking decodability

```tsx
import { canPlayVideo } from '@remotion/media-parser';
```

Worth doing when the user supplied the file. An HEVC clip from an iPhone or a 10-bit export will parse and then fail to decode; better to tell them early and ask for an H.264 export than to fail forty minutes into a render.

`scan_input.sh` already flags files it cannot open at all.
