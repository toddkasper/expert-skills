---
name: nodejs
description: Building and reviewing Node.js applications and services — the event loop and async patterns, streams and buffers, the module system (ESM/CJS), packaging and the toolchain, error handling and diagnostics, and HTTP services with security. Use when writing, reviewing, or debugging Node.js code, CLIs, services, or AWS Lambda handlers. Stays on the Node runtime; excludes React (see react), Next.js (see nextjs), and TypeScript typing (see typescript). Competence skill mapped to the retired OpenJS JSNAD/JSNSD curriculum.
metadata:
  credential: OpenJS Node.js Application Developer (JSNAD) / Services Developer (JSNSD) — both retired September 30, 2025
  domain: web
  type: certification-playbook
  blueprint: JSNAD / JSNSD curriculum (retired Sep 2025 — used as competence map only)
---

# Node.js — Skills Reference

## Overview

A strong Node.js engineer reasons about the runtime, not just the library. That means understanding how the event loop schedules work, how to move data through streams without blowing memory, how modules resolve at runtime vs at build time, and how to keep services secure against injection and header-based attacks. The retired OpenJS exams (JSNAD and JSNSD) are used here only as a public competence map — they defined what practitioners must know without being about the exam itself.

> **Deeper context:** Study resources, certification history, and learning paths live in [references/study-resources.md](references/study-resources.md). Load that file when planning a study path. Sibling skills: `typescript`, `react`, `nextjs`, `react-native`.

---

## Certification Details

**Both JSNAD and JSNSD were retired September 30, 2025.** As of June 2026, no official successor has been announced. The facts below describe the exams as they existed — useful for understanding the competence bar, not for registration.

| Field | JSNAD | JSNSD |
|---|---|---|
| Full name | OpenJS Node.js Application Developer | OpenJS Node.js Services Developer |
| Status | **Retired Sep 30, 2025** | **Retired Sep 30, 2025** |
| Format | Remote-proctored, performance-based (live coding in browser VM) | Same format |
| Duration | 2 hours | 2 hours |
| Passing score | 68% | 68% |
| Cost (at retirement) | $300 USD (free retake included) | $300 USD (free retake included) |
| Allowed resources | nodejs.org and npm docs only; StackOverflow blocked | Same |
| Prerequisites | None formal; 2+ years Node.js recommended | None formal |
| Task count (approx.) | ~25 coding tasks, 5–10 min each | ~4–5 longer tasks, 15–30 min each |

> Passing score (68%) is confirmed from multiple first-hand candidate reports and the archived Linux Foundation FAQ. Cost ($300) is confirmed from multiple sources at or near retirement; earlier it was $200. Task counts are best estimates from candidate reports, not official figures.

**JSNAD domain weights** (from the official curriculum PDF, confirmed by multiple sources):

| Domain | Weight |
|---|---|
| Control flow | 12% |
| Buffers & Streams | 11% |
| Events | 11% |
| Child processes | 8% |
| Error handling | 8% |
| File system | 8% |
| JavaScript prerequisites | 7% |
| Module system | 7% |
| Debugging / Diagnostics | 6% |
| Process / OS | 6% |
| package.json | 6% |
| Unit testing | 6% |
| Node.js CLI | 4% |

**JSNSD domain weights:** Servers & Services 70%, Security 30%.

---

## 1. Async Node.js and the Event Loop

The event loop is the single most misunderstood aspect of Node.js. Every performance problem traces back to either blocking the loop or failing to handle backpressure.

**Event loop phases (in order):** timers (`setTimeout`/`setInterval`) → pending I/O callbacks → idle/prepare → poll (new I/O) → check (`setImmediate`) → close callbacks. Then repeat.

**Microtask queue runs between every phase** — and `process.nextTick()` drains before Promises. Order within a tick: `nextTick` queue → Promise microtask queue → next event loop phase. Stacking `nextTick` callbacks recursively starves I/O permanently.

**The #1 rule: never block the event loop.** Blocking calls — `fs.readFileSync`, `crypto.pbkdf2Sync`, `zlib.gzipSync`, JSON.parse on a 10 MB payload — stop all I/O for every other client until they return. Use async variants. For CPU-bound work (image processing, compression, heavy computation), offload to `worker_threads` — not `child_process.fork()` which has IPC overhead, and not `setImmediate` which just defers to the next tick on the same thread.

**async/await pitfalls:**

| Pattern | Problem | Fix |
|---|---|---|
| `await` in a `for` loop | Serializes iterations — N×latency | `Promise.all()` / `Promise.allSettled()` for parallel |
| Unhandled rejection | Crashes process in Node 15+ | Always `.catch()` or `try/catch` in `async` |
| `await` on `EventEmitter` event | Race: event may fire before `await` | Use `events.once()` which returns a Promise |
| Forgetting `await` on an async call | Silent fire-and-forget, errors swallowed | Lint with `no-floating-promises` |
| Mixing callbacks with `async/await` | Error handling logic splits | Promisify at the boundary with `util.promisify` |

