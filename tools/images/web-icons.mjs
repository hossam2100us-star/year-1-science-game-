// Renders the web app icons from the same artwork as the Android launcher
// icon (android/app/src/main/res/drawable/ic_launcher.xml), so both
// platforms show the same flask.
//
//   cd tools/images && node web-icons.mjs
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const web = join(root, 'web');

// Paths copied from ic_launcher.xml (108 x 108 viewport).
const artwork = `
  <path fill="#2170B5" d="M40,18h28v9h-5v23l19,32c4,7 -1,13 -9,13h-38c-8,0 -13,-6 -9,-13l19,-32v-23h-5z"/>
  <path fill="#D9F2DF" d="M45,65h18l13,21h-44z"/>
  <path fill="#FFFFFF" d="M52,29h4v25l-10,17h-5l11,-19z"/>
  <path fill="#E88A2E" d="M83,18l3,6l6,3l-6,3l-3,6l-3,-6l-6,-3l6,-3z"/>`;

/** `scale` < 1 keeps the artwork inside the maskable safe zone. */
const svg = (scale) => {
  const offset = (108 * (1 - scale)) / 2;
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">
  <rect width="108" height="108" fill="#FFF8EC"/>
  <g transform="translate(${offset} ${offset}) scale(${scale})">${artwork}</g>
</svg>`);
};

mkdirSync(join(web, 'icons'), { recursive: true });
const outputs = [
  ['favicon.png', 32, 1],
  ['icons/Icon-192.png', 192, 1],
  ['icons/Icon-512.png', 512, 1],
  ['icons/Icon-maskable-192.png', 192, 0.8],
  ['icons/Icon-maskable-512.png', 512, 0.8],
];
for (const [file, size, scale] of outputs) {
  await sharp(svg(scale), { density: 600 }).resize(size, size).png({ compressionLevel: 9 }).toFile(join(web, file));
  console.log(`${file} ${size}x${size}`);
}
