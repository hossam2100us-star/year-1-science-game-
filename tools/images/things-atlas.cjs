// Builds assets/images/maths-things-v1.webp from the Canva object sheets
// (docs/MATHS_ART_V2.md), run from tools/images:
//   node things-atlas.cjs <sheets dir> <work dir>
// The sheets are a.png to f.png: the six pages of the Canva design, cropped
// to the generated picture (1536x1024, or 1776x896 for e and f).
// Each sheet holds objects in a grid on a flat magenta background, cut out
// by magenta-cut.cjs.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { cutSheet } = require('./magenta-cut.cjs');

const [sheets, work] = process.argv.slice(2);
const SHEETS = [
  ['a.png', 3, 2, ['spoon', 'shoe', 'bed', 'toothbrush', 'football', 'alarm clock']],
  ['b.png', 3, 2, ['grape', 'watermelon', 'strawberry', 'feather', 'book', 'chair']],
  ['c.png', 3, 2, ['pillow', 'stone', 'jug', 'mug', 'bowl', 'scales']],
  ['d.png', 3, 2, ['ruler', 'parcel', 'flour', 'school bag', 'dinner', 'glass of water']],
  ['e.png', 2, 1, ['string', null]],
  ['f.png', 2, 1, ['open eye', 'closed eye']],
];
const CELL = 320, PAD = 16, COLS = 6;
fs.mkdirSync(work, { recursive: true });

(async () => {
  const names = [], layers = [], bounds = [];
  for (const [file, cols, rows, items] of SHEETS) {
    const { cells, bg } = await cutSheet(path.join(sheets, file), cols, rows);
    console.log(file, 'background', bg.join(','));
    for (const [i, name] of items.entries()) {
      if (!name) continue;
      if (!cells[i]) throw new Error(`nothing found for ${name}`);
      fs.writeFileSync(path.join(work, `${name.replace(/ /g, '-')}.png`), cells[i]);
      const fitted = await sharp(cells[i]).resize({ width: CELL - 2 * PAD, height: CELL - 2 * PAD, fit: 'inside' }).png().toBuffer();
      const meta = await sharp(fitted).metadata();
      const n = names.length;
      const left = (n % COLS) * CELL + Math.round((CELL - meta.width) / 2);
      const top = Math.floor(n / COLS) * CELL + Math.round((CELL - meta.height) / 2);
      layers.push({ input: fitted, left, top });
      // Two pixels of padding keep soft edges without touching a neighbour.
      bounds.push([left - 2, top - 2, left + meta.width + 2, top + meta.height + 2]);
      names.push(name);
    }
  }
  const rowsOut = Math.ceil(names.length / COLS);
  const png = await sharp({
    create: { width: COLS * CELL, height: rowsOut * CELL, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  }).composite(layers).png().toBuffer();
  fs.writeFileSync(path.join(work, 'atlas.png'), png);
  const info = await sharp(png)
    .webp({ quality: 80, alphaQuality: 90, effort: 6, smartSubsample: true })
    .toFile(path.join(__dirname, '../../assets/images/maths-things-v1.webp'));
  for (const [bgName, colour] of [['light', '#f3efe6'], ['dark', '#26313a']]) {
    await sharp({ create: { width: COLS * CELL, height: rowsOut * CELL, channels: 3, background: colour } })
      .composite([{ input: png }]).png().toFile(path.join(work, `preview-${bgName}.png`));
  }
  fs.writeFileSync(path.join(work, 'names.json'), JSON.stringify(names));
  fs.writeFileSync(path.join(work, 'bounds.txt'), bounds.map((b, i) => `  Rect.fromLTRB(${b.join(', ')}), // ${names[i]}`).join('\n'));
  console.log(names.length, 'objects', `${COLS * CELL}x${rowsOut * CELL}`, `${(info.size / 1024).toFixed(0)} KB`);
})();
