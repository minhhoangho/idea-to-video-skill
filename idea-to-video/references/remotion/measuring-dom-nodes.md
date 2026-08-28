# Measuring DOM nodes

Sometimes you need a real measurement: the height of a paragraph after wrapping, the width of a rendered list.

```tsx
const ref = useRef<HTMLDivElement>(null);
const [size, setSize] = useState<DOMRect | null>(null);

useLayoutEffect(() => {
  if (ref.current) setSize(ref.current.getBoundingClientRect());
}, []);
```

`useLayoutEffect` rather than `useEffect` — it runs before paint, so the measured value is used on the same frame instead of one frame late.

## The render-time catch

Every frame is rendered in a fresh browser context, so the effect runs again for each. The value must therefore be *deterministic*: the same input must produce the same measurement on every frame. If it does not — because a font had not loaded, or an image had not decoded — you get a layout that jitters between frames.

Block on the dependency instead of measuring around it:

```tsx
const handle = delayRender('measuring');
// after fonts.ready and images decoded:
continueRender(handle);
```

## Prefer not to

CSS flexbox and `%` units solve most of what measurement is used for, and they cost nothing. Measure when you need a value in JavaScript — to animate a line that grows to the width of the text above it, for instance — not to centre something.
