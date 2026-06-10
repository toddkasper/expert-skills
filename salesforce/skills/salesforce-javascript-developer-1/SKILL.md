---
name: salesforce-javascript-developer-1
description: Lightning Web Components (LWC) and JavaScript for the Salesforce platform — wire adapters and Lightning Data Service, component lifecycle and decorators (@api/@track/@wire), custom events and shadow DOM, plus core JavaScript: ES6+ syntax, closures, prototypes, this-binding, the async/event loop, modules, Node.js, and Jest/LWC-Jest testing. Use when writing or reviewing LWC front-end code, or auditing JavaScript for coercion bugs, this-binding errors, unhandled rejections, or XSS. Not Apex/server-side logic (see salesforce-platform-developer-1). Scoped and benchmarked by the JavaScript Developer I (JS-Dev-101) blueprint.
metadata:
  credential: Salesforce Certified JavaScript Developer I
  exam-code: JS-Dev-101
  domain: salesforce
  type: certification-playbook
---

# Salesforce JavaScript Developer I — Skills Reference

## Overview

The Salesforce Certified JavaScript Developer I credential validates that a developer has
the knowledge and hands-on skills needed to build front-end and/or back-end JavaScript
applications for the modern web stack, including Salesforce-specific technologies such as
Lightning Web Components (LWC). Unlike most Salesforce certifications, this is
platform-agnostic: the multiple-choice exam tests general JavaScript fundamentals —
ES6+ syntax, DOM manipulation, asynchronous patterns, Node.js, debugging, and testing —
not Apex or declarative tooling.

The credential is a two-part requirement: a multiple-choice exam (JS-Dev-101, delivered
in a supervised setting) **and** the Lightning Web Components Specialist superbadge on
Trailhead. Both can be completed in either order.

This file is an **operational playbook**, not an exam outline. Each section states the
*rule* to apply at decision time, the *concrete limits/numbers*, the *decision criteria*,
and the *red flags* to catch in review. The rules apply to any JavaScript surface — React
front-ends, Node/Lambda back-ends, SFDX automation scripts — not just LWC authoring. Where
relevant, sections note how to verify field/record assumptions against a live Salesforce org
using describe/SOQL tooling before parsing a response or wiring a component.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Operational Knowledge by Topic

### Variables, Types, and Collections (23%)

**Default to `const`; use `let` only when you reassign; never use `var`.** `const`/`let` are
block-scoped and live in the temporal dead zone until declared — referencing them before
declaration throws `ReferenceError`. `var` is function-scoped and hoisted to `undefined`,
which silently produces wrong values instead of errors. In LWC and modern TS, `var` is a
red flag in any review.

**Prefer immutable array/object operations.** `.map()`, `.filter()`, `.reduce()`, `.slice()`,
spread return new values; `.push()`, `.pop()`, `.splice()`, `.sort()`, `.reverse()` mutate
in place. In LWC, a reactive property only re-renders when you assign a *new* reference —
mutating an array in place (`this.items.push(x)`) often won't trigger re-render. **Rule:
reassign with a new array** (`this.items = [...this.items, x]`).

**Type coercion decision table** — memorize these because exam questions and real bugs both
hinge on them:

| Expression | Result | Why |
|---|---|---|
| `"5" + 1` | `"51"` | `+` with a string concatenates |
| `"5" - 1` | `4` | `-` forces numeric coercion |
| `[] == false` | `true` | both coerce to `0` |
| `null == undefined` | `true` | special-cased by `==` |
| `null === undefined` | `false` | different types |
| `NaN === NaN` | `false` | use `Number.isNaN()` |
| `0 == ""` | `true` | both coerce to `0` |

**Always use `===` / `!==`.** Loose `==` triggers coercion and is a red flag except the
single idiomatic `x == null` (catches both `null` and `undefined`). Falsy values are exactly:
`false`, `0`, `-0`, `0n`, `""`, `null`, `undefined`, `NaN`. Everything else (including `"0"`,
`[]`, `{}`) is truthy — a common source of validation bugs.

