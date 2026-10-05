// Next.js prefixes router links; fetch URLs and plain image sources need this helper.
export const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

export function sitePath(path: string): string {
  return `${basePath}${path}`;
}
