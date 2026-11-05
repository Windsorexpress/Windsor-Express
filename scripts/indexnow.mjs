// ============================================================
//  IndexNow ping — tells Bing (which feeds ChatGPT search and
//  Copilot), Yandex, Seznam and Naver that pages changed, so they
//  re-crawl within minutes instead of days. Google ignores IndexNow;
//  it reads sitemap.xml instead.
//
//  Usage:
//    node scripts/indexnow.mjs <changed file> [<changed file> ...]
//    node scripts/indexnow.mjs --all        (every URL in sitemap.xml)
//
//  File paths are repo-relative (e.g. "phones/iphone-15-128gb-black/index.html",
//  "ipad-repair-windsor.html"). Non-page files are ignored. Never fails the
//  build: a ping is best-effort.
// ============================================================

import fs from "node:fs";

const SITE = "https://www.windsor-express.co.uk";
const HOST = "www.windsor-express.co.uk";
// Public by design: IndexNow proves ownership by fetching this key from
// ${SITE}/${KEY}.txt. Rotate by replacing both this value and the file.
const KEY = "ab3e3c1020cc3fca65323e5211ec01d7";
const PRIVATE = new Set(["admin.html", "connection-test.html"]);

function urlForFile(file) {
  const f = file.replace(/^\.?\//, "");
  if (PRIVATE.has(f)) return null;
  if (f === "index.html") return `${SITE}/`;
  const phone = f.match(/^phones\/(?:([^/]+)\/)?index\.html$/);
  if (phone) return phone[1] ? `${SITE}/phones/${phone[1]}/` : `${SITE}/phones/`;
  if (/^[a-z0-9-]+\.html$/.test(f)) return `${SITE}/${f}`;
  return null;
}

function sitemapUrls() {
  const xml = fs.readFileSync(new URL("../sitemap.xml", import.meta.url), "utf8");
  return [...xml.matchAll(/<loc>\s*([^<]+?)\s*<\/loc>/g)].map((m) => m[1]);
}

const args = process.argv.slice(2);
const urls = [...new Set(args.includes("--all") ? sitemapUrls() : args.map(urlForFile).filter(Boolean))];

if (!urls.length) {
  console.log("IndexNow: no page URLs changed — nothing to ping.");
  process.exit(0);
}

if (process.env.DRY_RUN) {
  console.log(urls.join("\n"));
  process.exit(0);
}

try {
  const res = await fetch("https://api.indexnow.org/indexnow", {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: JSON.stringify({ host: HOST, key: KEY, keyLocation: `${SITE}/${KEY}.txt`, urlList: urls.slice(0, 10000) })
  });
  // 200 = accepted, 202 = accepted (key validation pending)
  console.log(`IndexNow: HTTP ${res.status} for ${urls.length} URL(s)`);
  if (res.status >= 400) console.log(await res.text());
} catch (err) {
  console.log(`IndexNow ping failed (ignored): ${err.message}`);
}
