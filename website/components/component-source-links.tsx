import { sitePath } from '@/lib/site-path';

export function ComponentSourceLinks({ source, example }: { source?: string; example?: string }) {
  return (
    <div className="not-prose my-5 flex flex-wrap gap-3 text-sm">
      {source && <a className="rounded-lg border px-3 py-2 hover:bg-fd-accent" href={sitePath(`/registry/${source}`)} download>Download Swift source</a>}
      {example && <a className="rounded-lg border px-3 py-2 hover:bg-fd-accent" href={sitePath(`/registry/examples/${example}`)} download>Download example</a>}
      <a className="rounded-lg border px-3 py-2 hover:bg-fd-accent" href={sitePath('/registry/swiftcn-sources.zip')} download>Own the full source</a>
      <a className="rounded-lg border px-3 py-2 hover:bg-fd-accent" href={sitePath('/registry/LICENSE')}>MIT license</a>
    </div>
  );
}
