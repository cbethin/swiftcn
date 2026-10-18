import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { docsLlms } from '@/lib/source';

export const revalidate = false;

export async function GET() {
  // The class reference is generated from the parser by `swift run swiftcn-lint --reference`.
  const classes = await readFile(path.join(process.cwd(), 'public', 'classes.md'), 'utf8');
  return new Response(`${await docsLlms.full()}\n\n${classes}`);
}
