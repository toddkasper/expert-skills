# Answer key — typescript (grading rubric)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

PASS = competent move identified AND trap avoided. Partial = right instinct, misses the rule/trap.

1. **Competent:** TypeScript 6.0 changed the default for `"types"` from `["*"]` (load all installed
   `@types`) to `[]` (load none). `@types/jest` is installed but no longer auto-loaded, so Jest
   globals disappear. The fix is to add `"types": ["jest"]` (and any other needed `@types`) to
   `compilerOptions` in `tsconfig.json`. **Trap:** reinstalling `@types/jest`, blaming a Jest
   config change, or adding a triple-slash reference comment everywhere instead of fixing tsconfig
   once. **Verify:** rebuild — `describe`/`it` resolve without errors; check that no other
   previously auto-loaded `@types` went silent (e.g. `@types/node`).

2. **Competent:** The combination `"module": "esnext"` + `"moduleResolution": "nodenext"` is
   invalid — `nodenext` module resolution enforces explicit `.js` extension requirements and pairs
   with `"module": "nodenext"` (or `node20`), not `esnext`. For a Node.js library they should use
   `"module": "nodenext"` + `"moduleResolution": "nodenext"` (or the `node20` alias for stability).
   `allowImportingTsExtensions` is a bandage that does not fix the mismatched resolution strategy.
   **Trap:** accepting `allowImportingTsExtensions` as a fix, or assuming any `nodenext`
   combination is valid. **Verify:** CI passes after correcting both `module` and
   `moduleResolution`; relative imports resolve without extension errors.

3. **Competent:** Returning `any` from a public API function defeats type checking for every
   caller — the compiler cannot catch misuse of the returned value. The author should model the
   expected return type concretely (e.g. `Config`, `ParsedConfig`, etc.) and use a runtime
   validator such as Zod or Valibot to parse and type-narrow `raw`, letting the validator produce
   the typed output. The function signature becomes `parseConfig(raw: string): Config`. **Trap:**
   returning `unknown` as a substitute without fixing the type model, or casting the parsed result
   with `as Config` instead of validating it. **Verify:** remove `any`; ensure callers get
   autocomplete and type errors on misuse of the returned type.

4. **Competent:** In TypeScript 6.0, `useUnknownInCatchVariables` is on by default (it is part of
   `strict`), so `e` is typed `unknown` — not `any`. Accessing `e.message` directly is a type
   error because `unknown` has no properties. The correct fix is to narrow first:
   `if (e instanceof Error) console.error(e.message);` or use a type predicate. **Trap:** adding
   `// @ts-ignore` or casting `e as Error` without checking — this compiles but throws at runtime
   when the thrown value is not an `Error` instance (e.g. a rejected string or plain object).
   **Verify:** the narrowed branch compiles; remove the cast and confirm the code handles non-Error
   rejections safely.

5. **Competent:** Add an exhaustiveness check in the `default` branch by assigning `s` to `never`:
   ```ts
   default: {
     const _exhaustive: never = s;
     throw new Error("Unhandled shape: " + (s as any).kind);
   }
   ```
   When `triangle` is added to `Shape` without a corresponding `case`, the compiler errors on the
   `never` assignment before the code ships. **Trap:** adding a runtime `throw` without the `never`
   assignment (fails silently at compile time when a new member is added), or using a non-exhaustive
   approach like `return 0` in the default. **Verify:** add `triangle` to `Shape` and confirm tsc
   reports an error on the unhandled default branch.

6. **Competent:** Declare the type parameter with the `const` modifier (TS 5.0+):
   ```ts
   function identity<const T>(x: T): T { return x; }
   ```
   This causes TypeScript to infer literal types at the call site — `tag` is inferred as `"admin"`
   rather than `string` — without requiring callers to write `as const`. **Trap:** instructing
   callers to write `identity("admin" as const)` (pushes burden to every call site), or widening
   the constraint to `<T extends string>` without `const` (still infers `string`). **Verify:** in
   the playground or with `tsc --noEmit`, confirm `typeof tag` is `"admin"` not `string`.

