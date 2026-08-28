# Captions

Burned-in captions are not optional in short-form: most viewers watch muted. Style them for a phone held at arm's length, not for a desktop preview.

## Style rules that survive contact

- **5–7% of composition height** for font size on vertical. Smaller is unreadable; larger wraps constantly.
- **Heavy weight, tight tracking.** 700–900. Regular weight disappears over busy footage.
- **A dark plate or a thick stroke — not a drop shadow alone.** A shadow vanishes over dark footage, and footage brightness is unpredictable.
- **Lower third, above the platform UI.** The bottom 15% on TikTok and Reels carries the caption text, the share buttons and the progress bar. `SafeArea` in the component library already accounts for this.
- **One line at a time on vertical, two at most.** Three lines is a paragraph, and nobody reads a paragraph in 2 seconds.

The `Caption` component implements all of this. Reach for it before writing your own.

## Timing them

On the narrated track you already have the text and the per-scene frame counts, so no transcription is needed. Split each scene's line at clause boundaries and distribute the scene's frames by chunk length:

```tsx
const chunks = text.split(/(?<=[.!?,])\s+/);
const total = chunks.reduce((n, c) => n + c.length, 0);
// chunk i gets frames * chunks[i].length / total
```

Weight by character count, not by chunk count — otherwise "Yes." holds as long as a twelve-word clause and the captions drift visibly late.

## Word-level highlighting

The karaoke effect needs real per-word timestamps, which clause-weighting cannot fake. See `transcribe-captions.md` — it runs locally, with no API key.

## @remotion/captions

```bash
npm i @remotion/captions
```

`createTikTokStyleCaptions({ captions, combineTokensWithinMilliseconds: 1200 })` groups word-level tokens into pages. Useful once you have timestamps; unnecessary when you are laying out clause chunks yourself.
