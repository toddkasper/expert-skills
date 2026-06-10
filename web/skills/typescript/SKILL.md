---
name: typescript
description: Writing and reviewing TypeScript — the type system and structural typing, generics, narrowing and inference, conditional/mapped/utility types, strictness configuration (tsconfig, the strict family), module resolution and project references, typing third-party/Node APIs, and declaration files (.d.ts). Use when adding or reviewing types in any TS codebase (Node, React, Lambdas). Framework-specific concerns live in the react/nodejs/nextjs/react-native skills. Competence skill anchored on the official TypeScript Handbook — no first-party certification.
metadata:
  credential: None — competence skill (TypeScript has no first-party certification)
  domain: web
  type: competence-playbook
  status: active
  anchored-to: TypeScript Handbook + official release notes (typescriptlang.org)
---

# TypeScript — Skills Reference

## Overview

TypeScript is a statically typed superset of JavaScript maintained by Microsoft. The goal of this
skill is the working competence a strong TypeScript engineer applies: using the type system to make
illegal states unrepresentable, without fighting the compiler or hiding behind `any`. There is no
official TypeScript certification; competence is anchored to the TypeScript Handbook and official
release notes.

**Scope of this skill:** the TypeScript type system and compiler toolchain — type syntax,
inference, narrowing, generics, configuration, and declaration files. Framework usage (React JSX,
Next.js server components, Node.js APIs) is deferred to the sibling skills (`react`, `nextjs`,
`nodejs`).

> Study resources and version history live in
> [references/study-resources.md](references/study-resources.md) — load that file when planning
> a learning path or verifying a version-specific fact.

---

## TypeScript 6.0 — Breaking-change release (March 2026)

TypeScript 6.0 shipped March 2026 as the **last release compiled by TypeScript itself**. It
changed nine defaults at once. Know these before touching a tsconfig in 2026.

| Option | Old default | New default (6.0) |
|---|---|---|
| `strict` | `false` | **`true`** |
| `module` | `commonjs` | **`esnext`** |
| `target` | `es5` | **`es2025`** |
| `rootDir` | inferred | `.` (tsconfig directory) |
| `types` | `["*"]` (all @types) | **`[]`** (none) |
| `noUncheckedSideEffectImports` | `false` | `true` |

**Removed entirely in 6.0:** `--outFile`, `--module amd/umd/systemjs/none`,
`--moduleResolution classic`, `target: es5`, `--downlevelIteration`, legacy `module` keyword
(use `namespace`), `import assertions` with `assert` (use `with`).

**Deprecated in 6.0 (will be removed in 7.0):** `--baseUrl`, `--moduleResolution node` (node10),
`--esModuleInterop false`, `--allowSyntheticDefaultImports false`.

**`types: []` default is a stealth breaking change:** any project that relied on auto-loaded
`@types/node`, `@types/jest`, etc., must now list them explicitly:
```json
{ "compilerOptions": { "types": ["node", "jest"] } }
```

TypeScript 7.0 (Go-native compiler, ~late 2026) will remove everything deprecated in 6.0 and is
expected to deliver ~10× build speedups. All 6.0-deprecated options must be cleaned up before
adopting 7.0.

---

## 1. Type-system fundamentals & narrowing

### Structural typing

TypeScript uses **structural (duck) typing** — a type is compatible if its shape matches,
regardless of nominal origin. Consequence: two interfaces with identical properties are
interchangeable even if declared in different files or by different authors. This is intentional
and correct; do not work around it with phantom properties unless you genuinely need nominal
distinctions.

**Literal types and widening:** `const x = "blue"` infers type `"blue"`; `let x = "blue"` widens
to `string`. Add `as const` to freeze an object's values to their literal types:
```ts
const DIRECTIONS = ["north", "south", "east", "west"] as const;
type Direction = typeof DIRECTIONS[number]; // "north" | "south" | "east" | "west"
```

**Template literal types** compose string unions at the type level:
```ts
type EventName = `on${Capitalize<"click" | "focus">}`; // "onClick" | "onFocus"
```

### Narrowing