7. **Competent:** `strict: false` permanently is the wrong approach for new code — it leaves the
   codebase without the most important guards. The correct pattern for gradual migration is to set
   `"strict": false` temporarily and enable flags one at a time, starting with `strictNullChecks`
   — it has the highest value-to-effort ratio because it catches the most real bugs (null
   dereferences) with a tractable, focused error set. Leave a tsconfig comment marking which flags
   remain to be enabled. **Trap:** leaving `strict: false` permanently or enabling all flags at
   once (overwhelming backlog). **Verify:** `strictNullChecks` is set to `true` independently;
   remaining flags tracked in tsconfig comments or a migration ticket.

8. **Competent:** No, it will not compile. Without `exactOptionalPropertyTypes`, `timeout?: number`
   implicitly means `number | undefined`, so assigning `undefined` explicitly is allowed. With the
   flag enabled, an optional property (`?`) means the key may be *absent* — it does not mean the
   value can be `undefined`. Writing `{ timeout: undefined }` sets the key to `undefined`, which
   is distinct from omitting the key. The author must either omit the property entirely
   (`const cfg: Config = {}`) or change the type to `timeout?: number | undefined`. **Trap:**
   assuming optional always includes `undefined` as an assignable value (true without the flag,
   false with it). **Verify:** enable `exactOptionalPropertyTypes`; confirm `{ timeout: undefined }`
   errors; confirm `{}` compiles.

9. **Competent:** Add `"declarationMap": true` to `compilerOptions`. This emits a `.d.ts.map` file
   alongside each `.d.ts`, which maps type declarations back to the original `.ts` source. Editors
   that support source maps will then jump to the `.ts` source file rather than the generated
   `.d.ts`. **Trap:** setting `"sourceMap": true` (this maps JS to TS, not `.d.ts` to `.ts`) or
   telling the consumer to install the source themselves. **Verify:** after rebuild and `npm
   publish` (or in a local link), "go to definition" in VS Code or another LSP client lands in the
   `.ts` file.

10. **Competent:** Use TypeScript project references. Each package's `tsconfig.json` needs
    `"composite": true` (which implies `"declaration": true`). The root or consumer package lists
    dependencies in a `"references": [{ "path": "../core" }, { "path": "../ui" }]` array. Build
    with `tsc --build` (or `tsc -b`) to traverse the reference graph and incrementally type-check
    all packages. **Trap:** setting a single root tsconfig with a merged `include` glob across all
    packages (loses incremental checking, misses cross-package type errors at boundaries), or the
    teammate's proposal to copy files (breaks encapsulation and deduplicates types). **Verify:**
    introduce a deliberate type error in `core`; confirm `tsc -b` from the repo root catches it.

11. **Competent:** `JSON.parse` returns `any`, and casting it with `as WebhookEvent` is a
    structural lie — the runtime value is never checked against `WebhookEvent`'s shape. If the
    webhook payload changes or arrives malformed, the code silently passes bad data downstream and
    crashes unpredictably. The correct replacement is a runtime validator (Zod, Valibot, etc.):
    ```ts
    const event = WebhookEventSchema.parse(JSON.parse(rawBody));
    ```
    The validator both asserts the shape at runtime and produces a properly typed output — no cast
    needed. **Trap:** replacing `as WebhookEvent` with `as unknown as WebhookEvent` (same problem,
    louder signal), or adding only a TypeScript type assertion thinking it provides runtime safety.
    **Verify:** send a malformed payload; confirm the validator throws a descriptive error rather
    than passing corrupted data to `processEvent`.

12. **Competent:** `R` is `string | number`, which is exactly what the engineer expects — but the
    reason is more subtle than they likely think. TypeScript conditional types are **distributive**
    over naked union type parameters: `Unwrap<Promise<string> | number>` is evaluated as
    `Unwrap<Promise<string>> | Unwrap<number>`, which yields `string | number`. This is correct
    and intentional behavior, not a bug. The gotcha comes when distribution is *not* wanted — for
    example, `Unwrap<Promise<string | number>>` gives `string | number` for a different reason
    (single `Promise` unwrapped), and wrapping `T` in a tuple (`[T] extends [Promise<infer U>]`)
    disables distribution. **Trap:** thinking `R` is `Awaited<Promise<string> | number>` (same
    result here, but confused rationale), or believing distribution is a bug to avoid by default.
    **Verify:** in the TypeScript playground, hover `R` to confirm `string | number`; then test
    with `[T] extends` to confirm distribution is suppressed.

