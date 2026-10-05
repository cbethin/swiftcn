import { readFile, readdir, stat } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import assert from 'node:assert/strict';

const root = resolve('out');
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

async function files(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  return (await Promise.all(entries.map(entry => entry.isDirectory() ? files(join(directory, entry.name)) : join(directory, entry.name)))).flat();
}
const pages = (await files(root)).filter(file => file.endsWith('.html') && !file.endsWith('404.html'));
let checked = 0;
for (const page of pages) {
  const html = await readFile(page, 'utf8');
  for (const match of html.matchAll(/(?:href|src)="([^"#]+)"/g)) {
    const link = match[1].split(/[?#]/)[0];
    if (!link.startsWith('/') || link.startsWith('//')) continue;
    assert(!basePath || link === basePath || link.startsWith(`${basePath}/`), `Unprefixed link ${link} in ${page}`);
    const target = join(root, link.slice(basePath.length));
    const exists = await Promise.any([target, `${target}.html`, join(target, 'index.html')].map(async file => {
      if (!(await stat(file)).isFile()) throw new Error('Not a file');
      return true;
    })).catch(() => false);
    assert(exists, `Missing exported link ${link} in ${page}`);
    checked++;
  }
}
const index = JSON.parse(await readFile(join(root, 'search-index.json'), 'utf8'));
const text = JSON.stringify(index).toLowerCase();
for (const term of ['shared elements', 'global rules', 'tracking', 'installation', 'quick start', 'troubleshooting', 'native modifier plugins', 'typed interpolation']) {
  assert(text.includes(term), `Missing search content: ${term}`);
}
for (const filename of ['llms.txt', 'llms-full.txt', 'llms.mdx/docs/quick-start/content.md']) {
  const markdown = await readFile(join(root, filename), 'utf8');
  assert(markdown.includes(`${basePath}/docs/quick-start`), `Missing quick-start URL in ${filename}`);
  if (basePath) {
    assert(!/\]\(\/docs(?:[/#)])/g.test(markdown), `Unprefixed Markdown link in ${filename}`);
    assert(!markdown.includes(`${basePath}${basePath}/`), `Duplicate base path in ${filename}`);
  }
}
assert(pages.length >= 12, 'Missing documentation pages');
console.log(`Verified ${pages.length} HTML pages, ${checked} local links/assets, and search content.`);
