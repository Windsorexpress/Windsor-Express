// ============================================================
//  Shared product data helpers — used by build-products.mjs
//  and build-merchant-feed.mjs so the website and the Google
//  feed can never disagree with each other.
// ============================================================

export const SITE = "https://www.windsor-express.co.uk";
export const SUPABASE_URL = "https://hqjnhwkkqctuymvzzszy.supabase.co";
// Publishable (anon) key — read-only under RLS, safe to ship in a public repo.
export const SUPABASE_KEY = "sb_publishable_mbRgGL97wHJVQhYDBFJhmQ_63dFxWMH";

export const BUSINESS = {
  name: "Windsor Express",
  street: "Queen Annes Court, 3 Peascod Street",
  city: "Windsor",
  postcode: "SL4 1DG",
  country: "GB",
  phone: "+447912150397"
};

/**
 * Store code for the Peascod Street shop, used by the local inventory feed
 * that powers free local listings ("in stock nearby" on Search and Maps).
 *
 * This is the shop code Google assigned to the verified "Windsor Express -
 * Mobile Phone Repair & Vape" location, as shown in Business Profile Manager
 * at business.google.com/locations. It must match exactly or Merchant Center
 * rejects every row, so do not edit it unless that shop code changes.
 */
export const STORE_CODE = "11126744882028006931";

// Postage matches the fee used at checkout (POSTAGE_FEE in create-checkout).
export const POSTAGE_FEE = 4.99;
export const WARRANTY_MONTHS = 36;

// --- Supabase REST ------------------------------------------------------

async function sb(pathAndQuery) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${pathAndQuery}`, {
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` }
  });
  if (!res.ok) throw new Error(`Supabase ${res.status}: ${await res.text()}`);
  return res.json();
}

/**
 * Offline fixtures for local development and testing.
 * Set FIXTURES=scripts/fixtures to build pages without network access —
 * useful for previewing markup changes. CI and production always use live data.
 */
async function fromFixture(name) {
  if (!process.env.FIXTURES) return null;
  const { readFileSync, existsSync } = await import("node:fs");
  const file = `${process.env.FIXTURES}/${name}.json`;
  if (!existsSync(file)) return null;
  console.log(`(using fixture ${file})`);
  return JSON.parse(readFileSync(file, "utf8"));
}

export async function fetchPhones() {
  return (await fromFixture("phones")) ?? sb("phones?select=*&order=price.asc");
}

export async function fetchApprovedReviews() {
  const fixture = await fromFixture("product_reviews");
  if (fixture) return fixture.filter((r) => r.approved);
  // RLS already restricts anon reads to approved rows; the filter is belt-and-braces.
  try {
    return await sb("product_reviews?select=*&approved=is.true&order=created_at.desc");
  } catch {
    return []; // table may not exist yet on a fresh environment
  }
}

// --- Derived fields ----------------------------------------------------

export const slugify = (s) =>
  String(s).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");

export function slugFor(phone) {
  if (phone.slug) return phone.slug;
  return slugify([phone.name, phone.storage, phone.color].filter(Boolean).join(" "));
}

export function modelKeyFor(phone) {
  if (phone.model_key) return phone.model_key;
  return slugify([phone.name, phone.storage].filter(Boolean).join(" "));
}

export function brandFor(phone) {
  const n = String(phone.name || "").toLowerCase();
  if (n.includes("iphone") || n.includes("ipad")) return "Apple";
  if (n.includes("samsung") || n.includes("galaxy")) return "Samsung";
  if (n.includes("pixel")) return "Google";
  return "Windsor Express";
}

export function titleFor(phone) {
  return [phone.name, phone.storage, phone.color].filter(Boolean).join(" ");
}

export function pricingFor(phone) {
  const regular = Number(phone.price || 0);
  const candidate = Number(phone.sale_price);
  const onSale = Number.isFinite(candidate) && candidate > 0 && candidate < regular;
  const current = onSale ? candidate : regular;
  return {
    regular,
    current,
    onSale,
    saving: onSale ? regular - current : 0,
    percent: onSale && regular ? Math.round((1 - current / regular) * 100) : 0
  };
}

export const inStock = (phone) => Number(phone.stock || 0) > 0;

/** schema.org condition URL */
export function schemaCondition(phone) {
  if (phone.condition === "New") return "https://schema.org/NewCondition";
  if (phone.professionally_refurbished) return "https://schema.org/RefurbishedCondition";
  return "https://schema.org/UsedCondition";
}

