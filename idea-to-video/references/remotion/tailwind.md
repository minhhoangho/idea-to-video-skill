# TailwindCSS

```bash
npx remotion tailwind
```

Configures the bundler for you. Then classes work as normal:

```tsx
<AbsoluteFill className="flex items-center justify-center bg-black">
```

## What does not work

**Every `animate-*` class.** They compile to CSS animations, which run on wall-clock time and do not exist during a render. `animate-pulse`, `animate-bounce`, `animate-spin` all produce a frozen frame in the output, and — worse — they *do* animate in the Studio preview, so the bug only appears in the final file.

`transition-*` classes are the same story.

All motion comes from `useCurrentFrame()`. Tailwind is for layout and static styling only.

## Whether to use it at all

Tailwind is good at flex layout and spacing, which is most of what a scene file does. But this skill's `theme.ts` puts sizes in fractions of the composition so a video can be re-cut to another aspect ratio for free, and Tailwind's scale is in fixed pixels — `text-6xl` is 60px whether the composition is 1080 or 4K wide.

Mixing the two gets you a layout that half-adapts. Prefer inline styles driven by `layout(useVideoConfig())`, and use Tailwind only if the user already has a design system in it.
