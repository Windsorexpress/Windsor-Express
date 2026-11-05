// Downloads the official product images listed in scripts/product-images.json
// and saves each as a 1000x1000 JPEG on a white background in images/phones/.
// Hosting our own copies means Merchant Center never hits a hotlink block or a
// manufacturer CDN change. Existing files are kept unless FORCE=1 is set.
import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "scripts/product-images.json"), "utf8"));
const outDir = path.join(root, "images/phones");
fs.mkdirSync(outDir, { recursive: true });

const SIZE = 1000;
let saved = 0, skipped = 0;
const failed = [];

for (const [name, url] of Object.entries(manifest)) {
  if (name.startsWith("_")) continue;
  const file = path.join(outDir, `${name}.jpg`);
  if (fs.existsSync(file) && process.env.FORCE !== "1") { skipped++; continue; }
  try {
    const res = await fetch(url, { headers: { "User-Agent": "Mozilla/5.0 (WindsorExpressImageFetcher)" } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const input = Buffer.from(await res.arrayBuffer());
    const meta = await sharp(input).metadata();
    if (!meta.width || meta.width < 300) throw new Error(`image too small (${meta.width}x${meta.height})`);
    // Some manufacturer shots sit on a light grey studio band rather than
    // white. Push every near-white pixel to pure white, then trim the plain
    // border, fit the phone into 90% of the square and centre it on white so
    // every listing image looks the same.
    const { data, info } = await sharp(input)
      .flatten({ background: "#ffffff" })
      .removeAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    for (let i = 0; i < data.length; i += 3) {
      if (data[i] >= 242 && data[i + 1] >= 242 && data[i + 2] >= 242) {
        data[i] = data[i + 1] = data[i + 2] = 255;
      }
    }
    const trimmed = await sharp(data, { raw: { width: info.width, height: info.height, channels: 3 } })
      .trim({ background: "#ffffff", threshold: 10 })
      .resize(Math.round(SIZE * 0.9), Math.round(SIZE * 0.9), { fit: "inside" })
      .png()
      .toBuffer();
    await sharp({ create: { width: SIZE, height: SIZE, channels: 3, background: "#ffffff" } })
      .composite([{ input: trimmed, gravity: "centre" }])
      .jpeg({ quality: 86, mozjpeg: true })
      .toFile(file);
    console.log(`+ ${name}.jpg  (from ${meta.width}x${meta.height})`);
    saved++;
  } catch (err) {
    console.error(`! ${name}: ${err.message}`);
    failed.push(name);
  }
}
console.log(`\nSaved ${saved}, kept ${skipped} existing, failed ${failed.length}.`);
if (failed.length) process.exitCode = 1;