13. **Competent:** The timeline claim is wrong. TypeScript 7.0 Beta shipped 2026-04-21, and the
    official announcement states stable release is expected within ~two months of Beta — placing
    stable around **June 2026**, not "late 2026." The team should start preparing now: audit
    `tsconfig.json` for all 6.0-deprecated options (`--baseUrl`, `--moduleResolution node`,
    `target: es5`, `--downlevelIteration`, `--esModuleInterop false`,
    `--allowSyntheticDefaultImports false`) and migrate them before upgrading, since 7.0 removes
    all of them. **Trap:** trusting an outdated or estimated "late 2026" date and deferring prep
    work; or assuming Beta = alpha-quality and ignoring it. **Verify:** check
    devblogs.microsoft.com/typescript for the 7.0 Beta announcement and RC schedule;
    run `tsc --version` after upgrade and confirm deprecated options now error.
    `[volatile — verify live]`

14. **Competent:** The guide is inaccurate. `target: es5` and `--downlevelIteration` are
    **deprecated** in TypeScript 6.0, not removed. They still work in 6.0 when
    `"ignoreDeprecations": "6.0"` is set in `compilerOptions`. They are scheduled for removal in
    TypeScript 7.0. A project that still needs them should add `"ignoreDeprecations": "6.0"` as a
    short-term bridge and track a follow-up task to migrate the target/iteration pattern before
    upgrading to 7.0. **Trap:** immediately deleting these options from tsconfig upon 6.0 upgrade
    without a migration plan (breaks polyfill-dependent or older-browser targeting), or confusing
    them with `--outFile` and `--moduleResolution classic` which *were* removed in 6.0.
    **Verify:** set `"ignoreDeprecations": "6.0"` and confirm the project builds; check the
    typescriptlang.org 6.0 release notes for the definitive removed-vs-deprecated split.

15. **Competent:** The likely cause is `strictBuiltinIteratorReturn`, added in TypeScript 5.6 and
    enabled by default in 6.0 as part of the nine-flag `strict` family. This flag changes the
    `TReturn` type of built-in iterators from `any` to `undefined`. Code that previously depended
    on the `TReturn` being `any` — for example, consuming the final `.value` of a generator's
    `done: true` result as a typed value — will now see `undefined` instead, causing downstream
    mismatches. The team should search for generator `.return()` / iterator `.next()` usages that
    assumed a non-`undefined` `TReturn`, add explicit return-type annotations to generators, and
    validate that completion values are handled correctly. **Trap:** blaming the TS 6.0 `target`
    or `module` default changes, or disabling `strict` entirely — neither addresses the root cause.
    **Verify:** isolate with a minimal generator that returns a value; confirm the type error names
    `strictBuiltinIteratorReturn`; fix the generator's return annotation.

16. **Competent:** The missing default is `libReplacement`, which changed from **`true`** to
    **`false`** in TypeScript 6.0. With `libReplacement: true` (the old default), TypeScript would
    attempt to resolve each `lib.*.d.ts` as a replaceable module — causing a large number of failed
    module-resolution lookups on every build and adding watch overhead. Setting the default to
    `false` improves cold-build and watch performance. For projects that use custom lib replacements
    (e.g. shipping a polyfilled `lib.dom.d.ts`), the option must now be explicitly set to `true`;
    without it the custom lib files are silently ignored. **Trap:** believing the wiki table is
    complete at six entries (it is seven in 6.0 — `strict`, `module`, `target`, `rootDir`, `types`,
    `noUncheckedSideEffectImports`, `libReplacement`); or not auditing custom-lib setups after
    upgrade. **Verify:** check `tsc --showConfig | grep libReplacement` in an affected project;
    confirm lib-replacement files are loaded only when the flag is explicitly re-enabled.
