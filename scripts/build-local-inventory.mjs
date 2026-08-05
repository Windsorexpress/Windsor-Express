// ============================================================
//  build-local-inventory.mjs
//  Writes /local-inventory.xml — the local product inventory feed
//  that powers free LOCAL listings ("in stock nearby" on Google
//  Search and Maps) for the Peascod Street shop.
//
//  This is a SECOND, separate data source in Merchant Center:
//    Products -> Data sources -> Add -> Local product inventory
//    URL: https://www.windsor-express.co.uk/local-inventory.xml
//
//  Each g:id here must match a g:id in merchant-feed.xml, and
//  STORE_CODE must match the store code on the Windsor Express
//  location in Google Business Profile Manager.
//
//  Run:  npm run build:local
// ============================================================

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  STORE_CODE, fetchPhones, titleFor, pricingFor, inStock, escapeHtml
} from "./product-data.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const phones = await fetchPhones();
const live = phones.filter(inStock);

function itemXml(phone) {
  const p = pricingFor(phone);
  const qty = Math.max(0, Number(phone.stock || 0));
  const rows = [
    ["g:store_code", STORE_CODE],
    ["g:id", phone.id],
    ["g:quantity", String(qty)],
    ["g:availability", qty > 0 ? "in_stock" : "out_of_stock"],
    ["g:price", `${p.current.toFixed(2)} GBP`],
    // Collection from the shop counter, ready the same day.
    ["g:pickup_method", "buy"],
    ["g:pickup_sla", "same_day"]
  ];
  return `    <item>\n${rows
    .map(([k, v]) => `      <${k}>${escapeHtml(v)}</${k}>`)
    .join("\n")}\n    </item>`;
}

function renderXml(lastBuildDate) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">
  <channel>
    <title>Windsor Express — local shop inventory</title>
    <link>https://www.windsor-express.co.uk/phones-for-sale-windsor.html</link>
    <description>Stock physically available to collect at Windsor Express, 3 Peascod Street, Windsor SL4 1DG.</description>
    <lastBuildDate>${lastBuildDate}</lastBuildDate>
${live.map(itemXml).join("\n")}
  </channel>
</rss>
`;
}

const outputFile = path.join(root, "local-inventory.xml");
const previousXml = fs.existsSync(outputFile) ? fs.readFileSync(outputFile, "utf8") : "";
const previousDate = previousXml.match(/<lastBuildDate>([^<]+)<\/lastBuildDate>/)?.[1];
const unchanged = previousDate
  && !Number.isNaN(Date.parse(previousDate))
  && previousXml === renderXml(previousDate);
const xml = unchanged ? previousXml : renderXml(new Date().toUTCString());

if (xml !== previousXml) {
  fs.writeFileSync(outputFile, xml);
  console.log(`Wrote local-inventory.xml with ${live.length} item(s) for store "${STORE_CODE}".`);
} else {
  console.log(`local-inventory.xml unchanged (${live.length} item(s), store "${STORE_CODE}").`);
}
for (const p of live) console.log(`  - ${titleFor(p)} (qty ${p.stock})`);
console.log(
  `\nStore code used: ${STORE_CODE}\n` +
  "This must match the store code on the Windsor Express location in Google\n" +
  "Business Profile Manager exactly, or Merchant Center will reject these rows."
);
