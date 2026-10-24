// Builds the English story scenes (teacher review 8, docs/ENGLISH_INTEGRATION.md)
// from pictures generated in Canva Dream Lab, run from tools/images:
//   node english-scenes.cjs <art dir> <work dir>
// The art dir holds sceneA to sceneF (PNG or JPG): four wide scenes each in a
// 2 x 2 grid with a thin white gap, in the order of englishScenes in
// lib/features/english/english_art.dart.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const [art, work] = process.argv.slice(2);
const SCENES = [
  ['aqsa-monster', 'aqsa-falls', 'aqsa-cloud', 'mum-washing'],
  ['school-arrive', 'football', 'family-dinner', 'classroom'],
  ['tiddalik-drinks', 'tiddalik-jokes', 'tiddalik-laughs', 'wombat'],
  ['lion-mouse', 'tiger-trap', 'two-kings', 'swings'],
  ['gogo-walk', 'red-tackies-window', 'red-tackies-proud', 'market'],
  ['shark-park', 'mr-gumpy', 'rubys-worry', 'katie-morag'],
];
// Equal 16:9 cells, four to a row: the app crops a whole cell.
const W = 448, H = 252, COLS = 4;
const out = path.join(__dirname, '../../assets/images');
const webp = { quality: 78, effort: 6, smartSubsample: true };
fs.mkdirSync(work, { recursive: true });

/** The share of near-white pixels in each column (or row) of a picture. */
function whiteness({ data, info }, alongX) {
  const [n, m] = alongX ? [info.width, info.height] : [info.height, info.width];
  const share = new Array(n).fill(0);
  for (let i = 0; i < n; i++) {
    let white = 0;
    for (let j = 0; j < m; j++) {
      const [x, y] = alongX ? [i, j] : [j, i];
      const p = (y * info.width + x) * info.channels;
      if (data[p] > 225 && data[p + 1] > 225 && data[p + 2] > 225) white++;
    }
    share[i] = white / m;
  }
  return share;
}

/** The white gap near the middle, or the middle line when there is none. */
function gap(share) {
  const n = share.length;
  let best = Math.round(n / 2);
  for (let i = Math.round(n * 0.4); i < n * 0.6; i++) if (share[i] > share[best]) best = i;
  if (share[best] < 0.6) return [best, best];
  let [a, b] = [best, best];
  while (a > 0 && share[a - 1] > 0.5) a--;
  while (b < n - 1 && share[b + 1] > 0.5) b++;
  return [a, b + 1];
}

/** The picture without white rows or columns along its outer edges. */
function inner(share) {
  let [a, b] = [0, share.length];
  while (a < b && share[a] > 0.6) a++;
  while (b > a && share[b - 1] > 0.6) b--;
  return [a, b];
}

(async () => {
  const layers = [], names = [];
  for (const [index, items] of SCENES.entries()) {
    const stem = `scene${'ABCDEF'[index]}`;
    const file = ['png', 'jpg']
      .map((ext) => path.join(art, `${stem}.${ext}`))
      .find((f) => fs.existsSync(f));
    if (!file) throw new Error(`${stem} is missing`);
    const raw = await sharp(file).removeAlpha().raw().toBuffer({ resolveWithObject: true });
    const cols = whiteness(raw, true), rows = whiteness(raw, false);
    const [x0, x1] = gap(cols), [y0, y1] = gap(rows);
    const [left, right] = inner(cols), [top, bottom] = inner(rows);
    const boxes = [
      [left, top, x0, y0], [x1, top, right, y0],
      [left, y1, x0, bottom], [x1, y1, right, bottom],
    ];
    console.log(path.basename(file), `${raw.info.width}x${raw.info.height}`,
      'gap x', x0, x1, 'y', y0, y1);
    for (const [i, name] of items.entries()) {
      // A few pixels in from each edge, so no white line is left.
      const [l, t, r, b] = boxes[i];
      const cell = await sharp(file)
        .extract({ left: l + 3, top: t + 3, width: r - l - 6, height: b - t - 6 })
        .resize({ width: W, height: H, fit: 'cover' })
        .png()
        .toBuffer();
      fs.writeFileSync(path.join(work, `${name}.png`), cell);
      const n = names.length;
      layers.push({ input: cell, left: (n % COLS) * W, top: Math.floor(n / COLS) * H });
      names.push(name);
    }
  }
  const atlas = sharp({
    create: { width: COLS * W, height: SCENES.length * H, channels: 3, background: '#ffffff' },
  }).composite(layers);
  const png = await atlas.png().toBuffer();
  fs.writeFileSync(path.join(work, 'scenes.png'), png);
  const info = await sharp(png).webp(webp).toFile(path.join(out, 'english-scenes-v1.webp'));
  fs.writeFileSync(path.join(work, 'names.json'), JSON.stringify(names));
  console.log(names.length, 'scenes', `${info.width}x${info.height}`,
    `${(info.size / 1024).toFixed(0)} KB`);
})();
