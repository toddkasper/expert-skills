---
name: typescript
description: Writing and reviewing TypeScript — the type system and structural typing, generics, narrowing and inference, conditional/mapped/utility types, strictness configuration (tsconfig, the strict family), module resolution and project references, typing third-party/Node APIs, and declaration files (.d.ts). Use when adding or reviewing types in any TS codebase (Node, React, Lambdas). Framework-specific concerns live in the react/nodejs/nextjs/react-native skills. Competence skill anchored on the official TypeScript Handbook — no first-party certification.
metadata:
  credential: None — competence skill (TypeScript has no first-party certification)
  domain: web
  type: competence-playbook
  status: active
  last-reviewed: 2026-06-09
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

> **Load this skill when…** designing or reviewing type models (discriminated unions, generics, mapped types); configuring `tsconfig.json` (strictness, module resolution, project references); authoring or fixing `.d.ts` declaration files; migrating a JavaScript codebase to TypeScript.
> **Not this skill:** React component and hook typing → see `react`; Node.js API typing in the context of building a service → see `nodejs`; Next.js server-component typing → see `nextjs`; React Native/Expo typing → see `react-native`.

> Study resources and version history live in
> [references/study-resources.md](references/study-resources.md) — load that file when planning
> a learning path or verifying a version-specific fact.

> **Verify steps assume nothing about your tooling** — use your project's own scripts and the language toolchain (`tsc`, `node`, the test runner, the package manager), in that order of preference.

---

## Uncertainty & Escalation

