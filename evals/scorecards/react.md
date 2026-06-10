# Scorecard — react

- **Skill:** `react`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (hooks, rules of hooks, re-renders, effects, RTL testing); explicit use-when and exclusion of Next.js / React Native; ≤600 chars. |
| D2 | Scope contract | 2 | "Scope of this skill" and "Framework scope boundary" blocks present; sibling pointers explicit; not a single labeled "Scope" header but agent can route from it. |
| D3 | Operational depth | 3 | Prop-mirroring trap with two correct fixes (key vs full controlled) and why the effect-sync is wrong; reconciliation three-phase model; concurrent features (`useTransition` vs `useDeferredValue`) with scheduler semantics. |
| D4 | Decision support | 3 | State architecture decision table (5 questions with guidance), data-fetching tool table, memoization trio table with correct-use criteria, RTL query priority table — all forks have named constraints. |
| D5 | Failure-mode coverage | 3 | Red flags at end of §1 and §2 (10+ named anti-patterns); Scenario 1 names the plausible-but-wrong `React.memo` fix and explains why context changes bypass it; Testing section has an inline scenario with wrong/correct move. |
| D6 | Verification discipline | 3 | Workflow gates are copy-runnable: React DevTools Profiler steps ("record a session, click the component"), `Object.is(prev, next)` ref-stability check, `screen.debug()`, `--verbose` test runner flag. |
| D7 | Uncertainty & escalation | 3 | Dedicated U&E section; `[volatile — verify live]` on React Compiler availability, `useActionState`/`useOptimistic` (React 19+), TanStack Query major-version surface; escalate for React 17→18/18→19 upgrades; live-wins stated. |
| D8 | Executable workflows | 3 | Three numbered workflows (state placement, re-render diagnosis, RTL test writing) with verify gates between every step. |
| D9 | Teaching scenarios | 3 | 4 scenarios now inline in body (POLICY-format): context provider value object, prop-mirroring vs controlled component, React.memo bypassed by context change, and useEffect dependency infinite loop. references/scenarios.md removed. |
| D10 | Context economy | 2 | 4,721 words — inside the 4,300–5,000 band; scores 2. Body clean; no exam logistics. D10 trim flag: pushing additional scenarios to `references/` reduces body word count but D9 suffers — these concerns are in tension. |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`; Changelog present (2026-06-09 conformance); volatile marks inline. No per-scar provenance yet. |
| D12 | Measurability | 2 | Eval infra complete (triggers, situations, tasks, answer-key); no model run recorded yet. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

---

## Lens 2 — Trigger testing

Source phrasings: `evals/react/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "My `useEffect` runs on every render even though I passed a dependency array — the linter says I'm missing a dependency but adding it causes an infinite loop" | react | react — "hooks… rules of hooks… Use when writing, reviewing, or debugging React UIs, re-renders/effects" | ✓ |
| "I defined a child component inside the render function of the parent and now inputs inside it lose focus on every keystroke — what's happening?" | react | react — "components and JSX… rendering and memoization" | ✓ |
| "I'm mapping over a list with `key={index}` and after reordering, checkboxes show the wrong checked state" | react | react — "state and data flow… rendering and memoization" | ✓ |
| "How do I debounce a search input in React without using a library, and why does putting the debounce inside the component cause bugs?" | react | react — "hooks… state and data flow" | ✓ |
| "My `React.memo` wrapped component still re-renders every time the parent renders — what should I check?" | react | react — "rendering and memoization… Use when writing, reviewing, or debugging React UIs, re-renders/effects" | ✓ |
| NM: "In our Next.js app a Server Component fetches data but it re-fetches on every request instead of caching" | nextjs | nextjs — "rendering and caching (use cache, PPR, streaming), data fetching… Use when building, reviewing, or debugging Next.js apps" | ✓ |
| NM: "Our React Native FlatList re-renders every item when any state changes — how do I optimize this?" | react-native | react-native — "FlatList… Use when building, reviewing, or debugging RN/Expo apps or the native/mobile layer" | ✓ |
| NM: "I want to add an `onClick` handler to a custom component but TypeScript says the prop doesn't exist" | typescript | typescript — "Use when adding or reviewing types in any TS codebase"; react description explicitly excludes Next.js and RN; this is a type-system question about prop signatures | ✓ |

**Trigger pass rate:** 5/5 (target phrasings). Near-misses all correctly deflected.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/react/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

The blocking issue is D9. The skill body contains one full POLICY scenario and one inline testing mini-scenario — two at most, against the ≥4 bar. The fix is to inline at least three additional scenarios from `references/scenarios.md` directly into the body. Since body word count (4,721) is already near the D10 ceiling, adding three 150–200 word scenarios will push the skill over 5,000 words, risking a D10 drop to 1. The recommended resolution: trim the Quick Reference section (currently ~28 bullet points, many redundant with section bodies) by approximately 350–400 words to create headroom before inlining the scenarios. Target: 4 in-body scenarios + body ≤4,800 words.

The rest of the skill is high quality. D11/D12 improvements follow the standard path: field feedback for provenance, eval runs for measurability.
Cycle-1 curation (2026-06-09): D9 1→3 (4 scenarios now inline; references/scenarios.md removed) → now publish-ready.
