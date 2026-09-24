# Plant lab illustration

Tool: built-in imagegen. Original generated artwork; no book illustrations copied.
Asset: assets/images/plant-lab-v1.png.

The illustration is used by the Flame plant scene. Touch regions were aligned to the generated flower, left leaf, stem and exposed roots after visual inspection. Existing PDF-sourced story wording and assessment answers are retained. Source pages: 6–7. Motion is limited to 1.3 seconds and supports reduced motion.

## Generation prompt

Use case: scientific-educational, illustration-story.
Asset type: background painting for an offline children's interactive science game, ages 6–7. One polished wide 1536x1024 landscape children's picture-book illustration. NO TEXT or labels, no UI.
Scene: sunny garden, ONE very large sunflower plant centered straight-on, and a soil cutaway across the bottom. Warm tactile gouache/painterly 3D-like detail, lush rounded forms, beautiful greens, golden petals, premium storybook art NOT flat clipart.
Precise educational composition for interactive hotspots: flower head centered x50%,y22%, spanning x39–61%,y7–35%. Large brown seed center, thick golden petals, no face. One straight substantial green stem x50%,y32–68%. One broad left leaf x28–48%,y40–55%; one broad right leaf x52–73%,y47–62%, naturally attached to stem. Soil line at y68% with thin grass edge. Clearly visible branching cream roots from stem x50%,y68% down to y94%, spanning x34–65%, ALL BELOW GROUND. Warm dark chocolate soil cross-section with small pebbles, no pot.
Background: softly painted distant fence, foliage and greenhouse at far right, small watering can far left, all subdued so large plant dominates. Clear blue sky and sun upper left. Whole plant visible with generous margin. No extra foreground plants, no cropped roots, no disconnected parts, no diagrams/arrows/letters/numbers/logos/brands/watermarks. Scientific plant anatomy essential.

## Verification

- All 50 Flutter tests passed, including saved legacy Stem progress, 2x text on a phone, tablet layout, drag placement, gentle retries and exploration persistence.
- dart analyze --fatal-infos: clean.
- Content validator: all 145 source-linked steps passed; no assessment answers changed.
- Rendered and visually reviewed exploration, Stem story and roots puzzle at 824 x 860.
- flutter pub outdated: direct dependencies current; optional transitive updates image_picker_ios 0.8.13+8, material_color_utilities 0.13.1 and test_api 0.7.14 remain pinned. No dependency changes.
- Scope: plant-part exploration, four stories, Build a Plant, free plant building and part identification. Other unit activities retain their existing presentation.