- **Always re-verify live:** TypeScript compiler defaults and strictness options changed materially at 6.0 and will change again at 7.0 — always check the installed TypeScript version (`npm ls typescript`) and compare against the [release notes](https://devblogs.microsoft.com/typescript/). `[volatile — verify live]` marks apply to: `strict` default (was `false` before TS 6.0); `module`/`target` defaults (changed in TS 6.0); `types` default (changed from auto-load all to `[]` in TS 6.0); `--moduleResolution node` deprecation timeline (deprecated 6.0, removal in 7.0 — `[volatile — verify live]`); `const` type parameters (TS 5.0+ only); TypeScript 7.0 Go-native compiler timeline and option removal (expected late 2026 — `[volatile — verify live]`).
- **Live wins:** the installed TypeScript version's actual compiler behavior and [typescriptlang.org](https://typescriptlang.org) are authoritative over this file → log discrepancies via Feedback protocol below.
- **Escalate to a human:** major TypeScript version upgrades in production monorepos (breaking defaults can silently change inferred types); removing `strict: false` overrides across a large legacy codebase (compile errors may cascade); dependency major-version bumps; production deploys after tsconfig changes.
- **Confidence taxonomy:** facts in this file are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

---

## TypeScript 6.0 — Breaking-change release (March 2026) `[volatile — verify live]`

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

TypeScript 7.0 (Go-native compiler, ~late 2026) `[volatile — verify live]` will remove everything deprecated in 6.0 and is
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

**`--module node20`** (introduced TS 5.9) `[volatile — verify live]`: stable, non-floating alias for Node 20 behavior with
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

## Executable Workflows

### Workflow 1 — Type an external/Node API safely (runtime validator at boundary → narrow → honest .d.ts)

1. Identify the trust boundary: any value arriving via `JSON.parse`, `fetch().then(r => r.json())`, `req.body`, `process.env`, or a third-party callback is `unknown` at the boundary.
2. Define a Zod (or Valibot) schema that matches what the API actually returns — not what you hope it returns. Use `.parse()` to validate; on failure it throws a `ZodError` with field-level diagnostics. → gate: call `.parse()` with a deliberately malformed payload; confirm it throws `ZodError`, not a silent `undefined`.
3. Let the validator infer the TypeScript type: `type MyPayload = z.infer<typeof MyPayloadSchema>`. Do not write the `type` separately and then cast — the schema is the single source of truth.
4. If you must author a `.d.ts` for a plain-JS library, load the library in a Node.js REPL and inspect `Object.keys(require('the-lib'))` and the prototype chain before declaring anything. → gate: `node -e "const lib = require('the-lib'); console.log(typeof lib.method)"` — only declare methods that return `'function'`.
5. Publish the `.d.ts` alongside the JS output by setting `"declaration": true` and `"declarationMap": true` in `tsconfig.json`. → gate: `tsc --build` produces `.d.ts` and `.d.ts.map` files in `dist/`; consumers can jump-to-source across the package boundary.

### Workflow 2 — Tighten strictness incrementally on a JS→TS codebase

1. Check the installed TypeScript version (`npm ls typescript`). If on TS 6.0+, `strict: true` is already the default — confirm the project's `tsconfig.json` is not explicitly setting `"strict": false`. → gate: `tsc --showConfig | grep strict` reflects the actual effective value.
2. If `strict: false` is set and the codebase is large, enable sub-flags one at a time in order of value/effort ratio: `strictNullChecks` first (highest yield — catches most real bugs), then `noImplicitAny`, then the rest of the strict family.
3. After enabling each flag, run `tsc --noEmit 2>&1 | wc -l` to count new errors. Fix or explicitly type-assert with a `// TODO: type this` comment — never add `// @ts-ignore` without a ticket. → gate: error count decreases monotonically across commits; no `// @ts-ignore` without a linked tracking note.
4. Add `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` after the strict family is clean — these are the highest-value non-strict additions. → gate: `tsc --noEmit` exits 0 with both flags enabled.
5. Add `"noUnusedLocals": true` and `"noUnusedParameters": true` in a CI-only `tsconfig.ci.json` that extends the base. Run it in CI to catch dead code before review without blocking local development. → gate: CI `tsc -p tsconfig.ci.json --noEmit` exits 0.

### Workflow 3 — Model a discriminated union with exhaustiveness checking

1. Define a shared literal-typed discriminant field (`kind`, `type`, or `tag`) on every variant: `{ kind: 'circle'; radius: number }`, `{ kind: 'rect'; w: number; h: number }`. The discriminant must be a string literal, not a general `string`. → gate: `tsc` narrows correctly in a `switch (shape.kind)` block without type assertions.
2. Combine variants into a union type: `type Shape = Circle | Rect | Triangle`.
3. Write a switch over the discriminant. In the `default` branch, assign to `never`: `const _exhaustive: never = shape`. → gate: add a new union member (`Square`) without adding a case — `tsc` reports "Type 'Square' is not assignable to type 'never'" immediately.
4. If the switch is in a function that must return a value, throw in the default: `throw new Error('Unhandled shape: ' + (shape as any).kind)`. This satisfies `noImplicitReturns` and provides a runtime safety net for values that enter the union after a bad cast.
5. Use `satisfies` (not `as`) when constructing union members to validate the literal shape while preserving the inferred specific type. → gate: attempting `const s = { kind: 'circle' } satisfies Shape` with a missing `radius` field produces a compile error, not a runtime one.

---

## Decision Scenarios

**Scenario 1 — A `.d.ts` declaration file promises a method that the underlying JS library does not export**

> **Situation:** A developer hand-writes a `.d.ts` file for an untyped legacy charting library. They add a `chart.destroy()` method to the declaration because they saw it mentioned in an old README. After shipping, users call `chart.destroy()` and get a runtime `TypeError: chart.destroy is not a function` on the current version of the library.

> **Competent move:** Audit the actual JS runtime export before declaring it. Load the library in a Node.js REPL and inspect its prototype, or read its source, before adding anything to the `.d.ts`. The declaration file must faithfully describe what the JS actually does — phantom declarations give TypeScript false confidence and shift the error from compile time to runtime.

> **Tempting-but-wrong:** Adding the declaration and leaving a `// TODO: verify this method exists` comment, deferring the audit to later. Until the comment is resolved, every caller that uses `chart.destroy()` compiles cleanly but crashes at runtime. "Works in TypeScript" gives no runtime guarantee when the declaration is a lie.

> **Verify:** In a test file, import the library and call the declared method in isolation. Run `node test.js` (not `tsc`) — the runtime will immediately throw if the method doesn't exist. Only after the runtime test passes should the declaration be considered correct.

---

**Scenario 2 — Structural typing allows an `OrderId` to be passed where a `UserId` is expected**

> **Situation:** A codebase uses `type UserId = string` and `type OrderId = string`. Both are aliases for `string`. A function `getOrder(userId: UserId, orderId: OrderId)` is called in one place with the arguments reversed — `getOrder(orderId, userId)`. TypeScript emits no error and the bug reaches production.

> **Competent move:** Use branded (nominal) types for distinct ID domains. A minimal brand: `` type UserId = string & { readonly __brand: 'UserId' } ``. Assign them via constructor functions: `function toUserId(s: string): UserId { return s as UserId }`. Now `UserId` and `OrderId` are structurally distinct and the compiler catches transposed arguments.

> **Tempting-but-wrong:** Adding a code comment like `// first arg must be userId` and relying on review. Comments do not survive refactoring. A structural type alias (`type UserId = string`) provides no compiler protection whatsoever — both types are assignment-compatible with each other and with `string`.

> **Verify:** After branding, swap the arguments intentionally and run `tsc`. The compiler should report "Argument of type 'OrderId' is not assignable to parameter of type 'UserId'." This is the compile-time guarantee the plain type alias could not provide.

---

**Scenario 3 — Overly broad generic constraint lets any object through instead of enforcing a minimum shape**

> **Situation:** A generic utility `function pluck<T, K extends keyof T>(obj: T, key: K): T[K]` is being used correctly. A developer then writes a new utility `function merge<T>(a: T, b: T): T` for merging config objects. Code review flags the `T` constraint as too broad — the function is called with non-plain-object values like arrays and class instances.

> **Competent move:** Add a constraint that matches the intended usage: `function merge<T extends Record<string, unknown>>(a: T, b: T): T`. This narrows `T` to plain object types and prevents accidental calls with arrays, primitives, or class instances, all of which would compile without the constraint. The constraint communicates intent and catches misuse at the callsite.

> **Tempting-but-wrong:** Removing generics entirely and typing the parameters as `object`. `object` excludes primitives but is too broad — it includes arrays and class instances — and the return type loses the specific shape of `T`, forcing callers to cast.

> **Verify:** Attempt to call `merge([1, 2], [3, 4])` with and without the `Record<string, unknown>` constraint. Without it, the call compiles silently. With it, TypeScript reports "Argument of type 'number[]' is not assignable to parameter of type 'Record<string, unknown>'."

---

**Scenario 4 — Runtime boundary: `unknown` API response cast with `as` instead of a runtime validator**

> **Situation:** A service receives a webhook payload, parses it with `JSON.parse`, and immediately casts: `const event = JSON.parse(body) as WebhookPayload`. The type checks pass. In production, a vendor changes the payload schema and omits a required field — the code silently proceeds with `undefined` where a string is expected, causing corrupt database writes.

> **Competent move:** Use a runtime validator (Zod, Valibot, or similar) to parse and validate the payload at the boundary: `const event = WebhookPayloadSchema.parse(JSON.parse(body))`. The validator throws on schema mismatch, turning a silent corruption into an explicit 400/500 error. The TypeScript type of `event` is then inferred from the schema — no `as` cast needed.

> **Tempting-but-wrong:** Adding defensive `if (event.field !== undefined)` checks throughout the business logic downstream. This scatters validation across the codebase and is easy to miss for new fields. Validating at the single entry point (the boundary) catches all failures in one place regardless of how many fields the payload has.

> **Verify:** Define a Zod schema that matches the expected payload. Call `.parse()` with a deliberately malformed payload (missing a required field). Confirm the validator throws a `ZodError` with a clear field-level message. Then confirm the correctly shaped payload parses cleanly and the inferred type matches.

---

**Scenario 5 — `unknown` vs `any` in an error-handling utility at an API edge**

> **Situation:** A shared `handleError(err: any)` utility function is used throughout the codebase to log and format errors. A junior engineer proposes changing `err: any` to `err: unknown` but a teammate objects that doing so will break every call site where `err.message` is accessed directly.

> **Competent move:** Change the parameter to `unknown` and add a type guard at the top of the function: `const message = err instanceof Error ? err.message : String(err)`. This is exactly the right design for a shared error handler — errors from any source (rejected Promises, thrown strings, legacy code) can have any shape. `unknown` forces the narrowing to happen inside the utility, once, rather than spreading unchecked `.message` access across every call site.

> **Tempting-but-wrong:** Keeping `err: any` to avoid touching existing code. `any` propagates upward — every downstream expression derived from `err` also becomes `any`, silently disabling type checking on anything the error touches. A single `unknown` + guard in the utility is a smaller and safer change than `any` left in place indefinitely.

> **Verify:** With `err: unknown` in place, attempt to access `err.message` directly (without a guard) inside the utility. `tsc` should report "Property 'message' does not exist on type 'unknown'." After adding the `instanceof Error` guard, the access compiles and the check is explicit.

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

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/typescript.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. `last-reviewed` set to 2026-06-09.

---

_Independent educational content to upskill AI agents. TypeScript is a trademark of Microsoft.
Not affiliated with or endorsed by Microsoft. Guidance only — verify against official
documentation at typescriptlang.org._
