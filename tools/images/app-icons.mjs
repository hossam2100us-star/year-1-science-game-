// Renders every app icon from one master picture, app-icon-v1.webp (Zizo on
// the adventure island, see CREDITS.md):
// - Android: legacy square and round icons for Android 7, and the adaptive
//   icon (picture as the foreground layer on the sky colour) that each
//   launcher masks to its own shape;
// - web: favicon, the manifest icons and the maskable ones.
//
//   cd tools/images && node app-icons.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const res = join(root, 'android', 'app', 'src', 'main', 'res');
const web = join(root, 'web');
const master = join(here, 'app-icon-v1.webp');

// The night sky at the picture's edges, behind the adaptive foreground.
const sky = '#634382';

const png = (image) => image.png({ compressionLevel: 9 });

/** The picture with rounded corners (radius as a share of the side). */
async function rounded(size, radius) {
  const r = Math.round(size * radius);
  const mask = Buffer.from(
    `<svg width="${size}" height="${size}"><rect width="${size}" height="${size}" rx="${r}" ry="${r}"/></svg>`,
  );
  return sharp(await sharp(master).resize(size, size).toBuffer())
    .composite([{ input: mask, blend: 'dest-in' }]);
}

/**
 * The adaptive foreground: a 108 dp layer of which launchers show the middle
 * 72 dp. The picture covers 74 of the 108 dp, so a round mask shows the
 * picture to its edges, and its outer edge fades into the sky colour where a
 * square-ish mask reaches past it.
 */
async function foreground(size) {
  const inner = Math.round((size * 74) / 108);
  const edge = Math.max(2, Math.round(inner * 0.05));
  const fade = await sharp({ create: { width: inner, height: inner, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{
      input: Buffer.from(`<svg width="${inner}" height="${inner}"><rect x="${edge}" y="${edge}" width="${inner - 2 * edge}" height="${inner - 2 * edge}" rx="${edge * 2}" fill="#fff"/></svg>`),
    }])
    .blur(edge / 2)
    .png()
    .toBuffer();
  const picture = await sharp(await sharp(master).resize(inner, inner).toBuffer())
    .composite([{ input: fade, blend: 'dest-in' }])
    .png()
    .toBuffer();
  const offset = Math.round((size - inner) / 2);
  return sharp({ create: { width: size, height: size, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: picture, left: offset, top: offset }]);
}

/** Zizo's face only, for the 32 px favicon where the whole scene blurs. */
const face = { left: 288, top: 122, width: 400, height: 400 };

// Launcher icon sizes: 48 dp at each density.
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [name, scale] of Object.entries(densities)) {
  const dir = join(res, `mipmap-${name}`);
  mkdirSync(dir, { recursive: true });
  const icon = Math.round(48 * scale);
  await png(await rounded(icon, 0.2)).toFile(join(dir, 'ic_launcher.png'));
  await png(await rounded(icon, 0.5)).toFile(join(dir, 'ic_launcher_round.png'));
  await png(await foreground(Math.round(108 * scale))).toFile(join(dir, 'ic_launcher_foreground.png'));
  console.log(`mipmap-${name}: ${icon}px, foreground ${Math.round(108 * scale)}px`);
}
mkdirSync(join(res, 'mipmap-anydpi-v26'), { recursive: true });
const adaptive = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
`;
writeFileSync(join(res, 'mipmap-anydpi-v26', 'ic_launcher.xml'), adaptive);
writeFileSync(join(res, 'mipmap-anydpi-v26', 'ic_launcher_round.xml'), adaptive);
writeFileSync(
  join(res, 'values', 'ic_launcher_background.xml'),
  `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${sky}</color>
</resources>
`,
);

// Web: the manifest icons fill their square; maskable ones keep the
// picture whole too (its edges are sky, outside the 80 % safe circle).
mkdirSync(join(web, 'icons'), { recursive: true });
for (const [file, size, radius] of [
  ['icons/Icon-192.png', 192, 0.2],
  ['icons/Icon-512.png', 512, 0.2],
  ['icons/Icon-maskable-192.png', 192, 0],
  ['icons/Icon-maskable-512.png', 512, 0],
]) {
  await png(radius ? await rounded(size, radius) : sharp(master).resize(size, size)).toFile(join(web, file));
  console.log(`${file} ${size}x${size}`);
}
await png(sharp(master).extract(face).resize(32, 32)).toFile(join(web, 'favicon.png'));
console.log('favicon.png 32x32 (face)');