TypeScript's control-flow analysis narrows union types as code branches. The narrowing tools, in
order of preference:

| Technique | When to use |
|---|---|
| `typeof x === "string"` | Primitives |
| `x instanceof Date` | Class instances |
| `"swim" in x` | Structural property presence |
| Discriminated union (`kind` field) | Modeling mutually exclusive states |
| Type predicate (`x is Fish`) | Custom guard, isolates runtime check |
| Assertion function (`asserts x is T`) | Throws on failure, narrows after call |
| `never` exhaustiveness check | Compile-time guarantee all union arms are handled |

**Discriminated unions are the primary modeling tool** for state machines and variant data. Use a
shared literal-typed `kind` (or `type`, `tag`) field; the compiler then narrows each branch
automatically in `switch`/`if`.

**Exhaustiveness pattern** — assign to `never` in the default branch so adding a new union member
causes a compile error in every switch that forgets to handle it:
```ts
function assertNever(x: never): never {
  throw new Error("Unhandled case: " + x);
}
```

**`satisfies` vs `as`:** use `satisfies` to validate an object against a type while preserving the
most-specific inferred type (e.g., config objects, discriminated union literals). Use `as` only
when you genuinely know more than the compiler (e.g., DOM refs, casting from an untyped API
response after manual validation). `as` bypasses type checking entirely; `satisfies` does not.

---

## 2. Generics & advanced types

### Generics

Generics are parameterized types. Keep them simple: one parameter with a clear constraint is
almost always better than three unconstrained parameters.

**Constraints with `extends`:** `<T extends { length: number }>` means "T must have at least
`length`." Constraints make generics useful without over-broadening.

**`const` type parameters (TS 5.0+):** `<const T>` infers literal types without requiring callers
to write `as const`:
```ts
function first<const T extends readonly unknown[]>(arr: T): T[0] { return arr[0]; }
```

**When generics hurt:** a generic function where every call site has T = the same concrete type is
not gaining anything. Generics earn their complexity only when the relationship between input and
output types (or between two parameters) genuinely varies per callsite.

### Conditional types

`T extends U ? X : Y` — branch at the type level. Distributive by default over union T:
`type Unwrap<T> = T extends Promise<infer U> ? U : T`.

**`infer`** extracts a type from a pattern inside `extends`: use it to pull out return types,
element types, or parameter types. The built-in utility types `ReturnType<F>`,
`Parameters<F>`, `Awaited<T>` are implemented this way.

**Avoid deeply nested conditional chains.** More than two levels of nesting is a maintenance
problem; consider a lookup table (mapped type over a union) instead.

### Mapped types

Transform every key in a type:
```ts
type Readonly<T>  = { readonly [K in keyof T]: T[K] };
type Partial<T>   = { [K in keyof T]?: T[K] };
type Nullable<T>  = { [K in keyof T]: T[K] | null };
```

Key modifiers: `readonly`, `?` (optional), `-readonly` (remove readonly), `-?` (remove optional).
Remap keys with `as`: `{ [K in keyof T as Capitalize<string & K>]: T[K] }`.

### Utility types — the ones engineers reach for most

| Utility | What it does |
|---|---|
| `Partial<T>` | All props optional |
| `Required<T>` | All props required |
| `Readonly<T>` | All props readonly |
| `Pick<T, K>` | Keep only keys K |
| `Omit<T, K>` | Drop keys K |
| `Record<K, V>` | Object with keys K and values V |
| `Exclude<T, U>` | Union T minus U |
| `Extract<T, U>` | Union T intersected with U |
| `NonNullable<T>` | Remove null/undefined |
| `ReturnType<F>` | Return type of function F |
| `Parameters<F>` | Parameter tuple of function F |
| `Awaited<T>` | Unwrap Promise (recursive) |

---

## 3. Configuration & strictness

### The strict flag hierarchy

`"strict": true` (now the 6.0 default) enables eight sub-flags:

