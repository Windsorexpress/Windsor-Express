# What I need from you

Everything is built and committed. Below are the six things only you can do,
roughly in order of impact. Items 1 and 2 are the ones that actually turn
Google Shopping on.

---

## 1. Push the commit (2 minutes) — nothing is live until you do this

Your folder is now a **proper git repository** (it was previously a plain ZIP
download, which is why we couldn't push before). One commit is waiting.

1. Open **GitHub Desktop**
2. **File → Add local repository…**
3. Choose `C:\Users\tanis\Desktop\Windsor-Express-main`
4. You'll see the commit *"Add per-product pages, Google Shopping feed and
   first-party reviews"* — click **Push origin**

GitHub Pages redeploys in about a minute. Then check:

- <https://www.windsor-express.co.uk/phones/>
- <https://www.windsor-express.co.uk/phones/iphone-16-128gb-black/>
- <https://www.windsor-express.co.uk/merchant-feed.xml>

*If GitHub Desktop objects, `git push` from a terminal in that folder works too.*

---

## 2. Create the Google Merchant Center account

This is the actual gate on Shopping listings. Schema alone doesn't do it — I
can't create the account because it needs your identity and business
verification.

1. Go to <https://merchants.google.com> and sign up as **Windsor Express**
2. **Business address:** Queen Annes Court, 3 Peascod Street, Windsor SL4 1DG
3. **Verify your website** — choose the Search Console method; you already
   have Search Console on this domain, so it should verify immediately
4. **Products → Data sources → Add product source → Scheduled fetch**
   - File URL: `https://www.windsor-express.co.uk/merchant-feed.xml`
   - Fetch frequency: **Daily**
   - Country: **United Kingdom**, currency **GBP**
5. **Growth → Manage programmes → enable "Free listings"**
6. **Link your Google Business Profile** (Merchant Center → Settings → Business
   info → linked accounts). This is what unlocks **free local listings** — the
   "in stock nearby" results. For a shop on Peascod Street this is worth more
   than national Shopping, because you'll show to people already in Windsor.

Expect a review period of a few days, and expect some warnings on the first
fetch — items 3 and 4 below are what those warnings will be about.

---

## 3. Replace the product photos ⚠️ important

Right now all six listings use photos hosted by **other companies** — Google
Shopping thumbnails, BackMarket, Currys and bsimg.nl. This will cause you
problems on three fronts:

- Merchant Center expects the image to show **the item you're actually
  selling**. For second-hand goods it should be that specific handset.
- Those photos are **someone else's copyright**, not yours.
- Google Shopping thumbnail URLs are low-resolution and commonly block
  hotlinking, so listings can be **rejected or show a broken image**.

You don't need a studio. A phone photo of each handset on a plain background,
at least 800×800, uploaded somewhere you control, is enough — and for used
stock, a real photo of the real device converts *better* than a stock image,
because buyers can see what they're getting.

`npm run build:feed` prints a warning listing any borrowed images.

---

## 4. Add barcodes (GTINs) where you have the box

Google requires a **GTIN** for used and refurbished goods. It's the long number
under the barcode on the retail box — 8, 12, 13 or 14 digits.

Admin panel → **Phones for Sale** → each phone now has a
*"Google Shopping identifiers"* section. Enter the barcode in **GTIN**.

**No box?** Enter the **part number (MPN)** instead — on iPhones this is in
Settings → General → About → Model Number (e.g. `MQ4F3ZD/A`). Listings still
work without either, but they surface less often.

---

## 5. Get your first reviews

The review system is live: there's a form on every product page, submissions
land in Admin → **Reviews**, and nothing appears publicly until you approve it.
Star ratings then show on the page and become eligible in Google.

To start it off, email or text the people who've already bought phones from you
and ask for a review. Something plain works best:

> Hi [name] — hope the [phone] is treating you well. We've just added reviews
> to our website; if you've got a minute, would you mind leaving one?
> [link to that phone's page]#reviews — it genuinely helps us. Thanks, Windsor Express

Two things to keep in mind:

- **Only approve people who really bought from you.** The admin panel has a
  *"Find their order"* button that searches your orders to check. Google
  requires that a shop collects and owns the reviews it displays — this is why
  we can't lift ratings from Apple or Samsung, and why doing so risks a penalty
  that would undo the rest of this work.
- **Google Shopping needs 50 reviews** before star ratings appear there. On-page
  stars show much sooner. Treat this as a slow build.

---

## 6. Check the automation ran

I added a GitHub Action that regenerates the product pages, sitemap and feed
from live Supabase stock **every hour**, so pages never go stale when you add
or sell a phone.

After pushing, go to the repo's **Actions** tab and confirm
*"Refresh product pages & Google feed"* appears. You can run it on demand with
**Run workflow** — handy right after you list a phone. If Actions are disabled
on the repo, enable them there.

---

## Things worth knowing

**A deadline that affects you:** UK merchants offering click & collect must
supply `pickup_cost` in the feed from **30 September 2026**. Already included.

**Sold phones keep their pages.** When stock hits 0 the page stays up, switches
to "Now sold" and marks itself out-of-stock, then points at current stock. That
preserves any ranking the page earned instead of throwing a 404.

**URLs are fixed once indexed.** Editing a phone's name won't move its URL —
the slug is stored on first save deliberately. Renaming a live page's URL would
lose its ranking.

**Two Search Console warnings will remain**, and that's intentional: *missing
review* and *missing aggregateRating*. Google labels these non-critical
suggestions. They'll clear themselves as real reviews come in. Fabricating them
is the one shortcut that could get the site penalised.

**Running the build yourself:**

```bash
npm run build:products   # regenerate /phones/ pages + sitemap
npm run build:feed       # regenerate merchant-feed.xml (prints warnings)
npm run build:shop       # both
npm run build            # the homepage app bundle (app.js / site.css)
```
