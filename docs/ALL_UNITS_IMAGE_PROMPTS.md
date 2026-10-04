# All-units illustration review — 3 October 2026

Built-in image generation is used; outputs are copied into assets/images without background filtering. The existing reference files are retained. Integration and final verification are recorded in ALL_UNITS_REVIEW.md.

## materials-atlas-v2.png

Use case: background-extraction
Asset type: transparent watercolor/gouache sprite atlas for an offline children's science adventure.
Edit the supplied image. Preserve the exact sixteen subjects, their scientific identities, style, colors, fine textures and arrangement in a strict 4 by 4 regular grid. Keep generous transparent margins inside each equal cell, every entire subject fitting inside its original cell. Remove ONLY the cream paper backgrounds, cell outlines and opaque rectangular backdrops; replace those areas with genuine alpha transparency. Do not leave a white matte, checkerboard or erased pale object parts. Preserve the original polished storybook art quality and complete silhouettes. No new text, captions, numerals, labels, arrows, icons or decorative marks.
Keep all sixteen exact subjects in their original 4 x 4 positions: row 1 silver spoon, wooden chair, whole framed window with blue transparent glass, folded purple cotton shirt; row 2 folded newspaper with abstract gray print, closed blue plastic bottle, aluminium foil, pink sponge; row 3 gray stone, yellow rubber band, terracotta pot, yellow wooden pencil with graphite tip; row 4 white tissue, blue umbrella, red brick, soft pale dough. The whole window including frame remains a complete object. Do not add labels or objects.

## electric-atlas-v2.png

Use case: background-extraction
Asset type: transparent watercolor/gouache sprite atlas for an offline children's science adventure.
Edit the supplied image. Preserve the exact sixteen subjects, their scientific identities, style, colors, fine textures and arrangement in a strict 4 by 4 regular grid. Keep generous transparent margins inside each equal cell, every entire subject fitting inside its original cell. Remove ONLY the cream paper backgrounds, cell outlines and opaque rectangular backdrops; replace those areas with genuine alpha transparency. Do not leave a white matte, checkerboard or erased pale object parts. Preserve the original polished storybook art quality and complete silhouettes. No new text, captions, numerals, labels, arrows, icons or decorative marks.
Keep all sixteen exact subjects in their original 4 x 4 positions: row1 television, vacuum cleaner, historical lantern, desk lamp; row2 dishwasher, broom, battery, yellow torch; row3 refrigerator, battery wall clock, bicycle, air conditioner; row4 plastic blue button, gold ring, steel coat hanger, purple cotton socks. Keep appliances neutral, with no cables, plugs or exposed sockets, no visible electricity effects or magnet interaction. Preserve battery +/- markings and clock face as object detail.

## earth-atlas-v2.png

Use case: background-extraction
Asset type: transparent watercolor/gouache sprite atlas for an offline children's science adventure.
Edit the supplied image. Preserve the exact sixteen subjects, their scientific identities, style, colors, fine textures and arrangement in a strict 4 by 4 regular grid. Keep generous transparent margins inside each equal cell, every entire subject fitting inside its original cell. Remove ONLY the cream paper backgrounds, cell outlines and opaque rectangular backdrops; replace those areas with genuine alpha transparency. Do not leave a white matte, checkerboard or erased pale object parts. Preserve the original polished storybook art quality and complete silhouettes. No new text, captions, numerals, labels, arrows, icons or decorative marks.
Keep all sixteen exact subjects in original 4 x 4 positions: row1 pond vignette, stream vignette, river vignette, lake vignette; row2 ocean vignette, blue whale, crocodile, frog; row3 soil mound, earthworm, coal, diamond; row4 Earth globe, Sun, Moon, full astronaut. Habitats retain their scenic foliage/water INSIDE their painted silhouette but the surrounding cream paper is transparent. Remove the blue rectangular water panel behind the whale and ground scenery behind crocodile/frog, leaving complete isolated animals. Earth must stay round and mostly blue; Sun/Moon stay natural, with no faces. No labels, arrows, answer indicators, visible shadow boxes or opaque tile edges.

