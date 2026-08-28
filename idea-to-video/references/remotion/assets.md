# Assets — getting files into a composition

Two ways in, and the choice has consequences.

## staticFile — the default

Anything in the project's `public/` folder:

```
project/public/
├── audio/01-hook.mp3
├── images/logo.svg
└── fonts/Inter-Black.woff2
```

```tsx
<Img src={staticFile('images/logo.svg')} />
```

The path is relative to `public/`, with no leading slash and no `public/` prefix. Files are served as-is, are not bundled, and are not processed — which is what you want for media.

## import — for small things

```tsx
import logo from './logo.svg';
```

Goes through the bundler, so it is hashed and inlined if small. Fine for an icon; wrong for a 40 MB video, which would be embedded in the bundle.

## The rule for this skill

Media lives in `public/`, referenced with `staticFile()`. Files the user supplied get **copied** from the job's `input/` into `public/images/` — never referenced from `input/` directly. `input/` is the user's folder and read-only, and a composition that reaches outside its own `public/` breaks the moment the job folder moves.

## Common failures

| Symptom | Cause |
|---|---|
| 404 in the Studio | Leading slash, or `public/` included in the path |
| Works in Studio, fails in render | Absolute filesystem path instead of `staticFile()` |
| Render hangs at 0% | Asset fetched from the network at render time |
| Bundle enormous, slow to start | A video `import`ed instead of placed in `public/` |
