# Application tasks — nodejs (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

## Task 1 — Redline this HTTP handler for security and reliability flaws

**Prompt to the agent:** Review the following Node.js/Express HTTP handler and produce a written redline identifying every security and reliability flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```js
const { exec } = require('child_process');
const fs = require('fs');

app.post('/reports/generate', async (req, res) => {
  const { filename, userId } = req.body;

  // Log the full request for debugging
  console.log('Report request:', JSON.stringify(req.body));

  const configData = fs.readFileSync('/etc/app/report.config', 'utf8');
  const config = JSON.parse(configData);

  exec(`pdfgen --input /data/${filename} --output /reports/${filename}.pdf`, (err, stdout) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    const report = fs.readFileSync(`/reports/${filename}.pdf`);
    res.set('Content-Type', 'application/pdf');
    res.send(report);
  });

  db.query(`SELECT * FROM audit_log WHERE user_id = '${userId}'`)
    .then(rows => res.json(rows));
});
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Shell injection via `filename` in `exec()`: unsanitized user input passed directly to a shell command enables arbitrary code execution; fix is `execFile` with an argument array or strict allowlist validation.
- [ ] Trap 2 — SQL injection via string interpolation of `userId`: should use parameterized queries (`db.query('... WHERE user_id = $1', [userId])`).
- [ ] Trap 3 — Synchronous `fs.readFileSync` in the hot path: blocks the event loop for every request; fix is `fs.promises.readFile` with `await`.
- [ ] Trap 4 — PII/sensitive data logged via `console.log(JSON.stringify(req.body))`: request body may contain passwords, tokens, or personal data; fix is structured logging that redacts sensitive fields.
- [ ] Trap 5 — Floating Promise / double-response race: the `exec` callback calls `res.json(rows)` from the outer `.then()` concurrently; if both complete, Express throws "Cannot set headers after they are sent"; the handler must use a single response path.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Names shell injection specifically (not just "sanitize input") and prescribes `execFile` or `spawnSync` with an arg array.
- Names SQL injection and shows the parameterized-query fix for the specific driver pattern.
- Flags `readFileSync` as event-loop blocking and replaces with `await fs.promises.readFile`.
- Flags `console.log(req.body)` as a PII logging risk; recommends field-level redaction.
- Identifies the double-response hazard (exec callback + Promise `.then()` both calling `res.*`) and explains the correct single-exit-path structure.
- Organizes findings by severity (security > reliability > style).

---

## Task 2 — Redline this streaming pipeline for backpressure and error-handling flaws

**Prompt to the agent:** Review the following Node.js stream pipeline used in a file-download service and produce a written redline identifying every backpressure, error-handling, and reliability flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```js
const http = require('http');
const fs = require('fs');
const zlib = require('zlib');

http.createServer((req, res) => {
  const filePath = req.url.slice(1);          // e.g. /data/report.csv -> data/report.csv

  const readStream = fs.createReadStream(filePath);
  const gzip = zlib.createGzip();

  readStream.pipe(gzip).pipe(res);

  readStream.on('error', (err) => {
    res.writeHead(500);
    res.end('Read error');
  });

  new Promise(async (resolve, reject) => {
    const chunks = [];
    for await (const chunk of readStream) {
      chunks.push(chunk);
    }
    resolve(Buffer.concat(chunks));
  }).then(buf => {
    console.log(`Served ${buf.length} bytes for ${req.url}`);
  });

}).listen(3000);
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `.pipe()` without error forwarding on intermediate streams: if `gzip` emits an error, the pipeline hangs and the response is never ended; fix is `stream.pipeline()` (or `pipeline` from `node:stream/promises`) which propagates errors and destroys all streams.
- [ ] Trap 2 — Path traversal via `req.url`: `filePath` is derived directly from the URL with no sanitization; a request to `/../etc/passwd` escapes the intended directory; fix is `path.resolve` + prefix check, or an allowlist.
- [ ] Trap 3 — `new Promise(async (resolve, reject) => {...})` anti-pattern: the async executor swallows rejections that `reject` never sees; the iterator also reads the stream a second time after it has already been `.pipe()`d, so the second read gets no data (stream already consumed); fix is to eliminate this double-consumption entirely and log bytes via a `Transform` or `pipeline` callback.
- [ ] Trap 4 — `res` error not handled: if the client disconnects, `res` emits an error that is unhandled and crashes the process; the `pipeline` fix addresses this, but if `.pipe()` is kept, `res.on('error', ...)` must be added.
- [ ] Trap 5 — Double stream consumption: the `for await` loop attempts to iterate `readStream` after `.pipe()` has already started draining it, producing silent empty reads or errors; the logging intent must be achieved without re-consuming the stream.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Recommends replacing the three-stage `.pipe()` chain with `stream.pipeline(readStream, gzip, res, callback)` or the promise version, explaining error propagation and automatic cleanup.
- Identifies path-traversal risk and prescribes `path.resolve` + directory prefix validation.
- Calls out the `new Promise(async ...)` anti-pattern by name and explains the swallowed-rejection and double-consumption failure modes specifically.
- Notes that `res` errors must also be handled whether using `pipeline` or manual `.pipe()`.
- Suggests a `Transform` stream or the `pipeline` finish callback for byte-count logging instead of double-consuming the source stream.
- Does not introduce any new pattern errors (e.g., does not suggest `util.promisify(stream.pipeline)` when `stream/promises` is available in Node 15+).