/** Merchant Center `condition` attribute: new | refurbished | used */
export function feedCondition(phone) {
  if (phone.condition === "New") return "new";
  if (phone.professionally_refurbished) return "refurbished";
  return "used";
}

/** Plain-English explanation of each condition grade shown on the page. */
export const CONDITION_COPY = {
  New: "Brand new and sealed, exactly as it left the manufacturer.",
  "Like New": "Practically indistinguishable from new. No visible scratches or marks under normal light.",
  Excellent: "Light signs of previous use that are hard to spot at arm's length. Screen and body free from cracks or dents.",
  Good: "Visible minor marks or light scratches from everyday use. Fully functional with no cracks.",
  Fair: "Clear cosmetic wear such as deeper scratches or small dents. Works exactly as it should."
};

// --- Structured data building blocks ----------------------------------

/**
 * Return policy mirrors returns.html: 14 days to notify, 14 further days to
 * return, buyer covers change-of-mind postage.
 */
export const RETURN_POLICY = {
  "@type": "MerchantReturnPolicy",
  applicableCountry: "GB",
  returnPolicyCategory: "https://schema.org/MerchantReturnFiniteReturnWindow",
  merchantReturnDays: 14,
  returnMethod: "https://schema.org/ReturnByMail",
  returnFees: "https://schema.org/ReturnShippingFees",
  returnShippingFeesAmount: {
    "@type": "MonetaryAmount",
    currency: "GBP",
    value: 0,
    description: "Buyer arranges and pays for return postage on change-of-mind returns. We cover reasonable return costs for faulty, incorrect or misdescribed goods."
  },
  refundType: "https://schema.org/FullRefund"
};

/** Tracked UK delivery, plus free collection in store. */
export const SHIPPING_DETAILS = [
  {
    "@type": "OfferShippingDetails",
    shippingRate: {
      "@type": "MonetaryAmount",
      value: POSTAGE_FEE.toFixed(2),
      currency: "GBP"
    },
    shippingDestination: {
      "@type": "DefinedRegion",
      addressCountry: "GB"
    },
    deliveryTime: {
      "@type": "ShippingDeliveryTime",
      handlingTime: { "@type": "QuantitativeValue", minValue: 0, maxValue: 1, unitCode: "DAY" },
      transitTime: { "@type": "QuantitativeValue", minValue: 1, maxValue: 3, unitCode: "DAY" }
    }
  },
  {
    "@type": "OfferShippingDetails",
    shippingRate: { "@type": "MonetaryAmount", value: "0.00", currency: "GBP" },
    shippingDestination: { "@type": "DefinedRegion", addressCountry: "GB" },
    deliveryTime: {
      "@type": "ShippingDeliveryTime",
      handlingTime: { "@type": "QuantitativeValue", minValue: 0, maxValue: 1, unitCode: "DAY" },
      transitTime: { "@type": "QuantitativeValue", minValue: 0, maxValue: 0, unitCode: "DAY" }
    },
    description: "Free click & collect from our Peascod Street shop in Windsor."
  }
];

/** GTIN property name for the digit length supplied. */
export function gtinProp(gtin) {
  const g = String(gtin || "").trim();
  if (!/^\d+$/.test(g)) return null;
  if (g.length === 8) return "gtin8";
  if (g.length === 12) return "gtin12";
  if (g.length === 13) return "gtin13";
  if (g.length === 14) return "gtin14";
  return null;
}

/**
 * Identifier block. Google wants a global identifier; we supply whatever is
 * genuinely known and never invent one.
 */
export function identifiers(phone) {
  const out = { sku: phone.id, brand: { "@type": "Brand", name: brandFor(phone) } };
  const prop = gtinProp(phone.gtin);
  if (prop) out[prop] = String(phone.gtin).trim();
  if (phone.mpn) out.mpn = String(phone.mpn).trim();
  return out;
}

/** Price valid until end of next month — keeps merchant listings fresh. */
export function priceValidUntil() {
  const d = new Date();
  d.setMonth(d.getMonth() + 2, 0);
  return d.toISOString().slice(0, 10);
}

export const escapeHtml = (s) =>
  String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");

/** JSON-LD is escaped so a stray </script> in data can't break out. */
export const jsonLd = (obj) => JSON.stringify(obj, null, 2).replace(/</g, "\\u003c");
