# TypeScript — Study Resources

> Loaded on demand. Contains learning resources only — operational rules live in `../SKILL.md`.

## Official Documentation

- **TypeScript Handbook** — https://www.typescriptlang.org/docs/handbook/intro.html
  Primary reference. Chapters: Basic Types, Narrowing, Functions, Object Types, Generics,
  Conditional Types, Mapped Types, Template Literal Types, Declaration Files, Modules.
- **TSConfig Reference** — https://www.typescriptlang.org/tsconfig/
  Authoritative list of every compiler option with examples. Start here before Googling a flag.
- **Release Notes index** — https://www.typescriptlang.org/docs/handbook/release-notes/overview.html
  Per-version notes back to 1.1. Read the notes for any version you adopt.
- **TypeScript 6.0 announcement** — https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/
  Documents the breaking-changes release (strict true by default, ESM defaults, removed legacy
  module targets).
- **TypeScript 5.9 release notes** — https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html
- **DefinitelyTyped** — https://github.com/DefinitelyTyped/DefinitelyTyped
  Source for `@types/*` packages. Read the contributing guide before authoring new declaration files.
- **TypeScript playground** — https://www.typescriptlang.org/play
  Quickly verify narrowing, inference, or error messages against a specific compiler version.

## Key Handbook Chapters (by topic)

| Topic | Chapter |
|---|---|
| Structural typing, widening, literal types | The Basics + Everyday Types |
| Narrowing and control-flow analysis | Narrowing |
| Discriminated unions, exhaustiveness | Narrowing → Discriminated unions |
| Generics, constraints | Generics |
| Conditional + mapped types, utility types | Type Manipulation section |
| `satisfies`, `infer`, template literals | Type Manipulation section |
| Declaration files (`.d.ts`) | Declaration Files section |
| Module output, `moduleResolution` | Modules section |
| Project references | Project References |

## Recommended Community Resources

- **Effective TypeScript (Dan Vanderkam)** — book; focuses on 62 concrete items, organized around
  "things the TypeScript type system does that surprise people." Good for developers who have
  basics down and want to reason more precisely.
- **Matt Pocock / Total TypeScript** — https://www.totaltypescript.com/
  Free workshops and tips, strong on advanced type-level patterns and generics. Grounded in
  real-world React/Node codebases.
- **TypeScript Deep Dive (Basarat)** — https://basarat.gitbook.io/typescript/
  Free online book; useful quick reference for declaration files and module resolution.

## Versioning Reference (as of 2026-06-07)

| Version | Release | Notes |
|---|---|---|
| TypeScript 6.0 | March 2026 | Last JS-compiled release; strict true default; ESM default; ES5 target dropped |
| TypeScript 5.9 | ~Q1 2026 | `import defer`, `--module node20`, performance improvements |
| TypeScript 5.8 | March 2025 | Various inference improvements |
| TypeScript 5.7 | November 2024 | Uninitialized variable detection improvements |
| TypeScript 5.0 | March 2023 | Stable decorators (TC39), `const` type parameters |

TypeScript 7.0 (Go-native rewrite) is in development; target mid-to-late 2026. Expect further
breaking changes: all 6.0-deprecated options will be removed.

---

_Independent educational content. TypeScript is a trademark of Microsoft. Not affiliated with
or endorsed by Microsoft._
