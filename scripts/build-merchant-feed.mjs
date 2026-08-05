// ============================================================
//  build-merchant-feed.mjs
//  Writes /merchant-feed.xml — a Google Merchant Center product
//  feed (RSS 2.0 + Google namespace) for free Shopping listings
//  and free local "in stock nearby" listings.
//
//  Point Merchant Center at:
//    https://www.windsor-express.co.uk/merchant-feed.xml
//
//  Run:  npm run build:feed
// ============================================================

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  SITE, POSTAGE_FEE, WARRANTY_MONTHS,
  fetchPhones, slugFor, brandFor, titleFor, pricingFor, inStock,
  feedCondition, gtinProp, escapeHtml
} from "./product-data.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const phones = await fetchPhones();
const live = phones.filter(inStock);

function itemXml(phone) {
  const p = pricingFor(phone);
  const slug = slugFor(phone);
  const brand = brandFor(phone);
  const link = `${SITE}/phones/${slug}/`;

  const description = [
    `${titleFor(phone)} for sale at Windsor Express in Windsor.`,
    phone.condition ? `Condition: ${phone.condition}.` : "",
    phone.battery_health ? `Battery health ${phone.battery_health}%.` : "",
    phone.description || "",
    `Unlocked to all networks. ${WARRANTY_MONTHS / 12}-year warranty.`,
    "Free click & collect from Peascod Street, or tracked UK delivery."
  ].filter(Boolean).join(" ").replace(/\s+/g, " ").trim();

  const rows = [
    ["g:id", phone.id],
    ["g:title", titleFor(phone)],
    ["g:description", description],
    ["g:link", link],
    ["g:image_link", phone.image_url || ""],
    ["g:availability", "in_stock"],
    ["g:price", `${p.current.toFixed(2)} GBP`],
    ["g:brand", brand],
    ["g:condition", feedCondition(phone)],
    ["g:identifier_exists", phone.gtin || phone.mpn ? "yes" : "no"],
    ["g:google_product_category", "222"], // Electronics > Communications > Telephony > Mobile Phones
    ["g:product_type", "Mobile Phones"],
    ["g:item_group_id", phone.model_key || ""],
    // Physical shop: enables free local listings once the Business Profile is linked.
    ["g:pickup_method", "buy"],
    ["g:pickup_sla", "same_day"]
  ];

  // Sale pricing is expressed as price + sale_price so Shopping shows the discount.
  if (p.onSale) {
    rows[6] = ["g:price", `${p.regular.toFixed(2)} GBP`];
    rows.splice(7, 0, ["g:sale_price", `${p.current.toFixed(2)} GBP`]);
  }

  const prop = gtinProp(phone.gtin);
  if (prop) rows.push(["g:gtin", String(phone.gtin).trim()]);
  if (phone.mpn) rows.push(["g:mpn", String(phone.mpn).trim()]);
  if (phone.color) rows.push(["g:color", phone.color]);

  const simple = rows
    .filter(([, v]) => v !== "" && v != null)
    .map(([k, v]) => `      <${k}>${escapeHtml(v)}</${k}>`)
    .join("\n");

  // pickup_cost is mandatory for UK merchants offering collection from 30 Sep 2026.
  const shipping = `      <g:shipping>
        <g:country>GB</g:country>
        <g:service>Tracked UK delivery</g:service>
        <g:price>${POSTAGE_FEE.toFixed(2)} GBP</g:price>
      </g:shipping>
      <g:pickup_cost>0.00 GBP</g:pickup_cost>`;

  return `    <item>\n${simple}\n${shipping}\n    </item>`;
}

function renderXml(lastBuildDate) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">
  <channel>
    <title>Windsor Express — Phones for Sale in Windsor</title>
    <link>${SITE}/phones-for-sale-windsor.html</link>
    <description>Live stock of unlocked phones for sale at Windsor Express, Peascod Street, Windsor.</description>
    <lastBuildDate>${lastBuildDate}</lastBuildDate>
${live.map(itemXml).join("\n")}
  </channel>
</rss>
`;
}

const outputFile = path.join(root, "merchant-feed.xml");
const previousXml = fs.existsSync(outputFile) ? fs.readFileSync(outputFile, "utf8") : "";
const previousDate = previousXml.match(/<lastBuildDate>([^<]+)<\/lastBuildDate>/)?.[1];
const unchanged = previousDate
  && !Number.isNaN(Date.parse(previousDate))
  && previousXml === renderXml(previousDate);
const xml = unchanged ? previousXml : renderXml(new Date().toUTCString());

if (xml !== previousXml) {
  fs.writeFileSync(outputFile, xml);
  console.log(`Wrote merchant-feed.xml with ${live.length} in-stock item(s).`);
} else {
  console.log(`merchant-feed.xml unchanged (${live.length} in-stock item(s)).`);
}

const noId = live.filter((p) => !p.gtin && !p.mpn);
if (noId.length) {
  console.log(`\n${noId.length} item(s) sent with identifier_exists=no (no GTIN or MPN):`);
  for (const p of noId) console.log(`  - ${titleFor(p)}`);
  console.log("These may be limited in Shopping. Add the box barcode as GTIN where you have it.");
}
const noImage = live.filter((p) => !p.image_url);
if (noImage.length) {
  console.log(`\n${noImage.length} item(s) have no image and will be REJECTED by Merchant Center:`);
  for (const p of noImage) console.log(`  - ${titleFor(p)}`);
}

// Images borrowed from other retailers are a policy and copyright problem, and
// Google Shopping thumbnails are too small and often blocked to hotlinkers.
const FOREIGN_IMAGE_HOSTS = [
  "gstatic.com", "googleusercontent.com", "backmarket", "currys",
  "bsimg.nl", "amazon.", "ebay.", "argos.", "very.co.uk", "o2.co.uk", "ee.co.uk"
];
const borrowed = live.filter((p) =>
  p.image_url && FOREIGN_IMAGE_HOSTS.some((h) => String(p.image_url).toLowerCase().includes(h)));
if (borrowed.length) {
  console.log(`\n!! ${borrowed.length} item(s) use a photo hosted by someone else:`);
  for (const p of borrowed) console.log(`  - ${titleFor(p)}  ->  ${String(p.image_url).slice(0, 70)}…`);
  console.log(
    "\nThese need replacing with your own photographs of the actual handset:\n" +
    "  * Merchant Center expects the image to show the item you are really selling.\n" +
    "  * Another shop's product photography is their copyright, not yours.\n" +
    "  * Google Shopping thumbnail links are low-resolution and often block hotlinking,\n" +
    "    so the listing can be rejected or show a broken image.\n" +
    "  A phone photo on a plain background, at least 800x800, is enough."
  );
}
