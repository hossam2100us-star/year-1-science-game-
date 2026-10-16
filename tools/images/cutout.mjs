// Cuts out a picture drawn on a flat magenta (#FF00FF) background and saves
// it as a transparent WebP with the same settings as optimize.mjs.
//
//   node cutout.mjs <input.png|jpg> <output.webp|png> [maxSize=1024]
//
// A .png output is lossless, for pictures that are edited further before
// their one WebP encoding.
//
// Magenta is far from every colour used in the art (the lilac sweater has
// much more green), so a pixel's "magenta-ness" decides its transparency.
// Edge pixels are un-mixed from the magenta so no pink fringe remains.
import sharp from 'sharp';

const [input, output, maxArg] = process.argv.slice(2);
if (!input || !output) {
  console.error('usage: node cutout.mjs <input> <output.webp> [maxSize]');
  process.exit(2);
}
const maxSize = Number(maxArg ?? 1024);
const { data, info } = await sharp(input).removeAlpha().raw().toBuffer({ resolveWithObject: true });
const out = Buffer.alloc(info.width * info.height * 4);
const solid = 70; // below: fully kept
const clear = 150; // above: fully transparent
for (let i = 0, o = 0; i < data.length; i += 3, o += 4) {
  const r = data[i], g = data[i + 1], b = data[i + 2];
  const magenta = Math.abs(r - b) < 90 ? Math.min(r, b) - g : 0;
  const a = magenta <= solid ? 1 : magenta >= clear ? 0 : 1 - (magenta - solid) / (clear - solid);
  const brightness = (r + b) / 2;
  if (magenta > solid && brightness < 215 && g < 70) {
    // A darker magenta is the soft shadow under the feet: keep it as a
    // light neutral shadow (as in the other pictures), not a coloured smudge.
    out[o] = out[o + 1] = out[o + 2] = 40;
    out[o + 3] = Math.round(255 * Math.min(0.35, ((215 - brightness) / 215) * 1.4));
    continue;
  }
  if (a > 0 && a < 1) {
    // Un-mix the background: colour = (seen - (1 - a) * magenta) / a.
    out[o] = Math.max(0, Math.min(255, (r - (1 - a) * 255) / a));
    out[o + 1] = Math.max(0, Math.min(255, g / a));
    out[o + 2] = Math.max(0, Math.min(255, (b - (1 - a) * 255) / a));
  } else {
    out[o] = r;
    out[o + 1] = g;
    out[o + 2] = b;
  }
  out[o + 3] = Math.round(a * 255);
}
const cut = sharp(out, { raw: { width: info.width, height: info.height, channels: 4 } });
const trimmed = await sharp(await cut.png().toBuffer()).trim({ threshold: 1 }).png().toBuffer();
const resized = sharp(trimmed).resize({ width: maxSize, height: maxSize, fit: 'inside', withoutEnlargement: true });
const result = await (output.endsWith('.png')
  ? resized.png()
  : resized.webp({ quality: 80, alphaQuality: 90, effort: 6, smartSubsample: true })
).toFile(output);
console.log(`${output}: ${result.width}x${result.height}, ${(result.size / 1024).toFixed(0)} KB`);
