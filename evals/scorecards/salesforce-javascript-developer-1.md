# Scorecard — salesforce-javascript-developer-1

- **Skill:** `salesforce-javascript-developer-1`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (LWC, wire adapters, decorators, coercion bugs, this-binding, XSS), states explicit use-when/not, names sibling `salesforce-platform-developer-1`; fits ≤600 chars and matches a single skill. |
| D2 | Scope contract | 2 | Load-when/not-this-skill present in Overview box; tooling fallback stated; no explicit "assumed context" block naming what the project must provide. |
| D3 | Operational depth | 3 | Coercion table, `this`-binding table, event-loop microtask/macrotask order, `fetch` non-rejection on 4xx/5xx, JSON round-trip data-loss list, `toBe` vs `toEqual` distinction — non-obvious operational layer throughout. |
| D4 | Decision support | 3 | Decision tables for `this`-binding, Promise combinator choice (all/allSettled/race/any), sequential vs. parallel, module system (ESM vs CJS); every fork has named criteria. |
| D5 | Failure-mode coverage | 3 | Per-section Red flags with plausible-wrong reasoning: `@track` band-aid masking the immutable-reassign rule; anonymous-arrow wrapper fixing `this` but blocking `removeEventListener`; floating Promises; `try/catch` missing async escape. |
| D6 | Verification discipline | 3 | Every section ends with a "Verify against the live org" step; tool-agnostic order (MCP → `sf` CLI → Setup UI); steps are copy-runnable (SOQL describe, `npm run test`, DevTools Memory panel). |
| D7 | Uncertainty & escalation | 3 | Dedicated "Uncertainty & Escalation" section; four inline `[volatile — verify live]` tags (Node runtime, LWS vs Locker, `@track` deep-reactivity, LWC-Jest compat); Live wins rule; escalate-to-human list covers PII/XSS/prod deploys. |
| D8 | Executable workflows | 3 | Three numbered workflows with verify gates: (1) wire Apex `@wire` + Jest test, (2) debug reactivity/`this`-binding bug, (3) add a field end-to-end in LWC. Each gate catches the dominant failure at that step. |
| D9 | Teaching scenarios | 2 | Two scenarios in body (LWC reactive array mutation; `this` lost in callback); two additional scenarios deferred to `references/scenarios.md` — four total but only two in the main load. |
| D10 | Context economy | 2 | 4,792 words (snapshot); in the 4,300–5,000 band → score 2. Quick Reference repeats section imperatives (acceptable); blueprint coverage notes (iterators/WeakMap) add body tokens but are operationally relevant. No exam logistics in body. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog entry explains what changed and why; inline volatile tags present. |
| D12 | Measurability | 2 | `evals/salesforce-javascript-developer-1/` has 12 situations, answer-key, tasks, and triggers — full infra present; no model run recorded yet. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-javascript-developer-1/triggers.md`. Test against descriptions only.

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Review this LWC and flag any reactivity bugs where tracked property mutations won't re-render the template" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 (description: "wire adapters…component lifecycle and decorators (@api/@track/@wire)…auditing JavaScript for coercion bugs, this-binding errors") | ✓ |
| "My @wire adapter is firing once but not re-firing when a reactive property changes — what is wrong with my LWC?" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 (description explicitly calls out wire adapters and LDS) | ✓ |
| "Audit this Jest/LWC-Jest test: the test passes but the feature is broken because no flush-promises is awaited" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 (description: "Jest/LWC-Jest testing") | ✓ |
| "I passed a class method as a callback to an event handler and now `this` is undefined inside it — how do I fix it?" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 (description: "this-binding errors") | ✓ |
| "We have an XSS risk in our LWC because a developer used `innerHTML` to render user-supplied text — walk me through the remediation" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 (description: "XSS") | ✓ |
| "Write Apex trigger logic to bulkify a contact update on after-insert and avoid hitting the 100-SOQL limit" | salesforce-platform-developer-1 | salesforce-platform-developer-1 (description: "Apex, SOQL/SOSL, triggers…bulkification against governor limits") | ✓ |
| "Fix my React useEffect that is causing an infinite re-render loop in our customer portal" | react | react (description: "hooks…useEffect…debugging React UIs, re-renders/effects") | ✓ |
| "Build a Queueable Apex chain that fans out async callouts after a Platform Event fires" | salesforce-platform-developer-2 | salesforce-platform-developer-2 (description: "asynchronous patterns (Batch/Queueable/Future/Schedulable, chaining)…Platform Events") | ✓ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-javascript-developer-1/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

- **D9 (2):** Two scenarios deferred to `references/scenarios.md` rather than inline. Acceptable for body-size reasons, but a Lens 4 run will determine whether the deferred scenarios are accessible enough at inference time. Consider promoting one back to body if lift on async/fetch scenarios is weak.
- **D10 (2):** At 4,792 words the skill is in the 4,300–5,000 band. The blueprint coverage notes (Iterators/Generators, WeakMap) add ~250 words; if trimming is needed later these are the first candidates, as they are lower-frequency than the core sections.
- **D2 (2):** No explicit "assumed context" block (what the project must provide — org access, LWC repo, sfdx-lwc-jest). Minor gap; add one line to the Scope/Overview box on next content pass.
- Strong across operational depth (D3), decision tables (D4), failure modes (D5), and workflows (D8) — no urgent rework.
