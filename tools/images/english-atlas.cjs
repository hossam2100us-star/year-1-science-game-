// Builds the English art (docs/ENGLISH_INTEGRATION.md) from the pictures
// generated in Canva Dream Lab, run from tools/images:
//   node english-atlas.cjs <art dir> <work dir>
// The art dir holds islands.png and backdrops.png (2 x 2 scenes) and
// sheet01 to sheet11 (PNG or JPG): six word pictures each in a 3 x 2 grid on a
// flat magenta background (two side by side on the last), in the order of
// englishWords in lib/features/english/english_art.dart.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { cutSheet } = require('./magenta-cut.cjs');

const [art, work] = process.argv.slice(2);
const WORDS = [
  ['alligator', 'bag', 'bee', 'boat', 'bottle', 'box'],
  ['bus', 'bush', 'cake', 'can', 'cat', 'coat'],
  ['crocodile', 'cup', 'dish', 'dog', 'egg', 'elephant'],
  ['fox', 'frog', 'gate', 'goat', 'grass', 'hat'],
  ['hen', 'hippo', 'juice', 'kangaroo', 'kite', 'kookaburra'],
  ['lion', 'loaf', 'monkey', 'monster', 'moose', 'mouse'],
  ['park', 'pencil pot', 'platypus', 'postcard', 'present', 'puddle'],
  ['rabbit', 'rain', 'recycling bin', 'road', 'school', 'sea'],
  ['seal', 'ship', 'snake', 'spider', 'straw', 'sun'],
  ['sweet', 'teddy', 'telescope', 'tiger', 'tree', 'turtle'],
  ['washing machine', 'zebra'],
];
// Equal cells, eight to a row: the app crops a whole cell, so each picture
// is centred in its cell with room around it.
const CELL = 256, PAD = 14, COLS = 8;
const out = path.join(__dirname, '../../assets/images');
const webp = { quality: 80, alphaQuality: 90, effort: 6, smartSubsample: true };
fs.mkdirSync(work, { recursive: true });

(async () => {
  // The two scene atlases keep their 2 x 2 layout, 2048 pixels wide.
  for (const name of ['islands', 'backdrops']) {
    const info = await sharp(path.join(art, `${name}.png`))
      .resize({ width: 2048 })
      .webp(webp)
      .toFile(path.join(out, `english-${name}-v1.webp`));
    console.log(name, `${info.width}x${info.height}`, `${(info.size / 1024).toFixed(0)} KB`);
  }
  const names = [], layers = [];
  for (const [index, items] of WORDS.entries()) {
    // Dream Lab downloads some pictures as JPG and some as PNG.
    const stem = `sheet${String(index + 1).padStart(2, '0')}`;
    const file = ['png', 'jpg']
      .map((ext) => path.join(art, `${stem}.${ext}`))
      .find((f) => fs.existsSync(f));
    if (!file) throw new Error(`${stem} is missing`);
    const { cells, bg } = await cutSheet(file, items.length === 6 ? 3 : 2, items.length === 6 ? 2 : 1);
    console.log(path.basename(file), 'background', bg.join(','));
    for (const [i, name] of items.entries()) {
      if (!cells[i]) throw new Error(`nothing found for ${name}`);
      fs.writeFileSync(path.join(work, `${name.replace(/ /g, '-')}.png`), cells[i]);
      const fitted = await sharp(cells[i])
        .resize({ width: CELL - 2 * PAD, height: CELL - 2 * PAD, fit: 'inside' })
        .png()
        .toBuffer();
      const meta = await sharp(fitted).metadata();
      const n = names.length;
      layers.push({
        input: fitted,
        left: (n % COLS) * CELL + Math.round((CELL - meta.width) / 2),
        top: Math.floor(n / COLS) * CELL + Math.round((CELL - meta.height) / 2),
      });
      names.push(name);
    }
  }
  const size = COLS * CELL;
  const png = await sharp({
    create: { width: size, height: size, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  }).composite(layers).png().toBuffer();
  fs.writeFileSync(path.join(work, 'atlas.png'), png);
  const info = await sharp(png).webp(webp).toFile(path.join(out, 'english-words-v1.webp'));
  for (const [bgName, colour] of [['light', '#f3efe6'], ['dark', '#26313a']]) {
    await sharp({ create: { width: size, height: size, channels: 3, background: colour } })
      .composite([{ input: png }]).png().toFile(path.join(work, `preview-${bgName}.png`));
  }
  fs.writeFileSync(path.join(work, 'names.json'), JSON.stringify(names));
  console.log(names.length, 'words', `${size}x${size}`, `${(info.size / 1024).toFixed(0)} KB`);
})();
