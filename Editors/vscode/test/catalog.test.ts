import assert from 'node:assert/strict';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { check, classes, describe } from '../src/catalog.ts';
import { classLiterals, classTokens, emptyLearned, learn, literalAt, scan } from '../src/scanner.ts';

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');

function problems(source: string) {
  const { tokens, ignoredLines } = scan(source);
  const learned = learn(tokens);
  return classLiterals(tokens).flatMap((literal) => classTokens(literal))
    .filter((token) => !token.interpolatedOutsideBrackets)
    .map((token) => ({ token, problem: check(token.text, learned) }))
    .filter(({ token, problem }) => problem && !ignoredLines.has(source.slice(0, token.start).split('\n').length - 1))
    .map(({ token, problem }) => ({ text: token.text, suggestion: problem!.suggestion, start: token.start }));
}

test('reports misspelled classes with the closest valid class', () => {
  const source = 'Text("A").tw("p-4 bg-surfce hovr:bg-accent rounded-2xl")';
  assert.deepEqual(problems(source).map((p) => [p.text, p.suggestion]), [
    ['bg-surfce', 'bg-surface'],
    ['hovr:bg-accent', 'hover:bg-accent'],
    ['rounded-2xl', 'rounded-xl'],
  ]);
  assert.equal(problems(source)[0].start, source.indexOf('bg-surfce'));
});

test('accepts every catalog class, patterns, variants, and arguments', () => {
  const learned = emptyLearned();
  for (const entry of classes) assert.equal(check(entry.name, learned), undefined, entry.name);
  for (const name of ['p-4', 'px-2.5', 'w-12', 'min-h-11', 'opacity-80', 'border-2', 'line-clamp-3', 'duration-200',
    'group/hero', 'shared-[cover]/hero', 'w-[240]', 'bg-[#6366f1]', 'rotate-[3deg]', 'hover:group-focus/hero:opacity-50']) {
    assert.equal(check(name, learned), undefined, name);
  }
  assert.equal(describe('text-lg', learned)?.description, 'Font .title3. Scales with Dynamic Type.');
});

test('learns names that the project registers', () => {
  const source = `
    let rules = TWGlobalRules(named: ["motion-card": "card"], animations: ["settle": TWAnimation(.default)],
                              modifiers: ["tilt": .value(default: 0.0) { view, d in view }])
    let brand = TWColor("brand")
    Text("A").tw("motion-card tilt-[8deg] animate-settle bg-brand")
    Text("B").twRules { $0.named["pill"] = "rounded-full" }.tw("pill")`;
  assert.deepEqual(problems(source), []);
});

test('skips comments, runtime fragments, and ignored lines, and checks typed interpolation prefixes', () => {
  const source = String.raw`
    // .tw("not-a-class")
    Text("A").tw("\(compact ? "p-2" : "p-3") shadow-lgg")
    Text("B").tw("made-up") // swiftcn-lint: ignore
    Text("C").tw("rotte-[\(angle)] bg-[\(Color.red)]")`;
  assert.deepEqual(problems(source).map((p) => p.text), ['shadow-lgg', 'rotte-[￼]']);
});

test('finds the literal under the cursor, outside interpolations', () => {
  const source = String.raw`Text("A").tw("p-4 \(x) bg-")`;
  const literals = classLiterals(scan(source).tokens);
  assert.ok(literalAt(literals, source.indexOf('bg-') + 3));
  assert.equal(literalAt(literals, source.indexOf('(x') + 1), undefined);
  assert.equal(literalAt(literals, source.indexOf('"A"') + 1), undefined);
});

/** The examples exercise most of the grammar, so they guard against false positives. */
test('agrees with swiftcn-lint on the repository examples', () => {
  const files: string[] = [];
  const walk = (directory: string) => {
    for (const name of readdirSync(directory)) {
      const full = path.join(directory, name);
      if (statSync(full).isDirectory()) walk(full);
      else if (name.endsWith('.swift')) files.push(full);
    }
  };
  walk(path.join(repository, 'Examples'));
  const sources = files.map((file) => readFileSync(file, 'utf8'));
  const learned = emptyLearned();
  for (const source of sources) {
    const found = learn(scan(source).tokens);
    for (const key of ['named', 'prefixes', 'animations', 'colors'] as const) for (const name of found[key]) learned[key].add(name);
  }
  const reported = sources.flatMap((source) => classLiterals(scan(source).tokens).flatMap(classTokens)
    .filter((token) => !token.interpolatedOutsideBrackets && check(token.text, learned))
    .map((token) => token.text));
  // h-full is a real problem in NativeArrangementExample; swiftcn-lint reports it too.
  assert.deepEqual([...new Set(reported)], ['h-full']);
  assert.ok(files.length > 50);
});
