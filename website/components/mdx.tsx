import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import { ComponentSourceLinks } from './component-source-links';
import { NativeCapture } from './native-capture';

export function getMDXComponents(components?: MDXComponents) {
  return {
    ...defaultMdxComponents,
    NativeCapture,
    ComponentSourceLinks,
    ...components,
  } satisfies MDXComponents;
}

export const useMDXComponents = getMDXComponents;

declare global {
  type MDXProvidedComponents = ReturnType<typeof getMDXComponents>;
}