**JSON round-trips lose data.** `JSON.stringify` drops `undefined`, functions, and symbols;
converts `Date` to an ISO string (no auto-revival); throws on `BigInt` and circular refs.
This bites any pipeline that serializes records to JSON (e.g. snapshotting a payload to
storage, or extracting a nested sub-object from a JSON blob). **Red flag:** relying on a
`Date` surviving a JSON round-trip, or assuming `undefined` fields persist.

**Use `Map`/`Set` for lookups and dedupe, not object-as-dictionary.** `Set` for uniqueness,
`Map` for keyed collections with non-string keys or guaranteed insertion order. This is the
JS mirror of the Apex bulkification pattern: query once into a `Map` keyed by Id, then resolve
in memory instead of repeated lookups.

**Verify against the live org:** when parsing an API/SOQL response, confirm the actual field
shape with a describe call before assuming a field is a string vs. a number vs. a picklist —
coercing a Salesforce number field through string logic is a classic data-loss bug.

---

### Objects, Functions, and Classes (25%)

**`this` binding decision table** — the single most-tested concept; get it wrong and event
handlers silently break:

| Form | What `this` is |
|---|---|
| `function() {}` standalone call | `undefined` (strict/module) or global |
| `obj.method()` | `obj` (the receiver) |
| arrow function | inherited from enclosing lexical scope (no own `this`) |
| `fn.call(ctx)` / `fn.apply(ctx)` | `ctx` (apply takes args as array) |
| `fn.bind(ctx)` | returns a new function permanently bound to `ctx` |
| class method passed as callback | loses `this` unless bound or arrow |

**In LWC, write event handlers as arrow-assigned class fields or rely on the framework's
auto-binding for `handleX` template handlers.** A `addEventListener('click', this.handleClick)`
passed a regular method loses `this`. **Red flag:** a class method referenced as a bare
callback without `.bind(this)` or arrow wrapping.

**Use closures deliberately for private state and memoization; watch for the loop-capture
trap.** A classic bug: `for (var i…)` inside a closure captures the *final* `i`. Fixed by
`let` (per-iteration binding). This is exactly why `var` is banned.

**Prefer `Object.entries()`/`Object.values()`/spread over manual `for…in`.** `for…in` walks
the prototype chain — guard with `hasOwnProperty` or it leaks inherited keys. Spread
(`{...a, ...b}`) does a shallow merge; nested objects are shared by reference — a frequent
source of "I mutated one and the other changed" bugs.

**Classes are prototype sugar.** `extends` + `super()` set up the prototype chain; you must
call `super()` before using `this` in a subclass constructor or it throws. Use `#private`
fields for true encapsulation (not the `_underscore` convention). Static methods live on the
constructor, not instances.

**Modules: prefer named exports for tree-shaking and refactor-safety; one default export max
per module.** `import` is hoisted and live-bound (you see later mutations of an exported
`let`); `require` (CommonJS) is evaluated at call site and gives a snapshot. **Don't mix
`require` and `import` in the same module** — a mixed front-end (ES modules) / Node-scripts
(CommonJS) codebase is common, but keep each module consistent.

