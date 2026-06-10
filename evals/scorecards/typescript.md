# Scorecard — typescript

- **Skill:** `typescript`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (structural typing, generics, narrowing, tsconfig, declaration files); explicit use-when and "framework-specific concerns live in sibling skills" scope boundary; ≤600 chars. |
| D2 | Scope contract | 2 | "Scope of this skill" block in Overview with load-when, not-this-skill, and sibling pointers; solid but not a labeled "Scope" header — agent can route from it but it requires reading the intro. |
| D3 | Operational depth | 3 | TS 6.0 nine-defaults-at-once table with old/new values; `types:[]` stealth breaking change explained; `satisfies` vs `as` semantic difference; `as unknown as T` double-cast anti-pattern named. |
| D4 | Decision support | 3 | Narrowing technique preference table (7 tools in order), module resolution decision table (3 settings with correct pairings), utility types reference table — every choice comes with the constraint that drives it. |
| D5 | Failure-mode coverage | 3 | Red flags in code review section lists 9 named patterns; 5 POLICY scenarios each give the plausible-but-wrong reasoning (`any` propagation, phantom declarations, `as` casts) and a verify step. |
| D6 | Verification discipline | 3 | Workflow gates are copy-runnable: `tsc --showConfig | grep strict`, `tsc --noEmit 2>&1 | wc -l`, `node -e "const lib = require('the-lib'); console.log(typeof lib.method)"`, `tsc --build`. |
| D7 | Uncertainty & escalation | 3 | Dedicated U&E section; `[volatile — verify live]` on TS 6.0 defaults, `--moduleResolution node` deprecation, TS 7.0 Go-native timeline, `--module node20`; escalate-to-human for major version upgrades; live-wins stated. |
| D8 | Executable workflows | 3 | Three numbered workflows (type external API with runtime validator, tighten strictness incrementally, model discriminated union with exhaustiveness) with gates between every step. |
| D9 | Teaching scenarios | 3 | Five POLICY scenarios covering .d.ts phantom declarations, branded nominal types, generic constraints, runtime boundary `as` cast, `unknown` vs `any` in error handlers — each probes a different section's hardest fork. |
| D10 | Context economy | 2 | 4,628 words — inside the 4,300–5,000 band; scores 2. Body clean; no exam logistics; `references/` deferred. Moderate trim opportunity in the utility types table and Quick Reference duplication. |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`; Changelog entry present; `[volatile]` marks on all TS 6.0/7.0 facts. No per-scar origin tracking beyond initial conformance; single changelog event. |
| D12 | Measurability | 2 | Eval infra complete (triggers, situations, tasks, answer-key); no model run recorded yet. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/typescript/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Our published npm package's `.d.ts` file declares a method that was removed in v2 but consumers' type-checks still pass — how do I fix the declaration file?" | typescript | typescript — "declaration files (.d.ts)… Use when adding or reviewing types in any TS codebase" | ✓ |
| "I have a generic function `function wrap<T>(val: T): Box<T>` and I can't constrain T to only object types — what's the correct constraint syntax?" | typescript | typescript — "generics… Use when adding or reviewing types in any TS codebase" | ✓ |
| "TypeScript is widening my string literal to `string` when I infer it through a generic — how do I preserve the literal type?" | typescript | typescript — "narrowing and inference… generics" | ✓ |
| "We cast the result of `JSON.parse()` to our `ApiResponse` type with `as` and now we're getting runtime crashes — what's the type-safe pattern?" | typescript | typescript — "conditional/mapped/utility types… Use when adding or reviewing types in any TS codebase" | ✓ |
| "I'm getting a TS error: 'Type string is not assignable to type never' inside my exhaustive switch — what does that mean and how do I add a proper exhaustiveness check?" | typescript | typescript — "narrowing and inference… Use when adding or reviewing types" | ✓ |
| NM: "React component props have a TS error: 'Property children does not exist on type IntrinsicElements'" | react | react — "components and JSX… Use when writing, reviewing, or debugging React UIs" — JSX model is react's scope; typescript description explicitly defers framework concerns to sibling skills | ✓ |
| NM: "Next.js `generateStaticParams` returning the wrong type and the build fails" | nextjs | nextjs — "App Router… data fetching… Use when building, reviewing, or debugging Next.js apps" | ✓ |
| NM: "Node.js service's `process.env.PORT` typed as `string | undefined` — narrow before parseInt" | nodejs | nodejs — "HTTP services… Use when writing, reviewing, or debugging Node.js code, CLIs, services" — phrasing is anchored to "my Node.js service" context (borderline; see note below) | ✓ |
| NM: "Expo's `useLocalSearchParams` is returning `string | string[]` — how do I handle this in my screen?" | react-native | react-native — "navigation (Expo Router, React Navigation)… Use when building, reviewing, or debugging RN/Expo apps" | ✓ |

**Trigger pass rate:** 5/5 (target phrasings). Near-misses all correctly deflected.

**Ambiguous near-miss note (NM3):** "Node.js service's `process.env.PORT`" routes nodejs by context framing. If the phrasing dropped "Node.js service" and said only "my TypeScript app's `process.env.PORT`", it would correctly route typescript (typescript description: "typing third-party/Node APIs… Use when adding or reviewing types in any TS codebase"). The trigger file correctly flags this as borderline and the context word "service" is the deciding factor.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/typescript/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Strong first-pass score. The TS 6.0 breaking-changes section is a genuine differentiator — it documents the nine-default-flip event precisely, which the base model does not have in training. D10 trim opportunity: the utility types reference table in Section 2 (12 rows) and the Quick Reference (~28 bullet points) have moderate overlap with section bodies; targeted pruning could reach sub-4,300 words. D11 and D12 will improve as field feedback and eval runs accumulate.
