// ============================================================
//  build-products.mjs
//  Generates one real, indexable page per phone in stock:
//    /phones/<slug>/index.html
//  plus the /phones/ hub, and refreshes sitemap.xml.
//
//  Run:  npm run build:products
//  Pages are committed to the repo so GitHub Pages serves static
//  HTML — no JavaScript needed for Google to read the product.
// ============================================================

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  SITE, BUSINESS, POSTAGE_FEE, WARRANTY_MONTHS,
  fetchPhones, fetchApprovedReviews,
  slugFor, modelKeyFor, brandFor, titleFor, pricingFor, inStock,
  schemaCondition, CONDITION_COPY, RETURN_POLICY, SHIPPING_DETAILS,
  identifiers, priceValidUntil, escapeHtml, jsonLd
} from "./product-data.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outDir = path.join(root, "phones");

const money = (n) => `£${Number(n).toFixed(2)}`;

// --- head / chrome shared with the rest of the site --------------------

function head({ title, description, canonical, image, schema, noindex }) {
  return `<!DOCTYPE html>
<html lang="en-GB">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${escapeHtml(title)}</title>
<meta name="description" content="${escapeHtml(description)}">
<link rel="canonical" href="${canonical}">
<meta name="robots" content="${noindex ? "noindex, follow" : "index, follow, max-image-preview:large"}">
<link rel="icon" type="image/png" href="/favicon.png">
<meta property="og:site_name" content="Windsor Express">
<meta property="og:title" content="${escapeHtml(title)}">
<meta property="og:description" content="${escapeHtml(description)}">
<meta property="og:type" content="website">
<meta property="og:locale" content="en_GB">
<meta property="og:url" content="${canonical}">
<meta property="og:image" content="${image || SITE + "/og-image.jpg"}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${escapeHtml(title)}">
<meta name="twitter:description" content="${escapeHtml(description)}">
<meta name="twitter:image" content="${image || SITE + "/og-image.jpg"}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@700;800;900&family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/phone-shop-base.css">
<link rel="stylesheet" href="/phone-shop.css">
<link rel="stylesheet" href="/site-common.css">
<script src="/site-common.js" defer></script>
${schema.map((s) => `<script type="application/ld+json">\n${jsonLd(s)}\n</script>`).join("\n")}
</head>
<body>
<div class="announcement">Free click &amp; collect in Windsor <span>&middot;</span> Tracked UK delivery <span>&middot;</span> 3-year warranty</div>
<header>
  <div class="wrap nav">
    <a class="logo" href="/">WINDSOR <span>EXPRESS</span></a>
    <nav class="navlinks" aria-label="Main navigation">
      <a href="/">Repairs</a>
      <a href="/sell-my-phone-windsor.html">Sell / Trade-In</a>
      <a class="nav-cta" href="/phones-for-sale-windsor.html">See Live Stock</a>
    </nav>
  </div>
</header>`;
}

const footer = `<footer><div class="wrap">
<p><a href="/privacy.html">Privacy &amp; cookies</a> · <a href="/terms.html">Terms</a> · <a href="/returns.html">Returns</a> · <a href="/warranty.html">Warranty</a> · <button type="button" data-cookie-settings style="border:0;background:none;color:inherit;text-decoration:underline;cursor:pointer;font:inherit">Cookie settings</button></p>
<p><a href="/">Windsor Express</a> · ${BUSINESS.street}, ${BUSINESS.city} ${BUSINESS.postcode}<br>
<a href="tel:${BUSINESS.phone}">07912 150397</a> · Mon–Sat 10am–8pm · Sun 10:30am–7pm</p>
<p>Serving Windsor, Eton, Datchet, Old Windsor, Slough, Maidenhead, Ascot, Staines-upon-Thames, Egham, Virginia Water &amp; Wraysbury · <a href="/areas-we-cover.html">All areas we cover</a></p>
</div></footer>
</body>
</html>`;

function breadcrumbs(phone, canonical) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Windsor Express", item: SITE + "/" },
      { "@type": "ListItem", position: 2, name: "Phones for Sale in Windsor", item: SITE + "/phones-for-sale-windsor.html" },
      { "@type": "ListItem", position: 3, name: titleFor(phone), item: canonical }
    ]
  };
}

// --- Product schema ----------------------------------------------------