## science-details-v2.png

Use case: background-extraction
Asset type: transparent watercolor/gouache sprite atlas for an offline children's science adventure.
Edit the supplied image. Preserve the exact sixteen subjects, their scientific identities, style, colors, fine textures and arrangement in a strict 4 by 4 regular grid. Keep generous transparent margins inside each equal cell, every entire subject fitting inside its original cell. Remove ONLY the cream paper backgrounds, cell outlines and opaque rectangular backdrops; replace those areas with genuine alpha transparency. Do not leave a white matte, checkerboard or erased pale object parts. Preserve the original polished storybook art quality and complete silhouettes. No new text, captions, numerals, labels, arrows, icons or decorative marks.
Keep all sixteen exact original subjects in their 4 x 4 positions: row1 blue plastic pot, blue glass marble, striped paper straw, wooden block; row2 fabric cloth, see-through glass slab, white paper sheet, silver metal block; row3 wood plank, pale white plastic slab, lump of clay, dark graphite rod; row4 astronaut helmet with gold visor, white oxygen backpack with hose, white astronaut gloves, white astronaut boots. Keep white tissue/paper/suit edges and all fine object details opaque and visible. All thin cell borders and cream paper backgrounds must disappear. Do not add labels, arrows, checkmarks or symbols.

## Delivery and final crop integration — 4 October 2026

The four v2 PNG files above were actually generated with the built-in image tool and copied into E:/seif-science-game/assets/images. Source references were inspected before each edit. No fallback CLI/API, background filtering or asset retouching was used. All four have real RGBA alpha (0–255). Pixel-bound crops are now measured and implemented in lib/features/science/science_atlas_crops.dart; quarter-cell crops are not used because the generated subjects slightly cross grid row boundaries.

Final paths: E:/seif-science-game/assets/images/materials-atlas-v2.png; E:/seif-science-game/assets/images/electric-atlas-v2.png; E:/seif-science-game/assets/images/earth-atlas-v2.png; E:/seif-science-game/assets/images/science-details-v2.png.

## Remaining specifications, not delivered

The next built-in request (physics-atlas-v2.png background extraction) failed with HTTP 429 usage_limit. The following prepared specifications remain recorded for later work. Only the Physics request was submitted in this resumed pass; the loop stopped on that error, so the following three requests were not submitted or generated. None of these pending filenames is referenced by runtime code or registered in pubspec.yaml.

### physics-atlas-v2.png — submitted, blocked by usage limit

Use case: background-extraction
Asset type: transparent storybook sprite atlas for a children's science adventure.
Edit target: the supplied atlas. Preserve the exact sixteen subjects, identities, style, colors, proportions and arrangement in a strict regular four by four grid. Entire subjects fit within their original equal cells, generous transparent margins. Remove only the cream paper background, thin cell borders and rectangular backdrops. Make those areas genuinely alpha transparent, never a white matte or checkerboard. Keep white feathers and sails opaque. Keep the full swing frame and grass silhouette. No text, numbers, extra objects, arrows or answer indicators.
Original cells: row1 doorbell, wooden drawer, complete playground swing, shopping trolley; row2 sailboat, cork, red balloon, steel nail; row3 triangle instrument and striker, pair of maracas, trumpet, sitar; row4 blue drum with sticks, white feather, red-blue horseshoe magnet, steel key.

### science-extras-v2.png — prepared only

Use case: background-extraction
Asset type: transparent storybook sprite atlas for a children's science adventure.
Edit target: supplied image. Keep exact sixteen original subjects and identities, arrangement, polished watercolor style, colors, proportions and detail in strict equal four by four cells. Keep complete silhouettes with transparent margins in each original cell. Remove only cream paper backgrounds and grid lines, genuine alpha transparency. Never leave white rectangles or checkerboard, do not erase pale object parts. Preserve all original painted subjects. No text, labels, arrows, numbers or additions.
Row1 snake, goldfish, kangaroo, crawling baby. Row2 orange, peeled orange, whole wooden door, purple ball. Row3 sand pile, dead leaf, beetle, empty plastic carrier bag. Row4 saucepan, empty cardboard box, blue plate, thundercloud with lightning.

