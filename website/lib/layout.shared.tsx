import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { sitePath } from './site-path';
import { appName, gitConfig } from './shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: <span className="brand"><span className="brand-symbol" aria-hidden="true"><img className="bird-mark" src={sitePath('/brand/swiftcn-bird-v1.png')} alt="" width={44} height={44} /></span>{appName}<span className="brand-version">early preview</span></span>,
    },
    links: [{ text: 'Documentation', url: '/docs' }, { text: 'Utilities', url: '/docs/utilities' }],
    githubUrl: `https://github.com/${gitConfig.user}/${gitConfig.repo}`,
  };
}
