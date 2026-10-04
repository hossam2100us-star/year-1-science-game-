// Lossy WebP re-encoding for bundled art (AUD-008).
//
//   node optimize.mjs            -> candidates + review sheets in build/, no changes
//   node optimize.mjs --apply    -> replace bundled files and update references
//
// Images keep their exact pixel size: several scenes address atlas cells by
// absolute pixel rectangles, so resizing would break them.
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { basename, dirname, extname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const apply = process.argv.includes('--apply');
const quality = Number(process.env.WEBP_QUALITY ?? 80);
const candidates = join(root, 'build', 'image-candidates');
const review = join(root, 'build', 'image-review');
mkdirSync(candidates, { recursive: true });
mkdirSync(review, { recursive: true });

const pubspecPath = join(root, 'pubspec.yaml');
const pubspec = readFileSync(pubspecPath, 'utf8');
const bundled = [...pubspec.matchAll(/^\s*-\s*(assets\/images\/\S+)\s*$/gm)].map((m) => m[1]);

function psnr(a, b) {
  let sum = 0;
  for (let i = 0; i < a.length; i++) {
    const d = a[i] - b[i];
    sum += d * d;
  }
  const mse = sum / a.length;
  return mse === 0 ? Infinity : 10 * Math.log10((255 * 255) / mse);
}

const escape = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

async function sideBySide(name, original, candidate, width, height, before, after, score) {
  const crop = Math.min(560, width, height);
  const left = Math.max(0, Math.round(width / 2 - crop / 2));
  const top = Math.max(0, Math.round(height / 2 - crop / 2));
  const region = { left, top, width: crop, height: crop };
  const a = await sharp(original).extract(region).png().toBuffer();
  const b = await sharp(candidate).extract(region).png().toBuffer();
  const header = Buffer.from(
    `<svg width="${crop * 2 + 30}" height="60" xmlns="http://www.w3.org/2000/svg">` +
      `<rect width="100%" height="100%" fill="#ffffff"/>` +
      `<text x="10" y="24" font-size="20" font-family="Arial">${escape(name)} — PSNR ${score.toFixed(1)} dB</text>` +
      `<text x="10" y="50" font-size="18" font-family="Arial">left: current ${(before / 1048576).toFixed(2)} MB` +
      ` | right: lossy q${quality} ${(after / 1048576).toFixed(2)} MB (center crop, 1:1)</text></svg>`,
  );
  await sharp({
    create: { width: crop * 2 + 30, height: crop + 70, channels: 4, background: '#f3efe6' },
  })
    .composite([
      { input: header, left: 0, top: 0 },
      { input: a, left: 10, top: 64 },
      { input: b, left: crop + 20, top: 64 },
    ])
    .png()
    .toFile(join(review, `${basename(name, extname(name))}.png`));
}

const rows = [];
let totalBefore = 0;
let totalAfter = 0;
for (const asset of bundled) {
  const input = join(root, asset);
  const before = statSync(input).size;
  const image = sharp(input).ensureAlpha();
  const { width, height } = await image.metadata();
  // Compare what the child sees: both versions flattened onto the game's
  // cream background (hidden colour under transparent pixels is ignored).
  const seen = (buffer) => sharp(buffer).flatten({ background: '#FFF8EC' }).raw().toBuffer();
  const original = await seen(await sharp(input).png().toBuffer());
  const encoded = await sharp(input)
    .webp({ quality, alphaQuality: 90, effort: 6, smartSubsample: true })
    .toBuffer();
  const info = await sharp(encoded).metadata();
  if (info.width !== width || info.height !== height) {
    throw new Error(`${asset}: size changed`);
  }
  const score = psnr(original, await seen(encoded));
  const target = asset.replace(/\.(png|webp)$/, '.webp');
  writeFileSync(join(candidates, basename(target)), encoded);
  await sideBySide(basename(asset), await sharp(input).png().toBuffer(), encoded, width, height, before, encoded.length, score);
  // Never make a file bigger.
  const useCandidate = encoded.length < before;
  const after = useCandidate ? encoded.length : before;
  totalBefore += before;
  totalAfter += after;
  rows.push({ asset, target: useCandidate ? target : asset, width, height, before, after, psnr: score, useCandidate });
}

const mb = (n) => (n / 1048576).toFixed(2);
const report = [
  `# Bundled image re-encode (WebP q${quality}, alpha q90)`,
  '',
  '| File | Pixels | Current MB | Lossy MB | Saved | PSNR dB |',
  '|---|---|---|---|---|---|',
  ...rows.map(
    (r) =>
      `| ${basename(r.asset)} | ${r.width}×${r.height} | ${mb(r.before)} | ${mb(r.after)} | ${(100 * (1 - r.after / r.before)).toFixed(0)}% | ${r.psnr.toFixed(1)} |`,
  ),
  `| **Total (${rows.length} files)** | | **${mb(totalBefore)}** | **${mb(totalAfter)}** | **${(100 * (1 - totalAfter / totalBefore)).toFixed(0)}%** | |`,
  '',
].join('\n');
writeFileSync(join(review, 'report.md'), report);
console.log(report);

if (apply) {
  let spec = pubspec;
  const renames = [];
  for (const r of rows.filter((x) => x.useCandidate)) {
    writeFileSync(join(root, r.target), readFileSync(join(candidates, basename(r.target))));
    if (r.target !== r.asset) {
      rmSync(join(root, r.asset));
      spec = spec.replace(r.asset, r.target);
      renames.push([basename(r.asset), basename(r.target)]);
    }
  }
  writeFileSync(pubspecPath, spec);
  // Update code and content references to renamed files.
  const walk = (dir) =>
    readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
      e.isDirectory() ? walk(join(dir, e.name)) : [join(dir, e.name)],
    );
  for (const file of [...walk(join(root, 'lib')), ...walk(join(root, 'test')), ...walk(join(root, 'assets', 'content'))]) {
    if (!/\.(dart|json)$/.test(file) || file.includes(`${'l10n'}`)) continue;
    let text = readFileSync(file, 'utf8');
    const original = text;
    for (const [from, to] of renames) text = text.split(from).join(to);
    if (text !== original) {
      writeFileSync(file, text);
      console.log(`updated references in ${relative(root, file)}`);
    }
  }
  if (!existsSync(join(root, 'assets', 'images'))) throw new Error('assets missing');
  console.log(`applied ${rows.filter((x) => x.useCandidate).length} files`);
}