**EventEmitter rules:**
- Attach error listeners before emitting anything — an unhandled `error` event throws.
- Remove listeners when done (`emitter.off()` / `removeListener`) to prevent memory leaks; `once()` removes itself automatically.
- `setMaxListeners(n)` adjusts the default warning threshold of 10 (useful for intentional high-fan-out patterns, never to silence leaks).

**Red flags in review:** synchronous `*Sync` call in a request handler or hot path; `process.nextTick` recursion; `new Promise` constructor wrapping an async function (promise constructor anti-pattern); missing error listener on EventEmitter; `await` inside a `forEach` (forEach ignores returned Promises).

---

## 2. Streams, Buffers & the Filesystem

**Use streams for anything that doesn't need to fit in memory at once.** Reading a 2 GB file into a Buffer and then writing it out causes a 2 GB memory spike. Streaming it uses a small, bounded buffer.

**Stream types:** Readable, Writable, Duplex (both), Transform (Duplex that modifies data). All are `EventEmitter`s.

**Use `stream.pipeline()` — not `.pipe()`** for production code. `pipeline()` wires sources, transforms, and sinks with automatic backpressure and end-to-end error propagation and cleanup. `.pipe()` does not propagate errors — a source error leaves the destination open.

```js
const { pipeline } = require('node:stream/promises');
await pipeline(readableSource, transformStep, writableDest);
```

**Backpressure — the rule:** when `writable.write()` returns `false`, the consumer's buffer is full. Stop sending: pause the readable (`.pause()`) and wait for the `drain` event before resuming. `pipeline()` handles this automatically. `highWaterMark` (default 16 KB for byte streams, 16 objects for object-mode streams) controls the buffer ceiling.

**Buffer:** fixed-size raw memory outside V8's heap. Created with `Buffer.alloc(n)` (zero-fills — safe) or `Buffer.allocUnsafe(n)` (faster but contains old memory — only use when immediately overwriting). Never create Buffers from user-supplied length without range-checking — a huge `n` is a DoS vector. Encode/decode with `buf.toString('utf8')` / `Buffer.from(str, 'utf8')`.

**Filesystem patterns:**

| Operation | Use | Why |
|---|---|---|
| Stream large files | `fs.createReadStream` + `pipeline` | Bounded memory |
| Small config / key files | `fs.promises.readFile` | Simple, one round-trip |
| Atomic writes | Write to `.tmp`, then `fs.rename` | Rename is atomic on POSIX; prevents partial reads |
| Directory walking | `fs.promises.opendir` / async iteration | Avoids loading full readdir array in memory |
| Watch for changes | `fs.watch` (not `watchFile`) | `watchFile` polls; `fs.watch` uses OS events |

**`child_process`:** Use `spawn` for streaming I/O (logs, piped output); `exec` for small output where you want the full stdout/stderr as strings; `execFile` like `exec` but safer (no shell interpolation); `fork` for Node.js child workers with IPC. Never pass unsanitized user input into `exec` — use `spawn` with an args array to avoid shell injection.

**Red flags:** `.pipe()` without error handling; `Buffer.allocUnsafe` used for network-supplied sizes; `fs.readFileSync` in a request path; `exec` with user-controlled arguments; stream events (`data`, `end`, `error`) wired manually instead of `pipeline`.

---

## 3. Modules, Packaging & the Toolchain

**ESM vs CommonJS — the decision:**

| | CommonJS (CJS) | ESM |
|---|---|---|
| File extension | `.js` (default) / `.cjs` | `.mjs` / `.js` with `"type":"module"` |
| Load | Synchronous, dynamic | Async, static |
| Interop from CJS | `require('./foo.cjs')` works | `require('esm-only-pkg')` requires dynamic `import()` or Node ≥22 `require(esm)` (stable in Node 22) |
| Interop from ESM | `import cjsPkg from 'cjs-pkg'` works (default export = `module.exports`) | |
| Tree-shaking | ❌ (dynamic require) | ✅ (static analysis) |
| `__dirname` / `__filename` | Available | Not available — use `import.meta.url` + `fileURLToPath` |
| Top-level `await` | ❌ | ✅ |

**Rule for new projects: use ESM** (`"type":"module"` in `package.json`). For libraries that must support CJS consumers, publish a dual package using the `exports` map:

```json
"exports": {
  ".": {
    "import": "./dist/index.mjs",
    "require": "./dist/index.cjs"
  }
}
```

**`package.json` field decisions:**

