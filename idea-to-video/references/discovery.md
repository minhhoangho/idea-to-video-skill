# Discovery — asking well, once

## The principle

Every question you ask costs the user attention, and costs you trust if it turns out they already answered it. So the question set is not fixed: it is the *gap* between what a shootable brief needs and what the user's sentence already gave you.

A shootable brief needs nine slots filled. Most one-line ideas fill three or four. Ask about the empty ones, capped at six questions, and give every one a default so the user can decline to decide.

## The nine slots

| # | Slot | Default when unstated |
|---|---|---|
| 1 | Duration | 30s (brand/promo 15s, explainer 60s, faceless 60–90s) |
| 2 | Aspect ratio | 9:16 vertical |
| 3 | Language of the video | Same as the conversation language |
| 4 | Audience | General consumer, mobile, low attention |
| 5 | Goal / CTA | Awareness, soft CTA in the last 2s |
| 6 | Tone | Confident, modern, not corporate |
| 7 | Narration | Yes for faceless & explainer, no for brand/promo |
| 8 | Assets on hand | None — synthesize with stock or pure motion graphics |
| 9 | Brand constraints | None — propose a palette |

Slots 1–3 are cheap to confirm and expensive to get wrong; confirm them even when you think you inferred them. Slots 4–9 only get asked when they will actually change the output.

## Question bank by request shape

Pick from these; do not use all of them.

### Brand / promo

- Do you have a logo, brand colors, or a specific typeface? *(default: I'll propose a palette and type pairing)*
- Which words have to appear verbatim — product name, tagline, price? *(default: name plus tagline only)*
- How does it end: website, app download, QR code, or just the brand mark? *(default: brand mark plus website)*
- Is there a product UI I should show on screen? *(default: abstract mockup)*

### Explainer / educational

- Do you have a script, or should I write one? *(default: I write it, you approve before render)*
- Audience level — complete beginner or already knows the basics? *(default: beginner)*
- How much text on screen: keywords only, or full sentences? *(default: keywords plus subtitles)*
- Any diagrams, charts, or animated numbers needed? *(default: yes, if the content has figures)*

### Faceless content

- Voice: male or female, fast or measured, which language? *(default: female, medium pace, conversation language)*
- Visual source: stock footage, images you supply, or pure motion graphics? *(default: stock)*
- Caption style: word-by-word highlight, line-by-line, or none? *(default: line-by-line, large, heavy outline)*
- Background music, and what mood? *(default: yes, neutral lo-fi, ducked under narration)*

### Repair / upgrade

Here the question is diagnostic, not preferential. Ask for the artifact first, then exactly one question:

- Send me the file or the source. What specifically feels wrong — the pacing, the movement, the color, the type, or the sound?

Then read `creative-direction.md` §"Diagnosing flat video" before proposing fixes. Most "it looks generic" complaints reduce to: linear easing, everything entering at once, flat background, no exit animations.

## Format of the clarification message

Three parts, nothing more:

1. One line summarizing what you already understood from their idea — this proves you read it and pre-empts the "I just told you that" reaction.
2. The numbered questions with defaults in parentheses.
3. The escape hatch: "you pick" runs everything on defaults, with reasons explained afterwards.

**Example**

> Got it — vertical promo for a barbershop booking app, young and energetic. Four things to lock down:
>
> 1. Duration: 15s or 30s? *(default: 20s — enough for three features)*
> 2. Do you have a logo and hex codes? *(default: I propose a palette)*
> 3. End on an app-store button or a website? *(default: "Download on the App Store & Google Play")*
> 4. Do you want a voice-over? *(default: no — music and type only)*
>
> If you'd rather move fast, say "you pick" and I'll run the defaults and explain each choice after.

## Anti-patterns

- Five questions spread across five messages. One message.
- Asking a question whose answer cannot change what you build. If both answers lead to the same render, drop it.
- Offering a "custom" option with no default. The whole point of the default is that the user can skip.
- Asking about implementation ("Remotion or stock footage?"). That is your decision to propose in Phase 3, not their burden in Phase 2 — unless they raised the tool themselves.