| Sub-flag | What it catches |
|---|---|
| `noImplicitAny` | Variables/params inferred as `any` |
| `strictNullChecks` | `null`/`undefined` not assignable to non-nullable types |
| `strictFunctionTypes` | Contravariant param checking for function types |
| `strictBindCallApply` | Correct argument types for `.call`/`.bind`/`.apply` |
| `strictPropertyInitialization` | Class props must be assigned in constructor |
| `noImplicitThis` | `this` typed as `any` in functions |
| `alwaysStrict` | Emits `"use strict"` |
| `useUnknownInCatchVariables` | Catch variable typed `unknown` not `any` |

**Opt-in beyond strict** (not yet defaults, but strongly recommended):

| Flag | Why |
|---|---|
| `noUncheckedIndexedAccess` | `arr[i]` returns `T \| undefined`, forces index bounds awareness |
| `exactOptionalPropertyTypes` | `{ x?: T }` disallows explicit `undefined` assignment; cleaner option semantics |
| `noImplicitOverride` | Must write `override` keyword when overriding a base method |
| `noUnusedLocals` + `noUnusedParameters` | Dead code detection at compile time |
| `noFallthroughCasesInSwitch` | Catches missing `break` |
| `noImplicitReturns` | All code paths must return a value |

**Gradual adoption:** on a legacy JS→TS migration, set `strict: false` and enable flags one at a
time, starting with `strictNullChecks` (highest value/effort ratio). Never leave `strict: false`
on new code.

### Module resolution

| Setting | Use when |
|---|---|
| `"module": "nodenext"` + `"moduleResolution": "nodenext"` | Node.js packages with ESM or dual CJS/ESM |
| `"module": "esnext"` + `"moduleResolution": "bundler"` | Bundler-based apps (Vite, webpack, esbuild) |
| `"module": "esnext"` + `"moduleResolution": "nodenext"` | Not valid — do not mix |

`--moduleResolution node` (node10) is deprecated in 6.0; migrate to `nodenext` or `bundler`.
`"moduleResolution": "bundler"` is the right choice for any project that goes through a bundler;
it does not enforce the `.js` extension requirement that `nodenext` requires.

**`--module node20`** (introduced TS 5.9): stable, non-floating alias for Node 20 behavior with
`--target es2023` implied. Prefer over `nodenext` when pinning to Node 20 specifically.

### Project references

Large monorepos should use project references (`"composite": true`, `"references": [...]`) to
enable incremental type checking per package. Requirements: `"composite": true` implies
`"declaration": true`. Add `"declarationMap": true` to enable jump-to-source across package
boundaries. Use `tsc --build` (or `tsc -b`) to build the reference graph.

---

## 4. Typing the outside world

### Third-party `@types` packages

As of TypeScript 6.0, `"types": []` is the default — `@types` packages are **not** auto-loaded.
List every needed `@types` package explicitly in `tsconfig.json` under `"types"`.

Resolution: TypeScript looks for `@types/<package>` automatically when you `import "package"`. If
no `@types` package exists and the library ships no `.d.ts`, you must author one or use
`declare module "package-name"` as a stub (document this as technical debt).

**DefinitelyTyped** (github.com/DefinitelyTyped/DefinitelyTyped) hosts community-maintained
declarations for packages that don't ship their own types. Library authors writing in TypeScript
should ship `.d.ts` files directly (via `"declaration": true`) rather than relying on
DefinitelyTyped.

### Declaration files (`.d.ts`)

Write `.d.ts` files when:
- Typing an existing plain-JS library with no types.
- Publishing a TS library and exposing its public API to consumers.
- Augmenting a third-party module's types (module augmentation).

Rules for `.d.ts` files:
- Declare only what the JS actually exports. Phantom types that don't exist at runtime cause
  runtime errors.
- Use `export declare` (not `export`) in module declaration files.
- For global augmentation use `declare global { ... }` inside a module file.
- For module augmentation use `declare module "library" { ... }` in a `.d.ts` file.
- Prefer `interface` for extensible shapes (consumers can merge), `type` for unions/tuples/aliases.

### When `any` and type assertions are justified

