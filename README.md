# Windsor Express website

Static GitHub Pages website for [windsor-express.co.uk](https://www.windsor-express.co.uk/).

## Editing the homepage

- `index.html` contains metadata, structured data and the page shell.
- `src/app.jsx` contains the React booking, shop and trade-in interface.
- `src/tailwind.css` and `tailwind.config.cjs` generate the homepage utility CSS.
- `site-common.js` and `site-common.css` provide analytics consent across public pages.
- `app.js` and `site.css` are generated production files and must be rebuilt after source changes.

Install dependencies and rebuild:

```text
npm install
npm run build
```

Commit both the source files and generated `app.js` / `site.css` so GitHub Pages can serve them directly.

## Hosting

GitHub Pages publishes the root of the `main` branch. `CNAME` configures `www.windsor-express.co.uk`.

## Backend

The public pages call Supabase for phone stock, repair prices, bookings, orders and server functions. Supabase database migrations, row-level security policies and Edge Function source are maintained separately and are not currently stored in this repository.
