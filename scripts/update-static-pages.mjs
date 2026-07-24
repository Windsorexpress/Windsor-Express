import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const pages = fs.readdirSync(root)
  .filter((name) => name.endsWith(".html"))
  .filter((name) => !["index.html", "admin.html", "connection-test.html", "privacy.html", "terms.html", "returns.html", "warranty.html"].includes(name));

const analyticsPatterns = [
  /<script async src="https:\/\/www\.googletagmanager\.com\/gtag\/js\?id=G-3ZJFVJ5NDH"><\/script>\s*<script>window\.dataLayer=window\.dataLayer\|\|\[\];function gtag\(\)\{dataLayer\.push\(arguments\);\}gtag\('js',new Date\(\)\);gtag\('config','G-3ZJFVJ5NDH'\);<\/script>\s*/g,
  /<!-- Google tag \(gtag\.js\) -->[\s\S]*?gtag\('config', 'G-3ZJFVJ5NDH'\);\s*<\/script>\s*/g
];

const commonHead = [
  '<link rel="stylesheet" href="/site-common.css">',
  '<script src="/site-common.js" defer></script>'
].join("\n");

const legalLinks = '<p><a href="/privacy.html">Privacy &amp; cookies</a> · <a href="/terms.html">Terms</a> · <a href="/returns.html">Returns</a> · <a href="/warranty.html">Warranty</a> · <button type="button" data-cookie-settings style="border:0;background:none;color:inherit;text-decoration:underline;cursor:pointer;font:inherit">Cookie settings</button></p>';

for (const name of pages) {
  const fullPath = path.join(root, name);
  let html = fs.readFileSync(fullPath, "utf8");
  for (const pattern of analyticsPatterns) html = html.replace(pattern, "");
  if (!html.includes("/site-common.css")) html = html.replace("</head>", `${commonHead}\n</head>`);
  if (!html.includes('href="/privacy.html"')) {
    html = html.replace(/(<footer><div class="wrap">)/, `$1\n${legalLinks}`);
  }
  fs.writeFileSync(fullPath, html);
}

console.log(`Updated ${pages.length} static pages.`);