`any` legitimate uses (very short list):
- Interop with an API that genuinely returns unstructured data (JSON from an unknown schema).
- Incremental JS→TS migration: annotate as `any` explicitly, track with `// TODO: type this`.
- Type-level utilities that must accept anything (e.g. the argument to `JSON.stringify`).

`any` red flags:
- `(x as any).someMethod()` to silence a compile error that would catch a real bug.
- `as unknown as TargetType` double-cast — almost always a type model problem.
- Returning `any` from a public function's signature.

For data crossing a runtime boundary (API responses, `JSON.parse`, environment variables), use a
runtime validator (Zod, Valibot, etc.) and let the validator produce the typed output — do not
cast raw parsed data with `as`.

---

## Operational Rules Quick Reference

- **DO** model with discriminated unions (shared `kind` literal field) for mutually exclusive
  states — the compiler narrows automatically.
- **DO** use `satisfies` to validate config/literal objects against a type while keeping the
  inferred literal shape; prefer it over `as` for object initialization.
- **DON'T** use `as` to silence a type error — fix the type model. Reserve `as` for genuine
  type-narrowing the compiler can't see (post-validation casts, DOM refs).
- **DON'T** use `any` without a comment explaining why; prefer `unknown` and narrow it.
- **DO** enable `strict: true` on all new code (it is now the 6.0 default). Layer
  `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` on top for stricter semantics.
- **DON'T** fight `noUncheckedIndexedAccess` by casting — add bounds checks or use `.at()` with a
  default.
- **DO** assert exhaustiveness in `switch` over a discriminated union by assigning the default to
  `never`; this turns a missing case into a compile error.
- **DON'T** use TypeScript `enum` in new code — prefer `as const` objects + a derived union type
  (smaller bundle, works with `erasableSyntaxOnly`, no runtime artifact).
- **DO** use `const` type parameters (`<const T>`) to infer literal types from call-site values
  without requiring `as const` at the callsite (TS 5.0+).
- **DO** use `--module nodenext` (or `node20`) + `"moduleResolution": "nodenext"` for Node
  packages; use `--module esnext` + `"moduleResolution": "bundler"` for bundled apps.
- **DO** explicitly list `"types": ["node"]` (or whichever @types you need) in tsconfig — the
  6.0 default is `"types": []`, so nothing is auto-loaded.
- **DON'T** use deprecated 6.0 options (`--baseUrl`, `--moduleResolution node`, `--outFile`) in
  new projects; they will be removed in TypeScript 7.0.
- **DO** add `"declarationMap": true` in library packages so consumers can jump-to-source.
- **DON'T** cast `JSON.parse(...)` with `as MyType` — use a runtime validator (Zod/Valibot) and
  let the validator produce the typed output.
- **DO** keep `.d.ts` declarations honest: declare only what actually exists at runtime.
- **DON'T** add generics for the sake of flexibility if every callsite resolves T to the same
  concrete type — they add noise without benefit.
- **DO** put `noUnusedLocals: true` and `noUnusedParameters: true` in CI configs to catch dead
  code before review.

## Red flags in code review

- A function returning `any` in a public API signature.
- `as unknown as T` double-cast (structural lie — find the real type mismatch).
- Enum declarations (prefer `as const` + derived union).
- Array index access `arr[i]` used without a bounds check, especially when
  `noUncheckedIndexedAccess` is not enabled.
- An optional property `foo?: string` used everywhere as `foo?: string | undefined` — with
  `exactOptionalPropertyTypes` these differ.
- A `catch (e)` block casting `e as Error` without checking — TS 6.0 makes `e: unknown` the
  default; narrow it with `instanceof Error`.
- `.d.ts` file declaring methods or properties the underlying JS library does not actually export.
- A `tsconfig.json` that still has `"moduleResolution": "node"` (node10) or `--baseUrl` — both
  deprecated in 6.0, removed in 7.0.
- `JSON.parse(rawInput) as SomeType` without a runtime validation step.

---

_Independent educational content to upskill AI agents. TypeScript is a trademark of Microsoft.
Not affiliated with or endorsed by Microsoft. Guidance only — verify against official
documentation at typescriptlang.org._
