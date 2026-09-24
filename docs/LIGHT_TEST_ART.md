# Light test illustration and interaction

Tool: built-in OpenAI imagegen. Original assets generated for this project; no third-party book illustrations copied.

Assets:
- assets/images/light-room-v1.png: sunny window and open dark cupboard background.
- assets/images/light-plants-v1.png: three-column transparent plant atlas (young, green and strong, pale and floppy). Alpha verified; sprites remain unmodified.

Source: assets/content/unit_02.json, introductionText, PDF pages 6–7, Activity 2. Both young beans get equal water. Day 9 observations and explanation are reused verbatim from the existing source-linked runtime content. The prediction does not affect the observed result or assessment score.

The normal unit route now uses this experiment at 11/40. The separate review link starts at that same step in memory, preserving the child's real saved journey. Legacy frame 1 and frame 2 states resume without discarding their prediction.

## Background prompt
Use case: illustration-story, scientific-educational. Asset: 1536x1024 wide illustrated background for a children's science experiment ages 6–7. Premium warm rounded painterly picture-book art with beautiful wood textures, soft shadows and lush distant greenery, not flat clipart. ONE cozy garden science room. Left half: a large sunny window with green garden outside and warm sunlight; beneath it a broad empty wooden tabletop/potting shelf. Right half: a large dark wooden cupboard, both doors opened sideways, revealing an empty dim interior and flat empty shelf aligned at exactly the same height as the left tabletop. Cupboard interior spans x58–91%,y18–82%, its usable shelf at y82%. The left empty plant placement area spans x12–40%,y25–82%, tabletop at y82%. Both empty placement areas must have plenty of space for potted plant sprites. Camera straight-on with slight natural perspective. No plants, pots, jars, flowers or objects on either shelf; background garden outside window is fine. No people, text, labels, icons, arrows, numbers, brands or watermark. Entire scene fills image. Keep top 10% visually calm. Cheerful, uncluttered, child-friendly.

## Sprite prompt
Use case: scientific-educational, illustration-story. Asset: original transparent-background sprite atlas for an offline children's science game. Wide 1536x1024 image, TRANSPARENT background with genuine alpha, no white or checkerboard baked in. THREE clearly separated full potted BEAN plants arranged in one horizontal row, three equal columns (centers x16.7%,50%,83.3%). Same small round terracotta pot and same soil in every column, pots all at bottom y80–95%, equal size. Column 1: Day 1 young green bean seedling, short stem and two small leaves, entire plant from y54–95%. Column 2: Day 9 with light, compact short sturdy upright GREEN bean plant, thickish stem, broad healthy green leaves, entire plant from y35–95%. Column 3: Day 9 without light, PALE YELLOW bean plant, very LONG THIN FLOPPY bending stem, small pale yellow leaves drooping, taller but weak, entire plant from y8–95%; stem curved downward at top, unmistakably pale and floppy, NOT brown and dead. This is a bean plant, no flowers, no fruits, no vine support, no faces. Premium warm painterly picture-book style, tactile detailed leaves and rounded clay pots, appealing to children aged 6–7, not flat vector icons. Each whole sprite inside its own third with generous transparent space separating them, no overlap. No titles, labels, numbers, arrows, letters, logos, watermark or other objects. Scientific condition differences must be clear, pots must match.

## Verification

- All 58 Flutter tests passed. Light tests cover both predictions, equal watering, tablet/phone/2x text, result save failure/retry, legacy completed saves, progression to 12/40 and review isolation.
- dart analyze --fatal-infos: clean.
- Source validator passed all 145 steps; answers and science wording unchanged.
- Day 1 and Day 9 screenshots at 824 x 860 were rendered and visually inspected; prediction sprite cropping was corrected.
- Direct dependencies are current. Optional pinned transitive updates remain: image_picker_ios 0.8.13+8, material_color_utilities 0.13.1, test_api 0.7.14.
- Browser preview build succeeded; versioned route and both illustration files return HTTP 200 with no-store headers.

