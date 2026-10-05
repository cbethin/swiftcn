import { llms, loader } from 'fumadocs-core/source';
import { docsRoute } from './shared';
import { sitePath } from './site-path';
import { defineDocs } from 'fumadocs-mdx/macro';
import { metaSchema, pageSchema } from 'fumadocs-core/source/schema';

const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: pageSchema,
    postprocess: {
      includeProcessedMarkdown: true,
    },
  },
  meta: {
    schema: metaSchema,
  },
});

// See https://fumadocs.dev/docs/headless/source-api for more info
export const source = loader({
  baseUrl: docsRoute,
  source: docs.toFumadocsSource(),
  plugins: [],
});

// Plain Markdown URLs do not pass through the Next.js router.
const markdownSource = loader({
  baseUrl: sitePath(docsRoute),
  source: docs.toFumadocsSource(),
});

export const docsLlms = llms(markdownSource, {
  renderPage: async (page) => {
    const url = sitePath([docsRoute, ...page.slugs].join('/'));
    const markdown = (await page.data.getText('processed')).replace(
      /\]\((\/docs(?=[/#)]))/g,
      (_, path: string) => `](${sitePath(path)}`,
    );
    return `# ${page.data.title} (${url})\n\n${markdown}`;
  },
});
