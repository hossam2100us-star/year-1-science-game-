// Builds assets/images/maths-things-v1.webp from the Canva object sheets
// (docs/MATHS_ART_V2.md), run from tools/images:
//   node things-atlas.cjs <sheets dir> <work dir>
// The sheets are a.png to f.png: the six pages of the Canva design, cropped
// to the generated picture (1536x1024, or 1776x896 for e and f).
// Each sheet holds objects in a grid on a flat magenta background:
// 1. the background colour is measured from the sheet's border;
// 2. transparency comes from how much magenta is mixed in, only in the
//    background and a thin edge around it (a purple grape stays solid);
// 3. edge pixels are un-mixed from the measured colour (no pink fringe);
// 4. connected pieces go to the grid cell of their centre, so an object
//    reaching into the next cell is not cut in two.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

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

async function cutSheet(file, cols, rows) {
  const { data, info } = await sharp(file).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: w, height: h } = info;
  const px = (i) => [data[i * 3], data[i * 3 + 1], data[i * 3 + 2]];
  // 1. Background colour: the median of the border pixels.
  const border = [];
  for (let x = 0; x < w; x++) border.push(px(x), px((h - 1) * w + x));
  for (let y = 0; y < h; y++) border.push(px(y * w), px(y * w + w - 1));
  const bg = [0, 1, 2].map((c) => border.map((p) => p[c]).sort((a, b) => a - b)[border.length >> 1]);
  // How much of the background is mixed into a pixel: magenta is high in
  // red and blue and low in green, so (min(red, blue) - green) measures it.
  const magenta = (r, g, b) => (Math.abs(r - b) < 90 ? Math.max(0, Math.min(r, b) - g) : 0);
  const full = magenta(...bg);
  const raw = new Float32Array(w * h);
  for (let i = 0; i < w * h; i++) raw[i] = Math.min(1, Math.max(0, 1 - magenta(...px(i)) / full));
  // 2. Background: every nearly pure background pixel (also inside a
  // handle), grown through pixels that are more background than object.
  const outside = new Uint8Array(w * h);
  const queue = new Int32Array(w * h);
  let head = 0, tail = 0;
  for (let i = 0; i < w * h; i++) if (raw[i] < 0.15) { outside[i] = 1; queue[tail++] = i; }
  while (head < tail) {
    const i = queue[head++], x = i % w, y = (i / w) | 0;
    for (const j of [x > 0 ? i - 1 : -1, x < w - 1 ? i + 1 : -1, y > 0 ? i - w : -1, y < h - 1 ? i + w : -1]) {
      if (j >= 0 && !outside[j] && raw[j] < 0.5) { outside[j] = 1; queue[tail++] = j; }
    }
  }
  // Edge band: three pixels around the background are partly see-through;
  // deeper inside, an object keeps every pixel (a purple grape stays solid).
  const band = new Uint8Array(outside);
  for (let pass = 0; pass < 3; pass++) {
    const next = new Uint8Array(band);
    for (let i = 0; i < w * h; i++) {
      if (band[i]) continue;
      const x = i % w, y = (i / w) | 0;
      if ((x > 0 && band[i - 1]) || (x < w - 1 && band[i + 1]) || (y > 0 && band[i - w]) || (y < h - 1 && band[i + w])) next[i] = 1;
    }
    band.set(next);
  }
  const alpha = new Float32Array(w * h);
  const rgba = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    const a = outside[i] && raw[i] < 0.15 ? 0 : band[i] ? raw[i] : 1;
    alpha[i] = a;
    const seen = px(i);
    for (let c = 0; c < 3; c++) {
      // 3. Un-mix the background: colour = (seen - (1 - a) * bg) / a.
      rgba[i * 4 + c] = a > 0 && a < 1 ? Math.max(0, Math.min(255, (seen[c] - (1 - a) * bg[c]) / a)) : seen[c];
    }
    rgba[i * 4 + 3] = Math.round(a * 255);
  }
  // 4. Connected pieces (8-neighbours) of visible pixels, by cell of centre.
  const label = new Int32Array(w * h).fill(-1);
  const pieces = [];
  for (let s = 0; s < w * h; s++) {
    if (alpha[s] <= 0 || label[s] >= 0) continue;
    const id = pieces.length;
    let n = 0, sx = 0, sy = 0;
    head = tail = 0; queue[tail++] = s; label[s] = id;
    while (head < tail) {
      const i = queue[head++], x = i % w, y = (i / w) | 0;
      n++; sx += x; sy += y;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        const j = ny * w + nx;
        if (alpha[j] > 0 && label[j] < 0) { label[j] = id; queue[tail++] = j; }
      }
    }
    const cell = Math.min(cols - 1, Math.floor(sx / n / (w / cols))) + cols * Math.min(rows - 1, Math.floor(sy / n / (h / rows)));
    pieces.push({ n, cell });
  }
  const cells = [];
  for (let c = 0; c < cols * rows; c++) {
    const out = Buffer.alloc(w * h * 4);
    let any = false;
    for (let i = 0; i < w * h; i++) {
      const p = label[i] >= 0 ? pieces[label[i]] : null;
      // Specks smaller than 40 pixels are noise.
      if (p && p.cell === c && p.n >= 40) { rgba.copy(out, i * 4, i * 4, i * 4 + 4); any = true; }
    }
    cells.push(any ? await sharp(out, { raw: { width: w, height: h, channels: 4 } }).trim({ threshold: 0 }).png().toBuffer() : null);
  }
  return { cells, bg };
}

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