function productSchema(phone, canonical, reviews) {
  const p = pricingFor(phone);
  const available = inStock(phone);

  const schema = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: titleFor(phone),
    description: descriptionFor(phone),
    ...identifiers(phone),
    itemCondition: schemaCondition(phone),
    ...(phone.color ? { color: phone.color } : {}),
    ...(phone.image_url ? { image: [phone.image_url] } : {}),
    offers: {
      "@type": "Offer",
      "@id": canonical + "#offer",
      url: canonical,
      priceCurrency: "GBP",
      price: p.current.toFixed(2),
      priceValidUntil: priceValidUntil(),
      itemCondition: schemaCondition(phone),
      availability: available ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
      availableAtOrFrom: { "@id": SITE + "/#business" },
      seller: { "@id": SITE + "/#business" },
      hasMerchantReturnPolicy: RETURN_POLICY,
      shippingDetails: SHIPPING_DETAILS
    }
  };

  // Reviews and ratings are included ONLY when genuine, approved, first-party
  // reviews exist. Never populate these from a manufacturer or another site —
  // Google requires that a merchant collects and owns the reviews it marks up.
  if (reviews.length) {
    const avg = reviews.reduce((t, r) => t + Number(r.rating), 0) / reviews.length;
    schema.aggregateRating = {
      "@type": "AggregateRating",
      ratingValue: Math.round(avg * 10) / 10,
      reviewCount: reviews.length,
      bestRating: 5,
      worstRating: 1
    };
    schema.review = reviews.slice(0, 10).map((r) => ({
      "@type": "Review",
      reviewRating: { "@type": "Rating", ratingValue: Number(r.rating), bestRating: 5, worstRating: 1 },
      author: { "@type": "Person", name: r.reviewer_name },
      datePublished: (r.published_at || r.created_at || "").slice(0, 10),
      ...(r.title ? { name: r.title } : {}),
      ...(r.body ? { reviewBody: r.body } : {})
    }));
  }

  return schema;
}

function descriptionFor(phone) {
  const p = pricingFor(phone);
  const bits = [
    `${titleFor(phone)} for sale in Windsor at ${money(p.current)}.`,
    phone.condition ? `Condition: ${phone.condition}.` : "",
    phone.battery_health ? `Battery health ${phone.battery_health}%.` : "",
    "Unlocked to all networks,",
    `${WARRANTY_MONTHS / 12}-year Windsor Express warranty,`,
    "free click & collect from Peascod Street or tracked UK delivery."
  ];
  return bits.filter(Boolean).join(" ").replace(/\s+/g, " ");
}

// --- Product page ------------------------------------------------------

