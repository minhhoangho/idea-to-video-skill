# Charts and data visualisation

Chart libraries built for the web assume hover, tooltips and their own animation loop. In a video there is no hover, and their animation will not render. Draw the SVG yourself and animate it from `useCurrentFrame()`.

## A bar that grows

```tsx
const grow = spring({ frame: frame - i * 4, fps, config: springs.soft });
<rect x={x} y={base - h * grow} width={w} height={h * grow} fill={series[i % series.length]} />
```

Stagger the bars (rule 3). Bars arriving together is a chart; bars arriving in sequence is an argument.

## A line that draws itself

```tsx
const len = pathRef.current?.getTotalLength() ?? 0;
<path d={d} strokeDasharray={len} strokeDashoffset={len * (1 - progress)} fill="none" />
```

`getTotalLength` needs a measured node — see `measuring-dom-nodes.md`, and block the render until it is available or the first frames show nothing.

## Rules specific to video

- **Label directly, never with a legend.** The viewer cannot look back and forth; put the series name at the end of its own line or bar.
- **Animate one dimension.** Bars grow in height *or* fade in, not both plus a slide.
- **Hold the finished state.** A chart that finishes animating at the moment of the cut was never actually read. Give it at least a second of stillness.
- **Colour carries meaning.** `series` in `theme.ts` is ordered so the first three stay distinguishable to the most common forms of colour blindness.
- **Round the numbers.** `1,284,391` is noise at 1/24th of a second; `1.28M` is a fact.

`StatCounter` in the component library covers the single-number case, which is most of what short-form actually needs.
