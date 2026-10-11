// Finds swiftcn class strings in Swift source. A port of the lexer in Sources/SwiftCNLint, so the
// editor and `swiftcn-lint` agree on which literals hold classes.

export interface Piece {
  /** A character of the literal's value, or null for an interpolation. */
  char: string | null;
  /** Offset of the piece in the document. */
  offset: number;
}

export interface Literal {
  pieces: Piece[];
  /** Offset of the opening quote. */
  start: number;
  /** Offset just after the opening delimiter. */
  contentStart: number;
  /** Offset of the closing delimiter, or the end of the line for an unterminated literal. */
  contentEnd: number;
  /** Ranges inside the literal that belong to interpolations. */
  interpolations: Array<[number, number]>;
}

type Token =
  | { kind: 'identifier'; value: string; offset: number }
  | { kind: 'punctuation'; value: string; offset: number }
  | { kind: 'string'; literal: Literal; offset: number }
  | { kind: 'other'; offset: number };

export interface Scan {
  tokens: Token[];
  /** Zero-based lines whose diagnostics are suppressed by a swiftcn-lint comment. */
  ignoredLines: Set<number>;
}

export function scan(source: string): Scan {
  const tokens: Token[] = [];
  const ignoredLines = new Set<number>();
  let i = 0;
  const peek = (offset = 0) => source[i + offset];
  const lineOf = (offset: number) => {
    let line = 0;
    for (let k = 0; k < offset; k++) if (source[k] === '\n') line++;
    return line;
  };

  const directive = (text: string, offset: number) => {
    const compact = text.toLowerCase().replace(/ /g, '');
    if (compact.includes('swiftcn-lint:ignore-next-line')) ignoredLines.add(lineOf(offset) + 1);
    else if (compact.includes('swiftcn-lint:ignore')) ignoredLines.add(lineOf(offset));
  };
  const lineComment = () => {
    const start = i;
    while (i < source.length && source[i] !== '\n') i++;
    directive(source.slice(start, i), start);
  };
  const blockComment = () => {
    const start = i;
    let depth = 0;
    do {
      if (peek() === '/' && peek(1) === '*') { depth++; i += 2; continue; }
      if (peek() === '*' && peek(1) === '/') { depth--; i += 2; continue; }
      if (i >= source.length) break;
      i++;
    } while (depth > 0);
    directive(source.slice(start, i), start);
  };

  const closes = (multiline: boolean, hashes: number) => {
    const quotes = multiline ? 3 : 1;
    for (let k = 0; k < quotes; k++) if (peek(k) !== '"') return false;
    for (let k = 0; k < hashes; k++) if (peek(quotes + k) !== '#') return false;
    return true;
  };

  const skipInterpolation = () => {
    i++; // (
    let depth = 1;
    while (i < source.length && depth > 0) {
      const c = peek();
      if (c === '/' && peek(1) === '/') { lineComment(); continue; }
      if (c === '/' && peek(1) === '*') { blockComment(); continue; }
      if ((c === '#' || c === '"') && stringLiteral()) continue;
      if (c === '(') depth++;
      if (c === ')') depth--;
      i++;
    }
  };

  function stringLiteral(): Literal | null {
    let hashes = 0;
    while (peek(hashes) === '#') hashes++;
    if (peek(hashes) !== '"') return null;
    const start = i;
    i += hashes;
    const multiline = peek(1) === '"' && peek(2) === '"';
    if (!multiline && peek(1) === '"') {
      // An empty literal.
      i += 2;
      for (let k = 0; k < hashes && peek() === '#'; k++) i++;
      return { pieces: [], start, contentStart: start + hashes + 1, contentEnd: start + hashes + 1, interpolations: [] };
    }
    i += multiline ? 3 : 1;
    const contentStart = i;
    const pieces: Piece[] = [];
    const interpolations: Array<[number, number]> = [];
    let contentEnd = source.length;
    while (i < source.length) {
      const c = peek();
      if (closes(multiline, hashes)) {
        contentEnd = i;
        i += (multiline ? 3 : 1) + hashes;
        break;
      }
      if (!multiline && c === '\n') { contentEnd = i; break; }
      if (c === '\\' && Array.from({ length: hashes }, (_, k) => peek(1 + k) === '#').every(Boolean)) {
        const escapeStart = i;
        i += 1 + hashes;
        const escaped = peek();
        if (escaped === undefined) break;
        if (escaped === '(') {
          pieces.push({ char: null, offset: escapeStart });
          skipInterpolation();
          interpolations.push([escapeStart, i]);
        } else if (escaped === 'u' && peek(1) === '{') {
          const close = source.indexOf('}', i);
          const scalar = Number.parseInt(source.slice(i + 2, close), 16);
          if (!Number.isNaN(scalar)) pieces.push({ char: String.fromCodePoint(scalar), offset: escapeStart });
          i = close + 1;
        } else if (escaped === '\n') {
          i++;
        } else {
          const map: Record<string, string> = { n: '\n', t: '\t', r: '\r', '0': '\0' };
          pieces.push({ char: map[escaped] ?? escaped, offset: escapeStart });
          i++;
        }
        continue;
      }
      pieces.push({ char: c, offset: i });
      i++;
    }
    return { pieces, start, contentStart, contentEnd, interpolations };
  }

  while (i < source.length) {
    const c = peek();
    if (/\s/.test(c)) { i++; continue; }
    if (c === '/' && peek(1) === '/') { lineComment(); continue; }
    if (c === '/' && peek(1) === '*') { blockComment(); continue; }
    if (c === '#' || c === '"') {
      const literal = stringLiteral();
      if (literal) { tokens.push({ kind: 'string', literal, offset: literal.start }); continue; }
    }
    const start = i;
    if (/[A-Za-z_$]/.test(c)) {
      while (i < source.length && /[A-Za-z0-9_$]/.test(source[i])) i++;
      tokens.push({ kind: 'identifier', value: source.slice(start, i), offset: start });
      continue;
    }
    if (c === '`') {
      const close = source.indexOf('`', i + 1);
      const end = close === -1 ? source.length : close;
      tokens.push({ kind: 'identifier', value: source.slice(i + 1, end), offset: start });
      i = end + 1;
      continue;
    }
    if (/[0-9]/.test(c)) {
      while (i < source.length && /[0-9A-Za-z._]/.test(source[i])) i++;
      tokens.push({ kind: 'other', offset: start });
      continue;
    }
    i++;
    tokens.push({ kind: 'punctuation', value: c, offset: start });
  }
  return { tokens, ignoredLines };
}

