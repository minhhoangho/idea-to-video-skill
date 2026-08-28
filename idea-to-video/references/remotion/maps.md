# Maps

**This is the one topic in the skill that involves an API key**, and it is therefore the one to avoid. Mapbox and Google Maps both require a token, and tokens end up committed, rate-limited, or billed.

## Prefer static geometry

For almost every video, a map is a shape, not a service. Draw it from GeoJSON:

```tsx
import { geoMercator, geoPath } from 'd3-geo';

const projection = geoMercator().fitSize([width, height], geojson);
const path = geoPath(projection);
<path d={path(feature) ?? ''} fill={colors.bgElevated} stroke={colors.accent} />
```

Public-domain country and region outlines are widely available as GeoJSON. The result is deterministic, offline, renders fast, and looks like design rather than like a screenshot of a map.

Animate a route with the `strokeDasharray` technique from `charts.md`; animate a zoom by interpolating the projection's `scale` and `center`.

## If a real basemap is genuinely required

Tell the user it needs their Mapbox token before you build anything around it, and be explicit that this is the only part of the skill that does. Then keep the token in an environment variable, never in a committed file, and never echo it into the conversation.

Pre-render tiles to images and load them with `<Img>` rather than fetching at render time — a per-frame network call to a tile server is both slow and a good way to get rate-limited mid-render.

## The honest recommendation

A stylised vector map almost always looks better in a promo than a real basemap, which brings road labels and points of interest nobody asked for. Reach for tiles only when the specific streets matter.
