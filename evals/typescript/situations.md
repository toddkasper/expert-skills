# Eval situations — typescript

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. You upgrade a large Node.js CLI project from TypeScript 5.8 to 6.0. After the upgrade, the build
   succeeds but `jest` no longer recognizes global types like `describe` and `it`, even though
   `@types/jest` is installed. What changed, and what is the minimal fix?

2. A teammate opens a PR for a new Node.js library package. The tsconfig sets `"module": "esnext"`
   and `"moduleResolution": "nodenext"`. CI fails with errors about missing `.js` extensions on
   relative imports. Your teammate says "just add `allowImportingTsExtensions`." Is that the right
   fix? What should you recommend instead, and why?

3. You're reviewing a pull request that adds a public API function with this signature:
   ```ts
   export function parseConfig(raw: string): any { ... }
   ```
   What is wrong with returning `any` here, and what should the author do instead?

4. A colleague writes a catch block like this:
   ```ts
   try { await fetchData(); }
   catch (e) { console.error(e.message); }
   ```
   The project uses TypeScript 6.0 with default settings. Will this compile? What is the problem
   and the correct fix?

5. You have a discriminated union:
   ```ts
   type Shape = { kind: "circle"; radius: number } | { kind: "square"; side: number };
   function area(s: Shape): number {
     switch (s.kind) {
       case "circle": return Math.PI * s.radius ** 2;
       case "square": return s.side ** 2;
     }
   }
   ```
   A third team adds `{ kind: "triangle"; base: number; height: number }` to `Shape`. How do you
   make the `area` function produce a **compile-time error** for the missing case, without changing
   the runtime behavior for existing shapes?

6. You are writing a generic helper:
   ```ts
   function identity<T>(x: T): T { return x; }
   const tag = identity("admin");
   ```
   The inferred type of `tag` is `string`, but you need it to be the literal `"admin"`. What is the
   correct, idiomatic TypeScript 5.0+ way to change the function so callers get literal inference
   without having to write `identity("admin" as const)`?

7. You're migrating a legacy JavaScript codebase to TypeScript. For the first week, the team wants
   type checking but doesn't want to fix hundreds of pre-existing `any` inference errors right away.
   A colleague suggests setting `"strict": false` in tsconfig and leaving it there permanently.
   What is the correct approach, and which single flag gives the highest value-to-effort ratio in
   early migration?

8. A developer adds a new optional property to a `Config` interface:
   ```ts
   interface Config { timeout?: number; }
   ```
   Then they write:
   ```ts
   const cfg: Config = { timeout: undefined };
   ```
   With `exactOptionalPropertyTypes: true` enabled, will this compile? Explain the distinction
   the flag enforces and what the author must do.

9. You are publishing a TypeScript library to npm. You set `"declaration": true` to emit `.d.ts`
   files. A consumer reports that "go to definition" in their editor jumps to the `.d.ts` file
   rather than the original `.ts` source. What single tsconfig option would fix this, and what does
   it produce?

10. A monorepo has three packages: `core`, `ui`, and `app`. Running `tsc` from the repo root type-
    checks only `app` and misses errors in `core` and `ui`. A teammate proposes copying
    `core`'s files into `app`'s `src/`. What is the correct monorepo solution, and what tsconfig
    fields are required in each package?

11. You're reviewing a module that parses a webhook payload like this:
    ```ts
    const event = JSON.parse(rawBody) as WebhookEvent;
    processEvent(event.type, event.data);
    ```
    What is the risk of this pattern, and what should replace it?

12. A utility type in your codebase conditionally unwraps a promise:
    ```ts
    type Unwrap<T> = T extends Promise<infer U> ? U : T;
    type R = Unwrap<Promise<string> | number>;
    ```
    A junior engineer expects `R` to be `string | number`. What is the actual type of `R`, why does
    it differ from the engineer's expectation, and is this behavior correct or a bug?
