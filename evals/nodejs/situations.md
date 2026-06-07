# Eval situations — nodejs

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
