# Scorecard — nextjs

- **Skill:** `nextjs`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (App Router, Server/Client Components, `use cache`, PPR, streaming, Server Actions, Proxy/Middleware); explicit use-when and sibling exclusions; ≤600 chars. |
| D2 | Scope contract | 2 | Load-when / not-this-skill block in Overview with sibling pointers; version-sensitive warning prominent; solid routing signal but no single labeled "Scope" header. |
| D3 | Operational depth | 3 | CVE-2025-29927 named explicitly; `use cache` silently ignored in Route Handler body (not a build error — non-obvious); closure encryption round-trip explained with deployment key requirement; `updateTag` Server Actions-only restriction with `revalidateTag` as the alternative. |
| D4 | Decision support | 3 | Route Handlers vs Server Actions table (6 dimensions), revalidation decision table (4 scenarios with API + callable context), cacheLife profiles table, Server vs Client Component decision table — every fork has the determining constraint. |
| D5 | Failure-mode coverage | 3 | Red flags at end of all three major sections; 6 POLICY scenarios each give the plausible-but-wrong reasoning (silent cache miss, infrastructure debugging instead of Suspense placement, trusting proxy as auth gate) and a verify step. |
| D6 | Verification discipline | 3 | Workflow gates are copy-runnable: `NEXT_PRIVATE_DEBUG_CACHE=1 next dev` log inspection, `curl -X POST` without session cookie, `next build` for `server-only` violation, env var bundle inspection. |
| D7 | Uncertainty & escalation | 3 | Dedicated U&E section; `[volatile — verify live]` on cacheLife profiles, PPR default, proxy.ts rename, `updateTag` context restrictions, iOS SDK requirement; escalate for major version upgrades and encryption key rotation; live-wins stated. |
| D8 | Executable workflows | 3 | Three numbered workflows (cached data route, secure Server Action, server/client split) with gates between every step; gates catch the named common failure at each step. |
| D9 | Teaching scenarios | 3 | Six POLICY scenarios in Decision Scenarios section covering `use cache` in Route Handler, `cacheLife` outside scope, sequential await waterfall, root Suspense collapse, closure secret capture, missing `server-only` — each targets a different section's hardest judgment call. |
| D10 | Context economy | 2 | 4,900 words — inside the 4,300–5,000 band; scores 2. Body clean; no exam logistics; `references/` deferred. Near upper end of band — moderate trim opportunity in file-system conventions table. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`; explicit `docs-version: 16.2.7` and `docs-retrieved: 2026-06-07` in frontmatter; Changelog present; `[volatile]` marks throughout; version pin in the skill body opening paragraph. Exemplary provenance for a fast-moving framework. |
| D12 | Measurability | 2 | Eval infra complete (triggers, situations, tasks, answer-key); no model run recorded yet. |
| | **Total** | **33/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/nextjs/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Our Next.js Server Component calls `fetch` on every request even though the data doesn't change — how do I cache the response between requests?" | nextjs | nextjs — "rendering and caching (use cache, PPR, streaming), data fetching… Use when building, reviewing, or debugging Next.js apps, routing, caching" | ✓ |
| "I have a Server Action that mutates data but the page still shows the old values after it completes — I need to invalidate the cache" | nextjs | nextjs — "Server Actions and their security rules… Use when building, reviewing, or debugging Next.js apps, routing, caching" | ✓ |
| "We're getting a 'Server Component cannot be a child of a Client Component' error in our App Router layout — how do we structure this?" | nextjs | nextjs — "App Router, Server and Client Components… Use when building, reviewing, or debugging Next.js apps, routing" | ✓ |
| "Our Next.js middleware is reading an environment variable that starts with `NEXT_PUBLIC_` — a security reviewer flagged it. What's the issue?" | nextjs | nextjs — "the Proxy (formerly Middleware) layer… Use when building, reviewing, or debugging Next.js apps" | ✓ |
| "We added a `route.ts` file in the same `app/dashboard` directory as `page.tsx` and the build is failing" | nextjs | nextjs — "Route Handlers… App Router… Use when building, reviewing, or debugging Next.js apps, routing" | ✓ |
| NM: "React component fetches data in `useEffect` and we want to cache the result across multiple uses of the same hook" | react | react — "hooks… state and data flow… Use when writing, reviewing, or debugging React UIs" — this is a client-side custom hook concern, not a Next.js server caching concern | ✓ |
| NM: "Add rate limiting to Express API routes using a Redis store" | nodejs | nodejs — "HTTP services with security… Use when writing, reviewing, or debugging Node.js code, CLIs, services" | ✓ |
| NM: "TypeScript says `params` in my Next.js page is typed as `Promise<{ id: string }>` and I don't know how to unwrap it" | nextjs | nextjs — "App Router… data fetching… Use when building, reviewing, or debugging Next.js apps" — this is a Next.js v15+ async params API, not a generic TS generics question | ✓ |
| NM: "Building a React hook that subscribes to a WebSocket and want to make sure it cleans up correctly" | react | react — "hooks… Use when writing, reviewing, or debugging React UIs, re-renders/effects" | ✓ |

**Trigger pass rate:** 5/5 (target phrasings). Near-misses all correctly deflected.

**Note on NM3 (async params):** The trigger file correctly identifies this as a nextjs route, not typescript. The distinction is meaningful — an agent without this routing would load typescript and miss the Next.js v15+ async params context entirely. The nextjs description's "data fetching… App Router" covers it.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/nextjs/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Highest-scoring skill in this batch (33/36). The version provenance model (explicit `docs-version` + `docs-retrieved` in frontmatter, version-sensitive warning in the opening paragraph) is best-practice and should be replicated across the other fast-moving skills (react, react-native). The six in-body POLICY scenarios are well-distributed across all three major sections. D10 is the only meaningful trim candidate — the file-system conventions table (§1) accounts for ~200 words and could be pruned to the 5–6 most commonly confused entries. D12 unblocks on first Lens 3/4 run.
