# Parameterised video

Zod schemas turn a composition into a template with typed, editable inputs.

```bash
npm i zod @remotion/zod-types
```

```tsx
import { z } from 'zod';
import { zColor } from '@remotion/zod-types';

export const promoSchema = z.object({
  title: z.string(),
  price: z.number().min(0),
  accent: zColor(),
});

<Composition
  id="Promo"
  component={Promo}
  schema={promoSchema}
  defaultProps={{ title: 'Sale', price: 199, accent: '#6366F1' }}
  durationInFrames={600} fps={30} width={1080} height={1920}
/>
```

The Studio renders a form from the schema, so a non-developer can change the copy and see it immediately. `zColor()` gives a colour picker instead of a text field.

## Rendering variants

```bash
npx remotion render Promo out/a.mp4 --props='{"title":"Sale","price":199}'
npx remotion render Promo out/b.mp4 --props=./props/b.json
```

This is what makes batch generation — fifty product videos from a CSV — a loop rather than fifty projects.

## Where it earns its keep

Only when the same composition really is reused. A one-off promo does not need a schema, and adding one is friction with no payoff. The signal is the second job that is "the same video with different words".

## Sizing to the props

Props that change the duration — a longer script, more list items — need `calculateMetadata` rather than a fixed `durationInFrames`. See `calculate-metadata.md`.
