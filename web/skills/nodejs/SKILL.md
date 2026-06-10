---
name: nodejs
description: Building and reviewing Node.js applications and services — the event loop and async patterns, streams and buffers, the module system (ESM/CJS), packaging and the toolchain, error handling and diagnostics, and HTTP services with security. Use when writing, reviewing, or debugging Node.js code, CLIs, services, or AWS Lambda handlers. Stays on the Node runtime; excludes React (see react), Next.js (see nextjs), and TypeScript typing (see typescript). Competence skill mapped to the retired OpenJS JSNAD/JSNSD curriculum.
metadata:
  credential: OpenJS Node.js Application Developer (JSNAD) / Services Developer (JSNSD) — both retired September 30, 2025
  domain: web
  type: certification-playbook
  status: operational
  last-reviewed: 2026-06-09
  blueprint: JSNAD / JSNSD curriculum (retired Sep 2025 — used as competence map only)
---

# Node.js — Skills Reference

## Overview

A strong Node.js engineer reasons about the runtime, not just the library. That means understanding how the event loop schedules work, how to move data through streams without blowing memory, how modules resolve at runtime vs at build time, and how to keep services secure against injection and header-based attacks. The retired OpenJS exams (JSNAD and JSNSD) are used here only as a public competence map — they defined what practitioners must know without being about the exam itself.

> **Load this skill when…** writing or reviewing Node.js services, CLIs, or Lambda handlers; debugging event-loop blocking or stream backpressure issues; auditing HTTP security (injection, Helmet, JWT); reviewing module/packaging configuration (ESM, exports map, npm ci).
> **Not this skill:** React UI concerns → see `react`; Next.js framework (App Router, Server Actions) → see `nextjs`; TypeScript type-system questions → see `typescript`; React Native/mobile runtime → see `react-native`.

> **Deeper context:** Study resources, certification history, and learning paths live in [references/study-resources.md](references/study-resources.md). Load that file when planning a study path. Sibling skills: `typescript`, `react`, `nextjs`, `react-native`.

> **Verify steps assume nothing about your tooling** — use your project's own scripts and the language toolchain (`tsc`, `node`, the test runner, the package manager), in that order of preference.

---