**Decorators in LWC:** `@api` (public reactive property/method — parent-settable),
`@track` (rarely needed now; fields are reactive by default, `@track` only forces deep
reactivity on object/array internals), `@wire` (declarative data binding to an adapter or
Apex method). **Red flag:** using `@track` on a primitive (unnecessary since Spring '20) or
mutating a `@wire`-provisioned value (it's read-only — copy it first).

**Verify against the live org:** before wiring an LWC `@wire(getRecord, { fields })`, confirm the
field API names with a describe call — a wrong field name fails silently or returns
`undefined`, not an error. Use a SOQL query to confirm the record shape the component expects.

---

### Browser and Events (17%)

**Use `textContent`, never `innerHTML`, for untrusted data.** `innerHTML` parses and executes
markup — an XSS vector. In LWC this is enforced (Lightning Locker / Lightning Web Security
sandboxes the DOM and blocks most direct DOM access), but in a React front-end the same
rule holds: **rendering user input through `innerHTML`/`dangerouslySetInnerHTML` is a hard
red flag**, all the more so for apps handling PII or sensitive documents.

**Event propagation: capturing → target → bubbling.** `addEventListener(type, fn, true)`
listens in the capture phase; default is bubbling. `stopPropagation()` halts further
travel; `preventDefault()` cancels the default action (e.g. form submit) but does NOT stop
propagation — they are independent. **Red flag:** calling `preventDefault()` expecting it to
stop bubbling.

**Use event delegation for dynamic lists** — attach one listener on the parent, read
`event.target`. `target` is what was clicked; `currentTarget` is what the listener is attached
to. Confusing the two breaks delegation logic.

**LWC custom events:** dispatch with `new CustomEvent('mychange', { detail, bubbles, composed })`.
By default LWC events do NOT bubble and do NOT cross the shadow boundary. To reach a grandparent
you must set `bubbles: true` and `composed: true` — but compose-crossing is discouraged for
encapsulation. **Lowercase, no-hyphen event names** are required. This is the standard
child→parent pattern for multi-step forms: step components emit events upward to the container.

**Always pair `addEventListener` with `removeEventListener`** (in LWC, add in
`connectedCallback`, remove in `disconnectedCallback`) or you leak listeners and memory.

**Debounce expensive handlers** (search-as-you-type, address autocomplete). Debounce (~300ms)
to respect third-party API rate limits and avoid hammering the API on every keystroke.
`setTimeout`/`clearTimeout` is the building block; `setInterval` for polling must always have
a `clearInterval` exit.

**`fetch()` does NOT reject on HTTP 4xx/5xx** — it only rejects on network failure. You must
check `response.ok` / `response.status` yourself. **Red flag:** `await fetch(...)` followed by
`.json()` with no status check — a 500 returning an HTML error page will throw an opaque JSON
parse error instead of surfacing the real failure.

**Verify against the live org:** for any component reading config or tokens, never read PII into
`localStorage` — keep PII out of browser-at-rest storage, and prefer write-only bearer tokens
over stored identity for unauthenticated flows.

---

### Asynchronous Programming (13%)

**Event-loop execution order:** synchronous code first → drain ALL microtasks (resolved
Promise `.then`/`.catch`/`.finally`, `queueMicrotask`) → then ONE macrotask (`setTimeout`,
`setInterval`, I/O). After each macrotask, microtasks drain again. This is the heart of the
exam's "predict the output" questions. Canonical order: a `Promise.resolve().then()` logs
*before* a `setTimeout(…, 0)` even though both look "deferred."

**`async` functions always return a Promise**; `await` unwraps it and suspends only the async
function, not the thread. A thrown error inside an `async` function becomes a rejected Promise.

**Sequential vs. parallel — the decision that matters for performance:**

| Need | Use | Anti-pattern |
|---|---|---|
| Independent fetches, want all | `await Promise.all([a(), b()])` | awaiting each in sequence |
| Independent, tolerate partial failure | `Promise.allSettled([…])` | `Promise.all` (one reject kills all) |
| First to resolve/reject wins | `Promise.race([…])` | manual flags |
| First to *resolve* (ignore rejects) | `Promise.any([…])` | `race` (rejects propagate) |
| Each depends on the prior | sequential `await` in a loop | `Promise.all` (breaks ordering) |

**Red flag:** awaiting independent operations one at a time in a loop when they could run in
parallel via `Promise.all` — turns N×latency into 1×latency. Conversely, **firing
order-dependent DML/writes in parallel** corrupts ordering. For LWC + Apex, use `Promise.all`
to fan out independent `@wire`/imperative Apex calls.

**Always handle rejections.** An unhandled rejected Promise crashes Node processes and logs
`UnhandledPromiseRejection`. Wrap `await` in `try/catch`, or chain `.catch()`. **Red flag:** a
floating Promise (`doAsync();` with no `await` and no `.catch`).

**Never log PII in an async error path.** Catch SF/REST errors and log only non-identifying
keys (record IDs, request IDs) — never names, addresses, medical info, or file contents. Map
errors to HTTP status at the handler boundary; never leak Salesforce error detail to the client.

**Verify against the live org:** when building a parallel-fetch component, confirm each query is
genuinely independent by checking object relationships with a describe/graph-traversal call —
a child query that needs a parent Id is sequential, not parallel.

---

### Server-Side JavaScript / Node.js (8%)

**Know the runtime version your environment pins** (e.g. Node 20.x for current Lambda/CDK
toolchains). Know `node`, `npm`, `npx`, and the `package.json` fields. `dependencies` ship to
production; `devDependencies` (test/build tools like Vitest, Playwright, CDK) do not. **Red
flag:** a runtime import (e.g. an SF client or `aws-sdk v3`) sitting in `devDependencies`, or a
test-only tool in `dependencies` bloating the Lambda bundle.

**Semver ranges:** `^1.2.3` allows `<2.0.0` (minor+patch), `~1.2.3` allows `<1.3.0` (patch
only), exact `1.2.3` pins. `package-lock.json` is the source of truth for reproducible
installs — commit it; CI uses `npm ci` (clean, lockfile-exact) not `npm install`.

**Core modules to reach for:** `fs`/`fs/promises` (prefer the promise API), `path` (always
build paths with `path.join`, never string concatenation), `process.env` (config/secrets,
typically populated from a parameter/secret store), `process.argv` (CLI args in scripts),
`stream` (large files — stream large objects, don't buffer a whole file into memory).

**Red flag:** synchronous `fs.readFileSync` / blocking calls inside a Lambda handler hot path,
or buffering large files instead of streaming.

---

### Debugging and Error Handling (7%)

**Throw `Error` (or a subclass), never a string or plain object.** Only real `Error` objects
carry a stack trace. Subclass for typed handling: **throw typed errors from `lib/`, catch at
the handler boundary, map to HTTP status.**

**Error-type quick map:** `TypeError` (called/used a value of wrong type, e.g. `undefined is
not a function`), `ReferenceError` (used an undeclared/TDZ variable), `SyntaxError` (parse
time — won't reach runtime catch), `RangeError` (e.g. invalid array length, stack overflow).

**`try/catch` does NOT catch async errors that escape its synchronous frame.** A rejected
Promise inside a `try` without `await` is uncaught. `finally` runs regardless — use it for
cleanup, but a `return`/`throw` in `finally` overrides the try block (red flag).

**Read stack traces top-down** — the first frame is where it threw. For async, enable async
stack traces in DevTools/Node to see across `await` boundaries.

**Structured logging only.** Use `console.log` with structured JSON (CloudWatch and similar
ingest it), log non-identifying keys (record IDs, user/session IDs), **never PII**. **Red
flag:** `console.log(payload)` dumping a full object that contains names, addresses, or
medical info.

**Verify against the live org:** when a Salesforce write fails, reproduce against a sandbox with
a SOQL query to see the actual record state before guessing. A fast JWT/auth smoke test catches
auth/FLS/schema failures early.

---

### Testing (7%)

**Use your repo's runner** (e.g. Vitest); its API is Jest-compatible:
`describe` / `it`(`test`) / `expect`. For LWC specifically, `@salesforce/sfdx-lwc-jest` is the
required adapter (Node-based, no live org). Same matchers apply: `toBe` (Object.is / primitives),
`toEqual` (deep structural), `toContain`, `toThrow`, `toBeTruthy`.

**`toBe` vs `toEqual` is the most common testing mistake:** `toBe` fails on two structurally
equal objects (different references). Use `toEqual` for objects/arrays, `toBe` for primitives.

**Test behavior, not implementation.** A test that asserts internal call counts or private
fields breaks on every refactor — red flag. A good test asserts observable output for a given
input.

**Async tests must return or await the Promise** — a forgotten `await` produces a false
positive (test passes before the assertion runs). **Red flag:** an `async` test with assertions
after an un-awaited call.

**Mocking:** `jest.fn()`/`vi.fn()` for function stubs (`mockReturnValue`, `mockResolvedValue`
for async); `jest.mock()`/`vi.mock()` for module mocks. For LWC, mock `@salesforce/apex`
imports and wire adapters so tests never hit a real org. **Boundary cases matter most** — e.g.
"looks-like-a-date-but-isn't" inputs (`2026-02-31`), cross-field validation refinements, and
each discriminated-union branch. Prioritize those over happy-path coverage.

**Lifecycle hooks:** `beforeEach`/`afterEach` for per-test isolation (reset mocks here —
`vi.clearAllMocks()`), `beforeAll`/`afterAll` for expensive shared setup. Leaked state between
tests is a flakiness red flag.

**Coverage is a signal, not a target.** 100% line coverage with weak assertions is worse than
80% with strong ones. Branch coverage catches the un-tested `else`.

**Run before committing:** run the full test suite; never commit broken code — lint + build +
tests pass first.

---

## Operational Rules Quick Reference

- **DO** default to `const`, use `let` only on reassignment, **NEVER use `var`** (TDZ + block
  scope prevent whole classes of bugs).
- **DO** reassign a new array/object reference to trigger LWC reactivity; **DON'T** mutate in
  place and expect a re-render.
- **DO** use `===`/`!==` always; the only allowed loose check is `x == null`.
- **DON'T** trust a `Date`, `undefined`, function, or `BigInt` to survive `JSON.stringify` —
  it loses or throws.
- **DO** check `response.ok`/`response.status` after `fetch`; it does NOT reject on 4xx/5xx.
- **DO** use `Promise.all` for independent async work, `allSettled` to tolerate partial
  failure; **DON'T** await independent calls one-by-one in a loop.
- **DON'T** fire order-dependent writes in parallel.
- **DO** wrap every `await` in `try/catch` (or `.catch`); **DON'T** leave a floating Promise.
- **DON'T** render untrusted input via `innerHTML` / `dangerouslySetInnerHTML` (XSS).
- **DO** bind class-method callbacks (arrow field or `.bind(this)`); a bare method as a callback
  loses `this`.
- **DO** name LWC custom events lowercase/no-hyphen; they don't bubble or cross shadow boundary
  unless you set `bubbles`+`composed`.
- **DO** pair every `addEventListener`/`setInterval` with its remove/clear (LWC:
  connected/disconnectedCallback).
- **DO** debounce search/autocomplete handlers (~300ms) to respect API rate limits.
- **DO** throw real `Error` objects (stack trace); throw typed errors from `lib/`, map to HTTP
  at the handler boundary.
- **DON'T** log PII — log non-identifying record/session IDs only; never the full payload.
- **DON'T** leak Salesforce error detail to the client.
- **DO** keep runtime deps in `dependencies`, test/build tools in `devDependencies`; CI uses
  `npm ci`.
- **DO** stream large files; **DON'T** buffer them or use sync `fs` in a Lambda hot path.
- **DO** use `toEqual` for objects, `toBe` for primitives; test behavior, not implementation.
- **DO** return/await async test Promises; reset mocks in `beforeEach`.
- **DO** verify field API names with a describe call and record shape with a SOQL query
  before wiring `@wire`/parsing a response — wrong field names fail silently.

---

## Blueprint coverage notes

Two topic clusters appear in the official exam blueprint that the sections above touch only lightly:

**Iterators, generators, and `Symbol`** — A generator function (`function*`) returns an iterator
that produces values lazily on each `.next()` call. A value is a `{ value, done }` pair. Any object
that defines `[Symbol.iterator]()` is iterable and can be consumed by `for…of`, spread, or
destructuring. `Symbol` itself is a primitive that creates a guaranteed-unique property key —
useful for "private" or collision-free metadata on objects you don't own. **Red flag:** spreading
an object (not an array) expecting `Symbol.iterator` — plain objects are not iterable by default.

**`WeakMap`, `WeakRef`, and memory management** — `WeakMap` and `WeakSet` hold their keys by weak
reference: if no other reference to the key exists, the entry can be garbage-collected without any
action from you. This makes `WeakMap` the right structure for associating private metadata with DOM
nodes or component instances without preventing cleanup. `WeakRef` wraps any object; `.deref()`
returns the object or `undefined` if it has been collected. **Decision rule:** use `Map` when you
need guaranteed iteration or size; use `WeakMap` when the collection should not keep objects alive.
**Red flag:** caching component metadata in a plain `Map` keyed by component instance — the map
holds a strong reference and prevents GC of detached components.

---

## Decision scenarios

### Scenario 1 — LWC reactive array mutation

**Situation:** A developer has a `@track`-free LWC component with a `contacts` property (an array).
In a button handler they write `this.contacts.push(newContact)` to add a record. The template has
a `for:each` loop over `contacts`, but after clicking the button the new row never appears.

**Competent move:** Replace the mutation with a new-array assignment:
`this.contacts = [...this.contacts, newContact]`. LWC's reactivity system tracks property
assignments, not mutations of the object at that property. A `push` modifies the existing array
in place — LWC never sees a new value on `this.contacts`, so it skips the render cycle.

**Tempting-but-wrong:** Adding `@track` to `contacts` hoping it will detect the internal mutation.
Since Spring '20, `@track` enables *deep* reactivity on object/array internals — so it would
actually fix this particular case — but it is the wrong teaching moment. `@track` is a band-aid
that masks the real rule; the canonical pattern is the immutable reassignment, which works
whether or not `@track` is present and makes the data flow obvious.

**Verify:** In the LWC jest test, assert the rendered item count before and after the simulated
click. If the count does not increase, the mutation is the culprit. In a scratch org, open the
browser DevTools, set a breakpoint in the handler, and confirm via console that the property
reference changes (new array object) after the fix.

---

### Scenario 2 — `this` lost in a class-method event callback

**Situation:** A developer writes an LWC component that must listen to a global `resize` event.
In `connectedCallback` they write `window.addEventListener('resize', this.handleResize)`. Inside
`handleResize` (a regular method), `this.someProperty` is `undefined`, causing a runtime TypeError.

**Competent move:** Change the assignment to an arrow function class field:
`handleResize = () => { ... }` — or wrap the reference: `window.addEventListener('resize',
this.handleResize.bind(this))`. Arrow class fields capture `this` at class instantiation time and
never rebind, so `this` inside the method always refers to the component instance.

**Tempting-but-wrong:** Moving the logic inline: `window.addEventListener('resize', () =>
this.handleResize())`. This fixes `this` but makes cleanup impossible — the anonymous arrow has
no stable reference. The paired `removeEventListener` in `disconnectedCallback` must receive the
exact same function reference that was registered; an anonymous wrapper cannot be deregistered,
leaking the listener.

**Verify:** In the LWC jest test, call `connectedCallback()`, then simulate a resize event, and
assert the expected side effect. A test that uses `vi.spyOn` on the component method and confirms
it was called with the right `this` context catches the binding bug. In a live org, open DevTools
Memory panel and profile for detached-listener count after repeated navigation away from the
component.

---

Two additional scenarios (fetch status-check omission, parallel vs. sequential Apex calls) are in [references/scenarios.md](references/scenarios.md).

---

## Study resources & relevance

Study resources (official Salesforce + community) are kept in [references/study-resources.md](references/study-resources.md). For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed
by, or sponsored by Salesforce or any certification body. "Salesforce," "Lightning Web Components,"
and "Trailhead" are trademarks of Salesforce, Inc.; all other product names and trademarks belong
to their respective owners. Guidance only — verify all details against official Salesforce
documentation and live orgs before acting. No certification outcome is implied or guaranteed.
Blueprint weights and exam fees are subject to change; check the current official exam guide.
