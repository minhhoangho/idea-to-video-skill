# Transparent video

## Rendering with alpha

```bash
npx remotion render Main out/overlay.webm --codec=vp8 --image-format=png
npx remotion render Main out/overlay.mov --codec=prores --prores-profile=4444
```

Two requirements, and missing either gives you a black background instead of an error:

1. A codec that has an alpha channel — **VP8/VP9 in WebM, or ProRes 4444**. H.264 has none.
2. `--image-format=png`. JPEG cannot carry alpha, and it is the default.

Then make the composition itself transparent: no `backgroundColor` on the root `<AbsoluteFill>`. The `Scene` component in the library paints a backdrop by default, so pass your own transparent backdrop when rendering an overlay.

## Consuming transparent video

WebM with alpha composites correctly in `<OffthreadVideo>`. ProRes 4444 also works.

An mp4 someone describes as "transparent" is not — it will composite as black. Ask for WebM or a PNG sequence.

## When to bother

Lower thirds, logo stings and caption overlays that a human editor will drop onto their own footage. If the final output is a self-contained video, render it flat — alpha files are several times larger and every downstream tool handles them slightly differently.