const isPunctuation = (token: Token | undefined, value: string) => token?.kind === 'punctuation' && token.value === value;
const identifier = (token: Token | undefined) => (token?.kind === 'identifier' ? token.value : undefined);
const literal = (token: Token | undefined) => (token?.kind === 'string' ? token.literal : undefined);
const opens = (token: Token) => isPunctuation(token, '(') || isPunctuation(token, '[') || isPunctuation(token, '{');
const closesGroup = (token: Token) => isPunctuation(token, ')') || isPunctuation(token, ']') || isPunctuation(token, '}');

export function plainText(value: Literal): string | null {
  let text = '';
  for (const piece of value.pieces) {
    if (piece.char === null) return null;
    text += piece.char;
  }
  return text;
}

function dictionaryEntries(tokens: Token[], openingBracket: number): Array<{ key: string; value?: Literal }> {
  const entries: Array<{ key: string; value?: Literal }> = [];
  let depth = 0;
  for (let index = openingBracket; index < tokens.length; index++) {
    const token = tokens[index];
    if (opens(token)) depth++;
    if (closesGroup(token)) { depth--; if (depth === 0) break; }
    const key = literal(token);
    if (depth === 1 && key && isPunctuation(tokens[index + 1], ':')) {
      const text = plainText(key);
      if (text === null) continue;
      const value = literal(tokens[index + 2]);
      const after = tokens[index + 3];
      entries.push({ key: text, value: value && (isPunctuation(after, ',') || isPunctuation(after, ']')) ? value : undefined });
    }
  }
  return entries;
}

function callArguments(tokens: Token[], openingParenthesis: number): Literal[] {
  const result: Literal[] = [];
  let depth = 0;
  let argumentStart = openingParenthesis + 1;
  for (let index = openingParenthesis; index < tokens.length; index++) {
    const token = tokens[index];
    if (opens(token)) depth++;
    const closing = closesGroup(token);
    if (closing) depth--;
    if ((depth === 1 && isPunctuation(token, ',')) || (depth === 0 && closing)) {
      const value = literal(tokens[argumentStart]);
      if (index - argumentStart === 1 && value) result.push(value);
      argumentStart = index + 1;
    }
    if (depth === 0) break;
  }
  return result;
}