| Field | Rule |
|---|---|
| `dependencies` | Runtime deps — what the app needs when installed by a consumer |
| `devDependencies` | Build/test only — never shipped in a production Docker image |
| `peerDependencies` | Libs that must share the host project's instance (React plugins, etc.) |
| `engines` | Pin the Node.js version range your code is tested against |
| `exports` | Use instead of `main` for new packages; enables subpath and condition-based resolution |
| `files` | Allowlist what goes into the npm tarball — never publish `src/`, `.env`, or test fixtures |

**`npm ci` vs `npm install`:**
- `npm ci` reads `package-lock.json` exactly, errors if lock and manifest diverge — use in CI and Docker builds.
- `npm install` resolves and updates the lock — use during development only.
- `npm audit --omit=dev` in CI; never ship unfixed critical vulnerabilities.

**Semver discipline:** `^` (caret) pins major, allows minor/patch — safe for most deps. `~` pins major+minor, allows patch — tighter. Exact pins (`"1.2.3"`) are appropriate for CLIs that users install globally; avoid for libraries (causes dep duplication).

**Red flags:** `devDependencies` in `dependencies` (bloats prod bundle); missing `engines` field in a published package; `npm install` in a Dockerfile (non-deterministic); unresolved `npm audit` critical findings; `require()` of an ESM-only package in a CJS file without dynamic import.

---

## 4. Error Handling & Diagnostics

**Async error propagation rules:**
- In `async/await` code: thrown errors and rejected Promises both surface as rejections — `try/catch` catches both.
- In callbacks: always check the first argument (`if (err) return cb(err)`). Never throw inside a callback — it goes to `uncaughtException`, not the caller.
- In streams: errors don't automatically propagate. `pipeline()` propagates; `.pipe()` does not. Always attach `.on('error', handler)` on every stream if using `.pipe()`.
- Global safety nets: `process.on('unhandledRejection', ...)` and `process.on('uncaughtException', ...)` are **last-resort loggers**, not error handlers. Log and exit — continuing after `uncaughtException` leaves the process in an unknown state.

**Error design:** extend `Error` for custom types; set `error.code` (string) for programmatic branching, not `error.message` (which is human-readable and can change). Operational errors (bad input, network timeout) vs programmer errors (null dereference) — operational errors can be recovered from; programmer errors should crash the process.

**Diagnostics:**

| Tool | Use |
|---|---|
| `node --inspect` / `--inspect-brk` | Attach Chrome DevTools or VS Code debugger; `--inspect-brk` pauses at first line |
| `node --prof` + `node --prof-process` | V8 CPU profiler; generates tick file → readable report |
| `node --heap-snapshot` / `v8.writeHeapSnapshot()` | Memory leak analysis via Chrome Memory tab |
| `NODE_OPTIONS='--max-old-space-size=512'` | Cap heap — forces OOM before silent memory spiral |
| `clinic.js` (npm) | Wraps `--prof` and `--trace-gc`; produces flame graphs, bubble charts |
| `node:trace_events` | Low-overhead async timeline; diagnose event-loop stalls |

**Logging:** structured JSON logs (one object per line) beat formatted strings because they're machine-parseable. Include `level`, `msg`, `timestamp`, and a `correlationId`/`requestId` on every request log. Never log passwords, tokens, or PII — scrub at the boundary. Use log levels (`error`, `warn`, `info`, `debug`) and disable `debug` in production by default.

**Red flags:** `try/catch` around an async function without `await` (the try block exits before the Promise settles — the rejection is unhandled); `uncaughtException` handler that continues normally; `console.error` as the only error logging (no structure, no correlation); using `error.message` for programmatic control flow.

---

## 5. HTTP Services & Security

This section maps to the JSNSD scope (Servers & Services 70%, Security 30%).

**Framework choice (for exam scope and common use):** Express.js is the default; Fastify is faster and schema-first (built-in JSON schema validation + serialization). Hapi is configuration-heavy; for bare Node.js: `node:http`. Prefer Fastify for new services — its schema validation catches injection vectors at the boundary.

