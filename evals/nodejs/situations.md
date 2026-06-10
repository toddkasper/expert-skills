# Eval situations — nodejs

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A Fastify service receives a POST body where `req.body.userId` is used as the `$where` clause in a MongoDB query. Input validation confirms the field is present and non-empty. Yet security review flags the endpoint as still vulnerable. What's missing, and what's the fix?

2. A Node.js 20 service runs `fs.readFileSync('/etc/config', 'utf8')` inside the HTTP request handler. Load tests show the service handles 50 req/s fine. A tech lead still demands this be changed. Why — and to what?

3. You have an EventEmitter-based queue that can fire the `'data'` event thousands of times per second. After a week in production the service's RSS memory climbs steadily. Code review shows `.on('data', handler)` is called inside each request handler with `req.id` closed over. What's happening, and how do you fix it?

4. Your Express app compares an incoming API key with `if (req.headers['x-api-key'] === process.env.API_KEY)`. Security review flags this. What's the vulnerability, and what's the correct comparison?

5. A Lambda function written in Node.js uses `process.nextTick()` in a loop to break up a CPU-bound data transformation so it "doesn't block the event loop." In production, concurrent invocations see degraded I/O latency. Is this a correct use of `nextTick`? What should be done instead?

6. A library published to npm uses `"main": "./src/index.js"` in package.json and no `exports` field. A consumer with `"type":"module"` tries to `import` it and gets an error. What's the root cause, and what must the library author do to support both CJS and ESM consumers?

7. A Dockerfile for a Node.js service contains `RUN npm install` (not `npm ci`). The image builds fine in development. What's the operational risk in CI/CD, and what single change fixes it?

8. A developer wraps a legacy callback-based function in a `new Promise` constructor, placing an `async` arrow function inside it: `new Promise(async (resolve, reject) => { ... })`. A code reviewer calls this an anti-pattern. What specific failure mode does this create, and what's the correct approach?

9. You are streaming a 4 GB file from disk to an HTTP response using `.pipe()`. Under heavy load, the disk reads outpace the client download speed. Memory spikes and eventually the process OOMs. Explain the mechanism and the minimal fix.

10. A CLI tool allocates a Buffer with `Buffer.allocUnsafe(Number(req.query.size))` before filling it from a network response. A security reviewer raises two separate concerns about this single line. What are they?

11. An `async` function is called inside a `forEach` loop — `items.forEach(async (item) => { await db.save(item); })`. The surrounding code logs "all done" immediately after `forEach` returns and the tests pass. What's wrong, and what is the correct pattern for awaiting all saves?

12. A Node.js service's `process.on('uncaughtException', (err) => { logger.error(err); })` handler logs the error and then continues normally — no exit, no restart. A senior engineer says this is unsafe even though the app appears to keep running. What's the risk, and what should the handler do?

13. A CJS module on Node 20.15.0 attempts to load an ESM-only package with `const mod = require('esm-pkg')` and throws "ERR_REQUIRE_ESM". A developer on the same team running Node 22.12.0 reports the same call works without any flags. Explain the version-dependent behavior and what the Node 20 developer should do to fix this without upgrading Node.

14. A stream Transform is constructed with no options and processes binary data in chunks. Under load the pipeline stalls frequently — the downstream writable regularly returns `false` and the readable side keeps buffering. Profiling shows the internal buffer grows to 65 536 bytes before backpressure kicks in. A teammate suggests lowering `highWaterMark` to 16 384 on the Transform to reduce memory pressure. Is this a sound tuning decision? What is the actual default, and what trade-off does lowering it introduce?

15. A containerized Node.js service receives SIGTERM from Kubernetes when a rolling deploy drains a pod, but in-flight HTTP requests are regularly cut off mid-response and clients see connection resets. The SIGTERM handler does not exist — the process exits immediately. Write the minimal code change (using only Node.js built-ins) and explain why the container orchestrator needs the process to handle SIGTERM cooperatively.

16. A CLI tool reads `process.env.TIMEOUT` and passes it directly to `setTimeout(fn, process.env.TIMEOUT)`. In local testing it works fine. In CI the timer never fires, causing the test suite to hang. Identify two separate bugs on this single line and describe the correct fix for each.