function productPage(phone, reviews, others) {
  const slug = slugFor(phone);
  const canonical = `${SITE}/phones/${slug}/`;
  const p = pricingFor(phone);
  const available = inStock(phone);
  const brand = brandFor(phone);
  const title = titleFor(phone);
  const conditionCopy = CONDITION_COPY[phone.condition] || "";

  const pageTitle = available
    ? `${title} — ${money(p.current)} | Windsor Express`
    : `${title} — Sold | Windsor Express`;

  const avg = reviews.length
    ? Math.round((reviews.reduce((t, r) => t + Number(r.rating), 0) / reviews.length) * 10) / 10
    : null;

  const specRows = [
    ["Model", title],
    ["Brand", brand],
    ["Storage", phone.storage],
    ["Colour", phone.color],
    ["Condition", phone.condition],
    phone.battery_health ? ["Battery health", `${phone.battery_health}%`] : null,
    ["Network", "Unlocked to all networks"],
    phone.software_version ? ["Software", phone.software_version] : null,
    phone.software_support ? ["Software support", phone.software_support] : null,
    ["Warranty", `${WARRANTY_MONTHS} months, Windsor Express`],
    phone.gtin ? ["Barcode (GTIN)", phone.gtin] : null,
    phone.mpn ? ["Part number", phone.mpn] : null
  ].filter(Boolean);

  return `${head({
    title: pageTitle,
    description: descriptionFor(phone),
    canonical,
    image: phone.image_url,
    schema: [productSchema(phone, canonical, reviews), breadcrumbs(phone, canonical)]
  })}

<main class="wrap product-page">
  <nav class="crumbs" aria-label="Breadcrumb">
    <a href="/">Home</a> › <a href="/phones-for-sale-windsor.html">Phones for sale</a> › <span>${escapeHtml(title)}</span>
  </nav>

  <div class="product-grid">
    <div class="product-media">
      ${phone.image_url
        ? `<img src="${escapeHtml(phone.image_url)}" alt="${escapeHtml(title)} for sale at Windsor Express in Windsor" width="520" height="520" loading="eager">`
        : `<div class="product-media-placeholder" role="img" aria-label="Photo coming soon">Photo coming soon</div>`}
    </div>

    <div class="product-info">
      <h1>${escapeHtml(title)}</h1>

      <div class="badges">
        ${phone.condition ? `<span class="badge badge-condition">${escapeHtml(phone.condition)}</span>` : ""}
        ${phone.storage ? `<span class="badge">${escapeHtml(phone.storage)}</span>` : ""}
        ${phone.color ? `<span class="badge">${escapeHtml(phone.color)}</span>` : ""}
        ${phone.professionally_refurbished ? `<span class="badge badge-refurb">Professionally refurbished</span>` : ""}
      </div>

      ${avg ? `<p class="rating-line"><strong>${avg}/5</strong> from ${reviews.length} Windsor Express customer review${reviews.length === 1 ? "" : "s"}</p>` : ""}

      <div class="price-block">
        ${p.onSale
          ? `<span class="price">${money(p.current)}</span> <span class="price-was">${money(p.regular)}</span> <span class="price-save">Save ${money(p.saving)} (${p.percent}%)</span>`
          : `<span class="price">${money(p.current)}</span>`}
        <span class="price-note">One-off payment · no contract</span>
      </div>

      ${available
        ? `<a class="buy-btn" href="/?phone=${encodeURIComponent(phone.id)}">Reserve or buy this ${escapeHtml(brand)} →</a>
           <p class="stock-line in">In stock now at our Peascod Street shop</p>`
        : `<p class="stock-line out"><strong>Now sold.</strong> This exact handset has gone — but our stock changes weekly.</p>
           <a class="buy-btn" href="/phones-for-sale-windsor.html">See what's in stock today →</a>`}

      <ul class="trust-list">
        <li>Unlocked to all networks</li>
        <li>${WARRANTY_MONTHS / 12}-year Windsor Express warranty</li>
        <li>14-day change-of-mind returns on online orders</li>
        <li>Professionally checked, wiped and tested before sale</li>
        <li>Checked against the national lost &amp; stolen database</li>
      </ul>

      ${available ? `<div class="fulfilment">
        <div class="fulfil-card">
          <span class="fulfil-label">Collect in Windsor</span>
          <span class="fulfil-price">Free</span>
          <span class="fulfil-note">Ready today on Peascod Street</span>
        </div>
        <div class="fulfil-card">
          <span class="fulfil-label">Tracked UK delivery</span>
          <span class="fulfil-price">${money(POSTAGE_FEE)}</span>
          <span class="fulfil-note">Signed for, 1–3 working days</span>
        </div>
      </div>

      <div class="ask-row">
        <a class="ask-btn" href="https://wa.me/447912150397?text=${encodeURIComponent(`Hi Windsor Express! Is the ${title} at ${money(p.current)} still available?`)}" target="_blank" rel="noopener noreferrer">Ask about this phone on WhatsApp</a>
        <a class="ask-btn" href="tel:${BUSINESS.phone}">Call 07912 150397</a>
      </div>

      <p class="trade-nudge">Got an old phone? <a href="/sell-my-phone-windsor.html">Trade it in</a> and take the value straight off this price.</p>` : ""}

      <div class="shop-note">
        <p><strong>★ 5.0 on Google</strong> · 500+ devices fixed for Windsor locals</p>
        <p>${BUSINESS.street}, ${BUSINESS.city} ${BUSINESS.postcode}<br>
        Mon–Sat 10am–8pm · Sun 10:30am–7pm · no appointment needed</p>
      </div>
    </div>
  </div>

  ${phone.description ? `<section class="product-section"><h2>About this handset</h2><p>${escapeHtml(phone.description)}</p></section>` : ""}

  ${conditionCopy ? `<section class="product-section">
    <h2>What "${escapeHtml(phone.condition)}" means</h2>
    <p>${escapeHtml(conditionCopy)}</p>
    ${phone.battery_health ? `<p>This particular handset has a measured battery health of <strong>${phone.battery_health}%</strong>. Apple considers a battery healthy above 80%, and we replace anything below that before sale.</p>` : ""}
    <p>Every grade is judged on the actual handset in front of us, not a generic description. Come and inspect it in the shop before you buy — we would rather you were sure.</p>
  </section>` : ""}

  <section class="product-section">
    <h2>Specifications</h2>
    <table class="spec-table">
      <tbody>
        ${specRows.map(([k, v]) => `<tr><th scope="row">${escapeHtml(k)}</th><td>${escapeHtml(v)}</td></tr>`).join("\n        ")}
      </tbody>
    </table>
    ${phone.software_source_url
      ? `<p class="spec-source"><a href="${escapeHtml(phone.software_source_url)}" rel="nofollow noopener" target="_blank">View the manufacturer's official specifications and support information →</a></p>`
      : ""}
  </section>

  <section class="product-section reviews" id="reviews">
    <h2>Customer reviews</h2>
    ${reviews.length
      ? `<p class="rating-summary"><strong>${avg}/5</strong> · ${reviews.length} review${reviews.length === 1 ? "" : "s"} from people who bought this model from us</p>
         <ul class="review-list">
           ${reviews.slice(0, 10).map((r) => `<li class="review">
             <div class="review-head">
               <span class="stars" aria-label="${r.rating} out of 5 stars">${"★".repeat(r.rating)}${"☆".repeat(5 - r.rating)}</span>
               <strong>${escapeHtml(r.reviewer_name)}</strong>
               ${r.verified ? `<span class="verified">Verified purchase</span>` : ""}
             </div>
             ${r.title ? `<p class="review-title">${escapeHtml(r.title)}</p>` : ""}
             ${r.body ? `<p>${escapeHtml(r.body)}</p>` : ""}
           </li>`).join("\n           ")}
         </ul>`
      : `<p>No reviews for this model yet. We only publish reviews from people who actually bought
         from Windsor Express, so this section stays empty until a real customer fills it —
         we don't borrow ratings from anywhere else.</p>`}

    <details class="review-form-wrap">
      <summary>Bought this model from us? Leave a review</summary>
      <form class="review-form" data-model-key="${escapeHtml(modelKeyFor(phone))}" data-model-label="${escapeHtml(title)}">
        <label>Your name<input name="reviewer_name" required maxlength="60" autocomplete="name"></label>
        <label>Rating
          <select name="rating" required>
            <option value="">Choose…</option>
            <option value="5">5 — Excellent</option>
            <option value="4">4 — Good</option>
            <option value="3">3 — Average</option>
            <option value="2">2 — Poor</option>
            <option value="1">1 — Bad</option>
          </select>
        </label>
        <label>Headline<input name="title" maxlength="80"></label>
        <label>Your review<textarea name="body" rows="4" maxlength="1200" required></textarea></label>
        <button type="submit">Submit review</button>
        <p class="review-form-note">Reviews are checked against our order records before they appear.</p>
      </form>
    </details>
  </section>

  ${others.length ? `<section class="product-section">
    <h2>Also in stock in Windsor</h2>
    <ul class="other-list">
      ${others.map((o) => `<li><a href="/phones/${slugFor(o)}/">${escapeHtml(titleFor(o))}</a> — ${money(pricingFor(o).current)}${o.condition ? ` · ${escapeHtml(o.condition)}` : ""}</li>`).join("\n      ")}
    </ul>
  </section>` : ""}

  <section class="product-section">
    <h2>Buying a used phone in Windsor</h2>
    <p>We are a physical shop on Peascod Street, two minutes from Windsor Castle — not a marketplace listing.
       You can hold the handset, check the screen and battery figure, and ask us anything before paying.
       Every phone is checked, wiped and sold unlocked with a ${WARRANTY_MONTHS / 12}-year warranty.</p>
    <p>Got an old phone? We take <a href="/sell-my-phone-windsor.html">trade-ins and buy phones for cash</a>,
       so the price above can come down. Cracked screen on your current handset instead?
       See <a href="/iphone-repair-windsor.html">iPhone repair</a> or <a href="/samsung-repair-windsor.html">Samsung repair</a>.</p>
  </section>
</main>

<script src="/review-form.js" defer></script>
${footer}`;
}

// --- /phones/ hub ------------------------------------------------------

function hubPage(phones) {
  const canonical = `${SITE}/phones/`;
  const live = phones.filter(inStock);
  return `${head({
    title: "All Phones for Sale in Windsor | Windsor Express",
    description: "Every phone currently for sale at Windsor Express in Windsor, with condition, battery health, storage and price shown on its own page.",
    canonical,
    schema: [{
      "@context": "https://schema.org",
      "@type": "CollectionPage",
      "@id": canonical,
      name: "Phones for sale at Windsor Express",
      url: canonical,
      isPartOf: { "@id": SITE + "/#website" },
      mainEntity: {
        "@type": "ItemList",
        numberOfItems: live.length,
        itemListElement: live.map((p, i) => ({
          "@type": "ListItem",
          position: i + 1,
          url: `${SITE}/phones/${slugFor(p)}/`,
          name: titleFor(p)
        }))
      }
    }]
  })}
<main class="wrap product-page">
  <nav class="crumbs" aria-label="Breadcrumb"><a href="/">Home</a> › <span>All phones</span></nav>
  <h1>Every phone we have in stock</h1>
  <p>${live.length} handset${live.length === 1 ? "" : "s"} available right now in Windsor. Each has its own page with condition, battery health and full detail.</p>
  <ul class="other-list">
    ${live.map((p) => `<li><a href="/phones/${slugFor(p)}/">${escapeHtml(titleFor(p))}</a> — ${money(pricingFor(p).current)}${p.condition ? ` · ${escapeHtml(p.condition)}` : ""}</li>`).join("\n    ")}
  </ul>
  <p><a href="/phones-for-sale-windsor.html">See the full shop with photos →</a></p>
</main>
${footer}`;
}

// --- sitemap -----------------------------------------------------------

function updateSitemap(phones) {
  const file = path.join(root, "sitemap.xml");
  let xml = fs.readFileSync(file, "utf8");
  const today = new Date().toISOString().slice(0, 10);

  // Remove previously generated product entries, then re-add.
  xml = xml.replace(/\s*<!-- products:start -->[\s\S]*?<!-- products:end -->/g, "");

  const entries = [
    `  <url><loc>${SITE}/phones/</loc><lastmod>${today}</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>`,
    ...phones.filter(inStock).map((p) =>
      `  <url><loc>${SITE}/phones/${slugFor(p)}/</loc><lastmod>${today}</lastmod><changefreq>weekly</changefreq><priority>0.7</priority></url>`)
  ].join("\n");

  const block = `\n  <!-- products:start -->\n${entries}\n  <!-- products:end -->`;
  xml = xml.replace("</urlset>", `${block}\n</urlset>`);
  fs.writeFileSync(file, xml);
  return phones.filter(inStock).length + 1;
}

// --- main --------------------------------------------------------------

const phones = await fetchPhones();
const allReviews = await fetchApprovedReviews();

const reviewsByModel = allReviews.reduce((acc, r) => {
  (acc[r.model_key] ||= []).push(r);
  return acc;
}, {});

fs.mkdirSync(outDir, { recursive: true });

// Pages for sold phones are kept on purpose (marked OutOfStock) so any ranking
// they earned isn't thrown away and links don't 404. Only remove directories for
// phones deleted from the database outright.
const expected = new Set(phones.map(slugFor).filter(Boolean));
for (const entry of fs.readdirSync(outDir, { withFileTypes: true })) {
  if (!entry.isDirectory() || expected.has(entry.name)) continue;
  try {
    fs.rmSync(path.join(outDir, entry.name), { recursive: true, force: true });
    console.log(`- removed /phones/${entry.name}/ (no longer in the database)`);
  } catch (err) {
    console.warn(`! could not remove /phones/${entry.name}/: ${err.code || err.message}`);
  }
}

let written = 0;
for (const phone of phones) {
  const slug = slugFor(phone);
  if (!slug) {
    console.warn(`! Skipping phone ${phone.id} — could not derive a slug`);
    continue;
  }
  const reviews = reviewsByModel[modelKeyFor(phone)] || [];
  const others = phones.filter((o) => o.id !== phone.id && inStock(o)).slice(0, 5);
  const dir = path.join(outDir, slug);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, "index.html"), productPage(phone, reviews, others));
  written++;
}

fs.writeFileSync(path.join(outDir, "index.html"), hubPage(phones));
const sitemapCount = updateSitemap(phones);

console.log(`Built ${written} product page(s) + hub. Sitemap now lists ${sitemapCount} product URL(s).`);
const missingId = phones.filter((p) => inStock(p) && !p.gtin && !p.mpn).map(titleFor);
if (missingId.length) {
  console.log(`\nNo GTIN or MPN yet for: ${missingId.join(", ")}`);
  console.log("Google Merchant Center needs a GTIN for used goods — add the barcode from the retail box, or an MPN, in the admin panel.");
}