/** String literals that hold classes, in the same places `swiftcn-lint` checks. */
export function classLiterals(tokens: Token[]): Literal[] {
  const found: Literal[] = [];
  tokens.forEach((token, index) => {
    const at = (offset: number) => tokens[index + offset];
    // While typing, the argument may not be closed yet, so a literal directly after `(` counts.
    if (isPunctuation(token, '.') && ['tw', 'twAnimation', 'classes'].includes(identifier(at(1)) ?? '') && isPunctuation(at(2), '(')) {
      const value = literal(at(3));
      if (value) found.push(value);
    }
    if (identifier(token) === 'cn' && !isPunctuation(tokens[index - 1], '.') && isPunctuation(at(1), '(')) {
      found.push(...callArguments(tokens, index + 1));
      const first = literal(at(2));
      if (first && !found.includes(first)) found.push(first);
    }
    if (identifier(token) === 'classes' && isPunctuation(at(1), ':')) {
      const value = literal(at(2));
      if (value) found.push(value);
    }
    if (['TWClasses', 'TWStyle'].includes(identifier(token) ?? '') && isPunctuation(tokens[index - 1], ':') && isPunctuation(at(1), '=')) {
      const value = literal(at(2));
      if (value && !isPunctuation(at(3), '+')) found.push(value);
    }
    if (identifier(token) === 'named' && isPunctuation(at(1), ':') && isPunctuation(at(2), '[')) {
      for (const entry of dictionaryEntries(tokens, index + 2)) if (entry.value) found.push(entry.value);
    }
  });
  return [...new Set(found)];
}

export interface Learned {
  named: Set<string>;
  prefixes: Set<string>;
  animations: Set<string>;
  colors: Set<string>;
}

export const emptyLearned = (): Learned => ({ named: new Set(), prefixes: new Set(), animations: new Set(), colors: new Set() });

/** Names that the source registers at run time: recipes, modifiers, utilities, animations, and colors. */
export function learn(tokens: Token[]): Learned {
  const learned = emptyLearned();
  const record = (name: string, kind: string) => {
    if (kind === 'named') learned.named.add(name);
    else if (kind === 'animations') learned.animations.add(name);
    else { learned.named.add(name); learned.prefixes.add(name); }
  };
  tokens.forEach((token, index) => {
    if (identifier(token) === 'TWColor' && isPunctuation(tokens[index + 1], '(')) {
      const offset = identifier(tokens[index + 2]) === 'rawValue' ? 4 : 2;
      const value = literal(tokens[index + offset]);
      const text = value && plainText(value);
      if (text) learned.colors.add(text);
    }
    const kind = identifier(token);
    if (!kind || !['named', 'modifiers', 'utilities', 'animations'].includes(kind)) return;
    if (isPunctuation(tokens[index + 1], ':') && isPunctuation(tokens[index + 2], '[')) {
      for (const entry of dictionaryEntries(tokens, index + 2)) record(entry.key, kind);
    }
    const key = literal(tokens[index + 2]);
    if (isPunctuation(tokens[index - 1], '.') && isPunctuation(tokens[index + 1], '[') && key && isPunctuation(tokens[index + 3], ']')) {
      const text = plainText(key);
      if (text) record(text, kind);
    }
  });
  return learned;
}

export interface ClassToken {
  /** The class as written, with U+FFFC for each interpolation. */
  text: string;
  start: number;
  end: number;
  hasInterpolation: boolean;
  interpolatedOutsideBrackets: boolean;
}

/** Splits a literal into whitespace-separated classes with their document offsets. */
export function classTokens(value: Literal): ClassToken[] {
  const tokens: ClassToken[] = [];
  let current: ClassToken | null = null;
  let depth = 0;
  const finish = (end: number) => {
    if (current) { current.end = end; tokens.push(current); }
    current = null;
    depth = 0;
  };
  for (let index = 0; index < value.pieces.length; index++) {
    const piece = value.pieces[index];
    if (piece.char !== null && /\s/.test(piece.char)) { finish(piece.offset); continue; }
    current ??= { text: '', start: piece.offset, end: piece.offset, hasInterpolation: false, interpolatedOutsideBrackets: false };
    if (piece.char === null) {
      current.hasInterpolation = true;
      if (depth <= 0) current.interpolatedOutsideBrackets = true;
      current.text += '￼';
      const span = value.interpolations.find(([start]) => start === piece.offset);
      current.end = span ? span[1] : piece.offset + 1;
      continue;
    }
    if (piece.char === '[') depth++;
    if (piece.char === ']') depth--;
    current.text += piece.char;
    current.end = (value.pieces[index + 1]?.offset ?? value.contentEnd);
  }
  finish(value.pieces.length ? value.contentEnd : value.contentStart);
  // Recompute ends from the next piece so escapes keep their source width.
  return tokens.map((token) => ({ ...token, end: Math.max(token.end, token.start + 1) }));
}

/** The class literal that contains an offset, outside any interpolation. */
export function literalAt(literals: Literal[], offset: number): Literal | undefined {
  return literals.find((value) =>
    offset >= value.contentStart && offset <= value.contentEnd &&
    !value.interpolations.some(([start, end]) => offset > start && offset < end));
}
