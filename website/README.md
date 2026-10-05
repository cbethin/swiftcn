# swiftcn documentation

This site uses Fumadocs, Next.js, MDX, and Motion. It exports static HTML and a local search index. Search requires no external service.

## Run locally

Use Node.js 22 or later:

```bash
cd website
npm ci
npm run dev
```

Open http://localhost:3000.

## Verify the production site

```bash
npm run types:check
npm run build
npm run check:export
npm run start -- --listen 3100
```

Open http://localhost:3100. Verify search against the static production output.

## Edit content

Write guides in `content/docs/*.mdx`. Update `content/docs/meta.json` to change navigation. The index includes page text and section headings.

Use `components/landing.tsx` for the landing page and `app/global.css` for appearance. Motion respects the user's Reduce Motion preference.

Native screenshots live in `public/native`. Regenerate them from the SwiftUI catalog before replacing them:

```bash
swift run --package-path ../Examples/Catalog SwiftCNCatalog --render ../artifacts
```

Copy the reviewed light and dark exports into `public/native`. The interactive landing card is a web illustration. The gallery and guide captures come from the native app.

## GitHub Pages

The documentation workflow publishes `out/` to https://cbethin.github.io/swiftcn/ after a successful main-branch build. Pull requests only build and verify the site.

Set `NEXT_PUBLIC_SITE_URL` to the intended origin before building on a host. It controls social image URLs. Without it, local previews use http://localhost:3100.

`/search-index.json` serves the exported search index. Image, search, and Markdown download URLs use the configured base path.

The workflow builds and checks this output on documentation changes. It uploads the static site for review. The deploy job uses GitHub Pages with its deployment environment.

To verify the GitHub project path locally:

```bash
NEXT_PUBLIC_BASE_PATH=/swiftcn NEXT_PUBLIC_SITE_URL=https://cbethin.github.io npm run build
NEXT_PUBLIC_BASE_PATH=/swiftcn npm run check:export
```

The base path is a build-time setting. Rebuild without that variable to return to a root-path local preview.