### biology-scenes-v3.png — prepared only

Use case: illustration-story
Asset type: genuinely transparent sprite atlas for a polished children's science adventure, harmonious watercolor and gouache, clear expressive objects, softly painted textures and readable silhouettes.
A strict regular 4 by 4 grid of sixteen isolated subjects, no visible grid, every whole subject centered in its own equal cell with at least 10 percent empty transparent margin. Same relative visual scale and same warm polished storybook style throughout. True alpha transparency outside every subject, no paper backgrounds, no panels, no checkerboard, no labels, numbers, letters, arrows or UI.
Exact subjects by row left to right:
row1 small blue music speaker with two tiny musical notes; bouquet of colorful flowers; blue compact toy-style car; wooden colorful blocks beside a small teddy bear.
row2 one clean white sheet of paper with subtle visible edges; curling soft breeze with a ribbon and two flying leaves; visibly drooping dry potted plant; lush green whole tree.
row3 soft white cloud; plain wooden table; unmistakable wooden toy doll; silver kettle.
row4 small loaf of bread; a newly hatched chick beside its eggshell; pale yellow floppy potted plant; red and blue horseshoe magnet.
Do not print explanations or answers. The breeze is an illustration of moving air, not a person. Full shapes, no cropped objects, no adult realism, no exaggerated faces on objects.

### science-worlds-v2.png — prepared only

Use case: illustration-story
Asset type: three calm storybook scene backgrounds for a children's science adventure; one image containing three horizontal landscape panels stacked vertically, each panel twice as wide as high, exact equal thirds of the total image. No dividers, no text or labels. Soft polished watercolor and gouache matching a garden adventure, rich natural texture, clean foreground to layer interactive objects later.
TOP third: cozy safe home discovery room, warm light blue wall, simple wooden counter across center and warm floor foreground. Only background architecture, no appliances, toys, people, plugs, sockets or cables. Plenty of empty foreground and central space.
MIDDLE third: peaceful outdoor nature clearing beside a coast, green meadow foreground left, natural brown soil patch foreground, gently curving blue water right and soft sky above. No animals, litter, large rocks or interactive objects. Balanced sparse framing foliage at far edges; broad open middle.
BOTTOM third: peaceful imaginative space exploration setting, lunar gray terrain foreground, deep indigo starry sky above with sparse small stars. No spacecraft, astronaut, planets, large Sun, Earth or Moon in sky. Plenty of empty middle for educational sprites.
Keep all three panels equally calm and clear, avoid clutter, photorealism, UI, arrows and embedded characters.

## Single magnet extraction — 4 October 2026, not generated

The built-in edit below returned HTTP 429 `usage_limit_reached`. Source inspected: `E:/seif-science-game/assets/images/physics-atlas-v1.webp`. No output asset was produced, no unavailable asset was registered and no fallback CLI/API was used. The current application removes the opaque cell through a display crop and silhouette clip in `lib/features/science/magnet_picture.dart`; the original source bitmap is unchanged. A future standalone genuinely transparent bitmap can replace this rendering treatment.

Exact submitted prompt:

Use case: background-extraction.
Asset type: one transparent storybook game sprite for a children's science lesson.
Edit target: the supplied 4-by-4 atlas. Extract ONLY the red and blue horseshoe magnet in row 4, column 3 into a new single-object image. Preserve that exact magnet's full U-shaped silhouette, upright orientation, red left half, blue right half, silver metal tips, finely painted watercolor/gouache texture, soft highlights and proportions. Center the complete magnet, with modest transparent margin. Remove the entire cream paper background, grid lines, ground shadow and every other object. Background must have genuine alpha transparency outside and inside the U opening. No white or cream matte, no opaque rectangle, no panel, no border, no checkerboard drawn into pixels. Keep magnet edges and metal tips opaque. Do not add text, N/S markings, arrows, magnetic field lines, sparkles, hands, other objects or a shadow box. Return the single polished magnet sprite, no surrounding scene.