**Input validation — the most important security layer:**
1. Validate **type, shape, length, and allowed values** before any business logic or database call.
2. Never trust `req.body`, `req.query`, or `req.params` without schema validation.
3. Use a schema library (Fastify's built-in AJV, Zod, Joi) — never hand-rolled regexes as the sole guard.
4. Reject early and return a 400 with a generic message; do not echo back user input in error messages (information leakage).

**Security headers — always use Helmet:**
```js
import helmet from 'helmet';
app.use(helmet()); // sets CSP, X-Frame-Options, HSTS, X-Content-Type-Options, etc.
```
Helmet sets 14+ security headers with safe defaults. Customize CSP per route if needed; do not disable HSTS on production. Configure CORS at the route level for APIs, never globally for admin routes.

**Injection prevention decision table:**

| Attack vector | Prevention |
|---|---|
| SQL injection | Parameterized queries / prepared statements — never string concatenation |
| NoSQL injection | Validate that input is a string/number before passing to a query — `$where` / operator injection uses objects |
| Command injection | `child_process.spawn` with args array — never `exec` with user input |
| Path traversal | `path.resolve` + check that result starts with the allowed base directory |
| XSS | Escape output in templates; set CSP; never `res.send(userInput)` as HTML |
| SSRF | Allowlist outbound URLs; validate host before `fetch`/`http.request` |

**Auth patterns:**
- JWT: verify signature and `exp` claim on every request; never decode without verifying; prefer short-lived access tokens + refresh token rotation.
- API keys: constant-time comparison (`crypto.timingSafeEqual`) — never `===` (timing attack).
- Passwords: `bcrypt`/`argon2` only — never `SHA-256` or faster hashes which are trivially brute-forced.

**Rate limiting:** always apply at the service or API gateway level. `express-rate-limit` for Express; Fastify has `@fastify/rate-limit`. Use Redis-backed stores in multi-instance deployments — in-memory rate limiters don't share state across pods.

**Red flags:** user input concatenated into a query or shell command; Helmet not installed; CORS configured with `origin: '*'` on an authenticated endpoint; JWT decoded without signature verification; `===` used for secret or token comparison; `npm audit` critical vulnerabilities in production deps.

---

## 6. Unit Testing

Node.js has a built-in test runner (`node:test`, stable from Node 18; Assert module for assertions) — no test framework required for simple cases.

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

test('parses CSV row', () => {
  assert.deepEqual(parseRow('a,b,c'), ['a', 'b', 'c']);
});
```

For richer features (mocking, snapshot, coverage): Jest (most popular ecosystem), Vitest (faster, ESM-native, compatible API), Mocha + Chai (older projects). Match the project's existing choice before introducing a new runner.

**What to test (and not):** test behavior at module boundaries, not implementation details. Stub I/O (filesystem, network, DB) at the lowest practical layer. Prefer integration tests for stream pipelines — mock streams are error-prone. Mock `child_process.spawn` carefully; it's easier to extract the shell logic into a testable pure function and call the process-boundary once.

**Coverage:** 80% line/branch is a useful floor, not a ceiling. 100% coverage with bad assertions is worse than 70% with precise assertions.

---

## Operational Rules Quick Reference

- **DO** keep all sync `*Sync` calls out of request handlers and hot paths — they block the event loop for all concurrent clients.
- **DON'T** use `process.nextTick()` recursively — it starves I/O. Use `setImmediate()` to defer work past the current phase.
- **DO** use `stream.pipeline()` (or `stream/promises` variant) instead of `.pipe()` — `pipeline()` propagates errors and cleans up; `.pipe()` does not.
- **DON'T** ignore `writable.write()` returning `false` — respect backpressure or use `pipeline()` which handles it automatically.
- **DO** use `Buffer.alloc(n)` for safe zero-filled allocation; `Buffer.allocUnsafe(n)` only when immediately overwriting every byte.
- **DON'T** pass user-supplied sizes to `Buffer.allocUnsafe` without range-checking — a giant allocation is a DoS vector.
- **DO** use `child_process.spawn` with an argument array for external commands; never `exec` with user-controlled input.
- **DO** use `npm ci` in CI/CD and Docker — never `npm install` (non-deterministic).
- **DON'T** commit `node_modules/`; always derive the install from `package-lock.json`.
- **DO** ship `devDependencies` only in dev/test images — keep production images slim.
- **DO** use ESM (`"type":"module"`) for new projects and `exports` map for published packages.
- **DON'T** use `__dirname` or `__filename` in ESM — use `fileURLToPath(import.meta.url)` instead.
- **DO** attach an `error` listener to every EventEmitter before emitting — unhandled `error` events throw.
- **DON'T** use `process.on('uncaughtException')` as an error recovery mechanism — log and exit.
- **DO** install Helmet on every Express/Fastify service — it sets 14+ security headers in one call.
- **DON'T** use `===` for secret or token comparison — use `crypto.timingSafeEqual` to prevent timing attacks.
- **DO** validate and sanitize every input at the request boundary before any business logic or DB call.
- **DON'T** concatenate user input into SQL, shell commands, or file paths — use parameterized queries, `spawn` with args, and `path.resolve` + prefix check.
- **DO** use `bcrypt` or `argon2` for passwords — never SHA-256 or MD5.
- **DO** verify JWT signatures and `exp` on every request; never skip verification.
- **DON'T** log PII, tokens, or passwords — scrub at the log boundary.

---

_Independent educational content for upskilling AI agents. Node.js and the OpenJS marks are trademarks of the OpenJS Foundation, used here only to identify the subject matter. Not affiliated with, authorized by, or endorsed by the OpenJS Foundation or the Linux Foundation. Content is provided as guidance only — verify against official Node.js documentation and your runtime version._
