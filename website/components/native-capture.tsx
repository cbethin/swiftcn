import { sitePath } from '@/lib/site-path';

export function NativeCapture({ name, alt, platform = 'macOS' }: { name: string; alt: string; platform?: 'macOS' | 'iOS' }) {
  return <figure className="native-capture" data-platform={platform}>
    <picture>
      <img className="capture-light" src={sitePath(`/native/${name}-light.png`)} alt={alt} loading="lazy" />
      <img className="capture-dark" src={sitePath(`/native/${name}-dark.png`)} alt={`${alt} Dark appearance.`} loading="lazy" />
    </picture>
    <figcaption>Captured from the native SwiftUI catalog on {platform}.</figcaption>
  </figure>;
}
