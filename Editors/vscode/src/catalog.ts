// The swiftcn class vocabulary, generated from the parser by `swift run swiftcn-lint --catalog-json`.
import data from '../data/classes.json' with { type: 'json' };
import type { Learned } from './scanner.ts';

export interface Entry {
  name: string;
  category: string;
  description: string;
  kind?: string;
}

export interface Pattern {
  label: string;
  description: string;
  snippet: string;
  regex: string;
}

export const variants: Entry[] = data.variants;
export const classes: Entry[] = data.classes;
export const patterns: Pattern[] = data.patterns.map((pattern) => ({ ...pattern }));

const byName = new Map(classes.map((entry) => [entry.name, entry]));
const compiled = patterns.map((pattern) => ({ pattern, regex: new RegExp(pattern.regex) }));
const variantNames = new Set(variants.map((variant) => variant.name));

/** Prefixes that take a bracket value, such as `w` for `w-[240]`. */
export const argumentPrefixes = patterns
  .filter((pattern) => pattern.label.endsWith('-[…]') && !pattern.label.slice(0, -4).includes('…'))
  .map((pattern) => pattern.label.slice(0, -4));

const colorPrefixes = ['text-', 'bg-', 'border-', 'tint-', 'glass-tint-'];

/** Splits `hover:group-focus/hero:p-4` into variants and the class, ignoring colons inside brackets. */
export function splitVariants(token: string): string[] {
  const parts: string[] = [];
  let part = '';
  let depth = 0;
  for (const char of token) {
    if (char === '[') depth++;
    if (char === ']') depth--;
    if (char === ':' && depth === 0) { parts.push(part); part = ''; } else part += char;
  }
  parts.push(part);
  return parts;
}

export function isKnownVariant(variant: string): boolean {
  const [base, name, ...rest] = variant.split('/');
  if (!variantNames.has(base) || rest.length) return false;
  return name === undefined || (base.startsWith('group-') && name.length > 0);
}

export interface Description {
  title: string;
  description: string;
  category: string;
}

/** What a class does, or undefined when swiftcn does not know it. */
export function describe(name: string, learned: Learned): Description | undefined {
  const entry = byName.get(name);
  if (entry) return { title: name, description: entry.description, category: entry.category };
  if (learned.named.has(name)) return { title: name, description: 'Registered in your project.', category: 'Custom' };
  if (name.startsWith('animate-') && learned.animations.has(name.slice(8))) {
    return { title: name, description: 'Animation preset registered in your project.', category: 'Animation' };
  }
  for (const prefix of colorPrefixes) {
    if (name.startsWith(prefix) && learned.colors.has(name.slice(prefix.length))) {
      return { title: name, description: `Theme color ${name.slice(prefix.length)}, registered in your project.`, category: 'Color' };
    }
  }
  const bracket = /^([A-Za-z0-9_.-]+)-\[.+\]$/.exec(name);
  if (bracket && learned.prefixes.has(bracket[1])) {
    return { title: name, description: 'Custom argument utility registered in your project.', category: 'Custom' };
  }
  const match = compiled.find(({ regex }) => regex.test(name));
  if (match) return { title: match.pattern.label, description: match.pattern.description, category: 'Pattern' };
  return undefined;
}

export interface Problem {
  message: string;
  suggestion?: string;
}

/**
 * Checks one class. It only reports names it is sure are unknown; `swiftcn-lint` and the build
 * plugin check argument values with the parser itself.
 */
export function check(token: string, learned: Learned): Problem | undefined {
  const parts = splitVariants(token);
  const name = parts[parts.length - 1];
  for (const variant of parts.slice(0, -1)) {
    if (isKnownVariant(variant)) continue;
    const fixed = closest(variant.split('/')[0], [...variantNames]);
    const suggestion = fixed && parts.map((part) => (part === variant ? fixed + variant.slice(variant.split('/')[0].length) : part)).join(':');
    return { message: `Unknown swiftcn variant '${variant}:'.` + didYouMean(suggestion), suggestion };
  }
  if (token.includes('￼')) {
    // A typed interpolation inside brackets: only the prefix can be checked.
    const bracket = /^([A-Za-z0-9_.-]+)-\[/.exec(name);
    if (!bracket) return undefined;
    const known = [...argumentPrefixes, ...learned.prefixes];
    if (known.includes(bracket[1])) return undefined;
    const fixed = closest(bracket[1], known);
    return { message: `Unknown swiftcn argument prefix '${bracket[1]}-[…]'.` + didYouMean(fixed && `${fixed}-[…]`) };
  }
  if (!name || describe(name, learned)) return undefined;
  const bracket = /^([A-Za-z0-9_.-]+)-\[(.*)\]$/.exec(name);
  if (bracket) {
    const fixed = closest(bracket[1], [...argumentPrefixes, ...learned.prefixes]);
    const suggestion = fixed && [...parts.slice(0, -1), `${fixed}-[${bracket[2]}]`].join(':');
    return { message: `Unknown swiftcn argument prefix '${bracket[1]}-[…]'.` + didYouMean(suggestion), suggestion };
  }
  const fixed = closest(name, candidates(learned));
  const suggestion = fixed && [...parts.slice(0, -1), fixed].join(':');
  return { message: `Unknown swiftcn class '${token}'.` + didYouMean(suggestion), suggestion };
}

const scale = ['0', '0.5', '1', '1.5', '2', '2.5', '3', '4', '5', '6', '8', '10', '12', '16', '20', '24'];
const samples = [
  ...['p', 'px', 'py', 'pt', 'pb', 'ps', 'pe', 'w', 'h', 'min-h'].flatMap((prefix) => scale.map((value) => `${prefix}-${value}`)),
  ...Array.from({ length: 21 }, (_, step) => `opacity-${step * 5}`),
  ...['0', '1', '2', '4'].map((value) => `border-${value}`),
  ...['75', '100', '150', '200', '300', '500', '700', '1000'].flatMap((value) => [`duration-${value}`, `delay-${value}`]),
  ...[1, 2, 3, 4, 5, 6].map((value) => `line-clamp-${value}`),
];

function candidates(learned: Learned): string[] {
  return [
    ...byName.keys(), ...samples, ...learned.named,
    ...[...learned.animations].map((name) => `animate-${name}`),
    ...[...learned.colors].flatMap((color) => colorPrefixes.map((prefix) => prefix + color)),
  ];
}

function didYouMean(suggestion: string | undefined): string {
  return suggestion ? ` Did you mean '${suggestion}'?` : '';
}

/** The closest candidate within a small edit distance, matching `TWClassCatalog.closest`. */
export function closest(name: string, options: Iterable<string>): string | undefined {
  const limit = Math.max(1, Math.min(3, Math.floor(name.length / 3)));
  let best: { name: string; distance: number } | undefined;
  for (const candidate of new Set(options)) {
    if (candidate === name) continue;
    const distance = editDistance(name, candidate, limit);
    if (distance > limit) continue;
    if (!best || distance < best.distance || (distance === best.distance && candidate < best.name)) best = { name: candidate, distance };
  }
  return best?.name;
}

function editDistance(a: string, b: string, limit: number): number {
  if (Math.abs(a.length - b.length) > limit) return limit + 1;
  let previous = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const current = [i];
    let rowMinimum = i;
    for (let j = 1; j <= b.length; j++) {
      current[j] = Math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
      rowMinimum = Math.min(rowMinimum, current[j]);
    }
    if (rowMinimum > limit) return limit + 1;
    previous = current;
  }
  return previous[b.length];
}