Credential context (retired JSNAD/JSNSD) and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** Node.js LTS release lines and their API stability tier change on a schedule — APIs stable in Node 18 may be deprecated or removed in Node 22/24. `[volatile — verify live]` marks apply to: the `node:test` runner API surface (added Node 18, still gaining features each release); `require(esm)` support for CJS-loading ESM (stable in Node 22 — behavior varies by version); `stream.pipeline()` Promise variant availability (`node:stream/promises` — verify against the project's Node version); `worker_threads` API surface (stable Node 12+, but options evolve). Check `engines` in `package.json` and the [Node.js release schedule](https://nodejs.org/en/about/releases/) before relying on a version-specific API.
- **Live wins:** the installed Node.js version's actual runtime behavior and the [official Node.js docs](https://nodejs.org/docs/latest/api/) are authoritative over this file → log discrepancies via Feedback protocol below.
- **Escalate to a human:** production deploys; dependency major-version bumps (especially `express`→`fastify` or Node LTS upgrades); data migrations; deleting or force-pushing git history; infrastructure changes (Redis, load balancer config, rate-limit store).
- **Confidence taxonomy:** facts in this file are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

Specific volatile facts in this skill:
- `require(esm)` in CJS files — `[volatile — verify live]` — stable Node 22+, not available in Node 18/20.
- `node:test` runner API (e.g., `--test`, `--test-reporter`) — `[volatile — verify live]` — features added each LTS cycle.
- `stream.pipeline()` from `node:stream/promises` — `[volatile — verify live]` — verify it exists in the project's Node version (Node 15+).
- Fastify vs Express security default behavior (Helmet bundled, AJV schema validation) — `[volatile — verify live]` — confirm against installed library version.

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
| Interop from CJS | `require('./foo.cjs')` works | `require('esm-only-pkg')` requires dynamic `import()` or Node ≥22 `require(esm)` (stable in Node 22) `[volatile — verify live]` |
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

Node.js has a built-in test runner (`node:test`, stable from Node 18; Assert module for assertions) `[volatile — verify live]` — no test framework required for simple cases.

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

## Executable Workflows

### Workflow 1 — Build a streaming file/transform pipeline with backpressure + error propagation

1. Import `pipeline` from `node:stream/promises` (not the callback form). → gate: `node -e "require('node:stream/promises').pipeline"` prints the function without error; if it fails, check your Node version.
2. Create the source with `fs.createReadStream(inputPath)` — no `highWaterMark` tuning until a benchmark says otherwise.
3. Create each transform with `new Transform({ transform(chunk, enc, cb) { … cb(null, processed); } })` or use a built-in like `zlib.createGzip()`.
4. Create the sink with `fs.createWriteStream(outputPath + '.tmp')`. → gate: confirm the `.tmp` file is created (no "ENOENT" on the directory).
5. `await pipeline(source, ...transforms, sink)`. The call handles backpressure and propagates errors end-to-end; no manual `.on('error')` wiring needed.
6. After `await pipeline(...)` resolves, `await fs.promises.rename(outputPath + '.tmp', outputPath)` — atomic move prevents partial reads. → gate: source and `.tmp` files closed (`lsof | grep <pid>` shows no dangling fds after rename).
7. Wrap the whole function in `try/catch`; on error, `await fs.promises.unlink(outputPath + '.tmp').catch(() => {})` for cleanup.

### Workflow 2 — Ship a safe HTTP handler (validate → map errors → never log PII)

1. Install a schema validator at the project boundary (Fastify uses AJV built-in; for Express add `zod` or `joi`). Define the expected shape of `req.body`, `req.params`, and `req.query`.
2. At the top of the handler, parse/validate the input. On failure, return `res.status(400).json({ error: 'Invalid input' })` — do not echo back user-supplied values in the message. → gate: send a malformed body; confirm 400 response and that the error message contains no user data.
3. Map domain/operational errors (DB not found, auth fail) to explicit HTTP status codes in a central error handler — never let a generic `500` reveal a stack trace to the client. → gate: trigger each error type in a test; assert the status code and that the response body contains no stack trace.
4. Strip sensitive fields before logging. Create a `sanitizeHeaders(headers)` helper that removes `authorization`, `cookie`, and `x-api-key`. Log the sanitized headers object, not `req.headers` directly. → gate: send a request with `Authorization: Bearer TOKEN`; grep structured log output for `Bearer` — it must not appear.
5. Set `Helmet` on the app once at startup: `app.use(helmet())`. → gate: `curl -I <endpoint>` — response must include `X-Content-Type-Options` and `Strict-Transport-Security` headers.

### Workflow 3 — Package a CLI/lib (deps vs devDeps → lockfile → npm ci in CI)

1. Audit `package.json`: every package used only in tests, builds, or linting goes in `devDependencies`. Packages the consumer needs at runtime stay in `dependencies`. → gate: `npm install --omit=dev` in a clean directory; the app starts without "Cannot find module" errors.
2. Add an `engines` field: `{ "engines": { "node": ">=20.0.0" } }`. → gate: `node --version` in CI matches the range.
3. Add a `files` array allowlisting `dist/` (or `lib/`), `README`, and `LICENSE`. Run `npm pack --dry-run` and confirm `src/`, `test/`, and `.env*` are absent from the tarball. → gate: tarball size is reasonable; no source maps or test fixtures included.
4. Commit `package-lock.json`. In CI, replace `npm install` with `npm ci` — it errors if the lockfile is missing or out of sync, guaranteeing reproducible installs. → gate: CI run uses `npm ci`; deliberately introduce a version mismatch in `package.json` and confirm `npm ci` fails with "npm ci can only install packages when your package.json and package-lock.json are in sync."
5. Run `npm audit --omit=dev` in the CI pipeline after install; fail the build on critical vulnerabilities. → gate: audit output exits 0 (or a known-OK non-zero when no criticals exist).

---

## Decision Scenarios

**Scenario 1 — `.pipe()` leaves a writable stream open after a readable error**

> **Situation:** A service pipes a `ReadStream` to a `WriteStream` to copy uploaded files to disk: `readStream.pipe(writeStream)`. In production, network disruptions occasionally cause the read stream to error mid-transfer. Monitoring shows orphaned file handles accumulating on the server.

> **Competent move:** Replace `.pipe()` with `stream.pipeline()` from `node:stream/promises`. `pipeline()` automatically destroys all streams in the chain and propagates errors end-to-end when any one stream errors. `.pipe()` forwards data but does not propagate errors — the destination stream stays open and the file handle leaks.

> **Tempting-but-wrong:** Adding an `error` listener to the readable and manually calling `writeStream.destroy()` inside it. This closes the gap but is fragile (must be repeated on every new pipeline) and easy to forget. `pipeline()` is the single-call fix that handles it for every stream in the chain.

> **Verify:** Simulate a read error by destroying the readable mid-transfer. With `.pipe()`, confirm the write stream fd remains open (`lsof | grep <pid>`). After switching to `pipeline()`, confirm the fd is closed immediately on error.

---

**Scenario 2 — CPU-bound work deferred with `setImmediate` blocks concurrent requests**

> **Situation:** A developer breaks up a 500ms JSON-transformation loop by inserting `await new Promise(r => setImmediate(r))` every 10,000 iterations so the event loop "can breathe." Under load tests with 20 concurrent requests, response times for all other endpoints still spike dramatically during the transformation.

> **Competent move:** Move the CPU-bound transformation into a `worker_threads` Worker. `setImmediate` defers work to the next event-loop iteration on the **same thread** — it yields briefly but the heavy computation still runs on the main thread and blocks all other I/O while it executes each chunk. Worker threads run on a separate OS thread and never block the event loop.

> **Tempting-but-wrong:** Increasing the chunk size so `setImmediate` is called fewer times, believing this reduces the blocking overhead. Fewer interruptions actually mean longer blocking windows per chunk — the total time spent blocking the main thread is essentially unchanged.

> **Verify:** Benchmark concurrent request latency with `autocannon` while a transformation is running. Compare main-thread deferral vs `worker_threads` — the worker approach should show near-zero latency impact on concurrent requests.

---

**Scenario 3 — In-memory rate limiter does not share state across pods**

> **Situation:** A three-instance Node.js API uses `express-rate-limit` with the default in-memory store. Security testing reveals that an attacker can bypass the 100 req/min limit by distributing requests across the three instances (34 requests per pod per minute — under the per-pod limit).

> **Competent move:** Configure `express-rate-limit` with a Redis-backed store (e.g. `rate-limit-redis`). In-memory stores track counts per process — each pod has its own counter, so the effective limit is `n × per-pod-limit` across a cluster. A shared Redis store means all instances share one counter and the limit is enforced globally.

> **Tempting-but-wrong:** Increasing the per-pod limit to compensate, reasoning that the average distribution will stay under the intended total. This does not enforce the limit reliably — a single attacker who knows the instance count can saturate the service with targeted requests.

> **Verify:** Use a Redis `MONITOR` command during the load test to confirm all instances are incrementing the same key, and verify that a burst from a single client across all pods triggers the limit correctly.

---

**Scenario 4 — Structured log accidentally includes a JWT in the request log**

> **Situation:** A Node.js service logs the full `req.headers` object on every request for debugging: `logger.info({ headers: req.headers }, 'incoming request')`. A security audit finds that `Authorization: Bearer <jwt>` tokens are persisted in the log store.

> **Competent move:** Scrub sensitive headers at the log boundary before calling the logger. Create a helper that strips `authorization`, `cookie`, and `x-api-key` from the headers object (or logs only an allowlist of safe headers). Log the scrubbed object, never the raw `req.headers`.

> **Tempting-but-wrong:** Removing the header-logging line entirely. That's overcorrection — headers like `content-type`, `user-agent`, and `x-request-id` are useful diagnostics. The correct fix is selective scrubbing, not wholesale deletion.

> **Verify:** Send a request with an `Authorization` header and grep the log output for `Bearer`. After scrubbing, the JWT must not appear. Also check `cookie` and `x-api-key` headers as a regression guard.

---

**Scenario 5 — `util.promisify` vs manually wrapping a callback — the `this` binding trap**

> **Situation:** A developer wraps a legacy database client method with `new Promise((resolve, reject) => client.query(sql, (err, rows) => err ? reject(err) : resolve(rows)))`. Code review flags this as a footgun. A teammate instead uses `const query = util.promisify(client.query)` and calls `query(sql)` — it throws "cannot read property 'pool' of undefined."

> **Competent move:** Bind the method when promisifying: `const query = util.promisify(client.query).bind(client)`. `util.promisify` strips the `this` context — calling the promisified function as a plain function loses the object reference the method needs internally. Binding restores the correct receiver.

> **Tempting-but-wrong:** Falling back to the `new Promise` constructor wrapper because "at least it works." The wrapper works, but it's verbose and must be repeated for every method. Binding once on `util.promisify` is the canonical, concise fix.

> **Verify:** Run the promisified query against a live test DB connection. With `.bind(client)`, the call succeeds. Without it, the error references an internal property of the client object — confirming the `this` loss.

---

**Scenario 6 — `exec` with a user-controlled filename enables command injection**

> **Situation:** A file-conversion service accepts a filename from the user and runs: `exec(`convert ${req.body.filename} output.pdf`)`. A penetration tester submits `filename = "input.jpg; rm -rf /tmp/uploads"` and the command executes both parts.

> **Competent move:** Switch to `spawn('convert', [req.body.filename, 'output.pdf'])`. `exec` passes the full string to the shell — shell metacharacters (`; | && $()`) are interpreted. `spawn` with an explicit argument array bypasses the shell entirely; each element is passed as a literal argument to the process and no shell expansion occurs.

> **Tempting-but-wrong:** Sanitizing `req.body.filename` with a regex that strips semicolons and pipes. Regex sanitization is incomplete — there are many shell metacharacter forms (`$()`, `` ` `` , newlines, null bytes, environment variable expansion) and any missed character is a vulnerability. Structural avoidance (no shell) is always safer than filtering.

> **Verify:** Pass `"input.jpg; echo INJECTED > /tmp/proof"` to both the `exec` and `spawn` implementations. The `exec` version creates the file; the `spawn` version passes the entire string as a literal filename argument and the injection fails.

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

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/nodejs.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. `last-reviewed` set to 2026-06-09.

---

_Independent educational content for upskilling AI agents. Node.js and the OpenJS marks are trademarks of the OpenJS Foundation, used here only to identify the subject matter. Not affiliated with, authorized by, or endorsed by the OpenJS Foundation or the Linux Foundation. Content is provided as guidance only — verify against official Node.js documentation and your runtime version._
