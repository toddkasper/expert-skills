# Scorecard — nodejs

- **Skill:** `nodejs`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with runtime task vocab (event loop, streams, ESM/CJS, HTTP services, Lambda); ends with explicit sibling scope boundaries; ≤600 chars. |
| D2 | Scope contract | 2 | Load-when / not-this-skill block in Overview; sibling pointers present; not labeled a formal "Scope" header — readable but slightly informal structure. |
| D3 | Operational depth | 3 | Microtask queue phase order named precisely; `pipeline()` vs `.pipe()` error-propagation gap explained with mechanism; `exec` vs `spawn` shell interpolation detailed; timing-attack `===` noted. |
| D4 | Decision support | 3 | async/await pitfall table, filesystem operation table, injection prevention table, framework choice criteria — every fork has the constraint driving the choice. |
| D5 | Failure-mode coverage | 3 | Red flags at end of every section; 6 POLICY scenarios each name the plausible-but-wrong reasoning and explain why it fails; detection steps in Verify. |
| D6 | Verification discipline | 3 | Workflow gates are copy-runnable: `lsof | grep <pid>`, `curl -I <endpoint>`, `npm ci` divergence test, `node -e "require('node:stream/promises').pipeline"`. |
| D7 | Uncertainty & escalation | 3 | Dedicated U&E section; `[volatile — verify live]` inline on `require(esm)`, `node:test` API, `stream/promises`, Fastify defaults; escalate-to-human list; live-wins stated. |
| D8 | Executable workflows | 3 | Three numbered workflows (streaming pipeline, safe HTTP handler, CLI packaging) each with verify gates between steps that catch the named failure at that step. |
| D9 | Teaching scenarios | 3 | Six POLICY scenarios (`.pipe()` leak, `setImmediate` CPU block, in-memory rate limiter, JWT log leak, `util.promisify` `this` trap, `exec` injection); each targets a different section's hardest judgment call. |
| D10 | Context economy | 2 | 4,833 words — inside the 4,300–5,000 band; scores 2. Quick Reference is one-liners only; no exam logistics; deep context deferred to `references/`. Trim flag: ~300 words recoverable from Quick Reference duplication. |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`; Changelog entry present (2026-06-09 conformance); volatile facts marked inline. No per-scar origin tracking yet; changelog note is single conformance event only. |
| D12 | Measurability | 2 | Eval infra complete (triggers, situations, tasks, answer-key); no model run recorded yet — standard result for a newly conformant skill. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/nodejs/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Our Node.js service is OOMing under load — we're piping a large file to the HTTP response, help me find the backpressure problem" | nodejs | nodejs — "streams and buffers… Use when writing, reviewing, or debugging Node.js code" | ✓ |
| "Review this Express middleware: it calls `exec(userInput)` to run a shell command and logs the full request body to stdout" | nodejs | nodejs — "HTTP services with security… Use when writing, reviewing, or debugging Node.js code, CLIs, services" | ✓ |
| "My npm package has both a `main` and an `exports` field but ESM consumers get 'not a module' errors — what's the correct exports map?" | nodejs | nodejs — "the module system (ESM/CJS), packaging and the toolchain" | ✓ |
| "We have a floating Promise inside a forEach loop that calls our database; the function returns before the writes finish" | nodejs | nodejs — "async patterns… Use when writing, reviewing, or debugging Node.js code" | ✓ |
| "A Lambda handler uses `fs.readFileSync` in the hot path — is this a problem and how do I fix it?" | nodejs | nodejs — "AWS Lambda handlers… event loop and async patterns" | ✓ |
| NM: "Our Next.js API route streams a large file to the browser and memory is growing" | nextjs | nextjs — "Route Handlers, Server Actions… Use when building, reviewing, or debugging Next.js apps" — nodejs explicitly excluded from Next.js streaming context | ✓ |
| NM: "Property does not exist after union type narrowing in TypeScript" | typescript | typescript — "narrowing and inference… Use when adding or reviewing types in any TS codebase" | ✓ |
| NM: "React app makes a fetch call inside useEffect on mount — is this right?" | react | react — "hooks… state and data flow… Use when writing, reviewing, or debugging React UIs" | ✓ |
| NM: "getServerSideProps calls db.query() synchronously — should it be async?" | nextjs | nextjs — "data fetching… Use when building, reviewing, or debugging Next.js apps" | ✓ |

**Trigger pass rate:** 5/5 (target phrasings). Near-misses all correctly deflected.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/nodejs/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Strong first-pass score. D10 is the primary trim target — the Quick Reference section (~20 bullet points) partially duplicates rules already in the section bodies; a selective prune of fully-redundant entries could bring word count under 4,300 and lift D10 to 3. D11 will improve naturally as field feedback accrues and per-scar provenance is added to the changelog. D12 unblocks once Lens 3/4 runs are recorded.
