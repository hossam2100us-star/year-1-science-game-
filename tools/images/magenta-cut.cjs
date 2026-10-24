// Cuts objects off a flat magenta background, for the picture atlases
// made from Canva sheets (docs/MATHS_ART_V2.md, docs/ENGLISH_INTEGRATION.md).
// cutSheet(file, cols, rows) returns one trimmed transparent PNG per grid
// cell (null for an empty cell) and the measured background colour:
// 1. the background colour is measured from the sheet's border;
// 2. transparency comes from how much magenta is mixed in, only in the
//    background and a thin edge around it (a purple grape stays solid);
// 3. edge pixels are un-mixed from the measured colour (no pink fringe);
// 4. connected pieces go to the grid cell of their centre, so an object
//    reaching into the next cell is not cut in two.
const sharp = require('sharp');

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

module.exports = { cutSheet };
