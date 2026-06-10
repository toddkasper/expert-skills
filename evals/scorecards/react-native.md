# Scorecard — react-native

- **Skill:** `react-native`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (Flexbox/FlatList, Expo Router, JSI/Fabric/TurboModules, EAS Build/Submit/Update, iOS/Android differences); explicit use-when and "assumes core React — covers mobile deltas only" scope boundary; ≤600 chars. |
| D2 | Scope contract | 2 | Load-when / not-this-skill block in Overview; "mobile deltas only" framing is clear; sibling pointer to `react` explicit; not a labeled "Scope" header but agent can route from it. |
| D3 | Operational depth | 3 | New Architecture mandatory from SDK 55+ (not just a best-practice — a hard cutover); iOS permission messages OTA-restriction named with consequence (new binary required); Android keystore unrecoverable explained; `createNativeStackNavigator` vs JS stack runs-on-UI-thread distinction. |
| D4 | Decision support | 3 | FlatList key props table with "why it matters" rationale; managed vs bare workflow decision table (4 dimensions + decision rule); EAS Submit prerequisites by platform; `platform.OS` vs platform-specific file decision implicit in §1. |
| D5 | Failure-mode coverage | 3 | Red flags at end of every section (§1 ScrollView, §2 JS stack navigator, §3 per-frame JSI calls, §5 New Arch incompatible library, §6 performance anti-patterns); Scenario 1 explains why `React.memo` fails with an unstable `renderItem` and names the wrong fix. |
| D6 | Verification discipline | 3 | Workflow gates are copy-runnable: `git diff --name-only HEAD~1` for OTA-safety check, `eas build:list` for runtime version confirmation, `flatListRef.current.scrollToIndex` for getItemLayout validation, `npx expo-doctor@latest`. |
| D7 | Uncertainty & escalation | 3 | Dedicated U&E section; `[volatile — verify live]` on New Arch mandatory date (SDK 55+), React Navigation/Reanimated/Gesture Handler version gates, `runtimeVersion` match semantics, iOS SDK requirement (currently iOS 26), Android target API floor; escalate for store submissions, OTA to production, keystore rotation; live-wins stated. |
| D8 | Executable workflows | 3 | Three numbered workflows (OTA update, add native permission, optimize long list) with gates between every step; each gate catches the named failure at that step. |
| D9 | Teaching scenarios | 1 | Decision Scenarios body contains **one** full POLICY scenario (inline arrow defeats `React.memo` on FlatList items), then "Further scenarios: references/scenarios.md". D9 requires ≥4 original scenarios in the skill body — body delivers only 1. |
| D10 | Context economy | 2 | 4,713 words — inside the 4,300–5,000 band; scores 2. Body clean; no exam logistics. Same D9/D10 tension as `react`: adding scenarios inflates the body, but the current headroom (~200 words below the 4,900 upper-band mark) is too tight without first trimming. |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`; Changelog present (2026-06-09 conformance); `[volatile]` marks on SDK/RN version gates and iOS/Android policy floors. No per-scar provenance; single changelog event. |
| D12 | Measurability | 2 | Eval infra complete (triggers, situations, tasks, answer-key); no model run recorded yet. |
| | **Total** | **30/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: needs content pass**

Sub-2 dimensions filed as inbox items: **D9** (scenario count in body = 1; need ≥4 in-body POLICY scenarios).

---

## Lens 2 — Trigger testing

Source phrasings: `evals/react-native/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Our Expo app's FlatList is janky when scrolling 500 items — we're using a ScrollView with a map and React.memo didn't help" | react-native | react-native — "core components and styling (Flexbox, FlatList)… Use when building, reviewing, or debugging RN/Expo apps or the native/mobile layer" | ✓ |
| "We shipped an OTA update via EAS Update to fix a bug but it added a new runtime permission — users are getting permission crashes" | react-native | react-native — "EAS Build/Submit/Update… Expo SDK and permissions… Use when building, reviewing, or debugging RN/Expo apps" | ✓ |
| "The iOS build works but Android crashes with 'Invariant Violation: Text strings must be rendered within a <Text> component'" | react-native | react-native — "core components… iOS/Android platform differences… Use when building, reviewing, or debugging RN/Expo apps" | ✓ |
| "We can't find the Android keystore that signed our production app — how do we push an urgent update?" | react-native | react-native — "EAS Build/Submit/Update… Use when building, reviewing, or debugging RN/Expo apps or the native/mobile layer" | ✓ |
| "Our Animated API animation is smooth in dev but drops frames in the production release build even though `useNativeDriver: true` is set" | react-native | react-native — "mobile performance… Use when building, reviewing, or debugging RN/Expo apps or the native/mobile layer" | ✓ |
| NM: "My React component list re-renders too often — I want to memoize the items" | react | react — "rendering and memoization… Use when writing, reviewing, or debugging React UIs" — no mobile/Expo/FlatList context | ✓ |
| NM: "We're building a Next.js app and want to cache the product list between navigations without re-fetching" | nextjs | nextjs — "rendering and caching… Use when building, reviewing, or debugging Next.js apps, routing, caching" | ✓ |
| NM: "Our TypeScript types for our navigation stack are getting complex — how do I type the params correctly with React Navigation?" | react-native | react-native — "navigation (Expo Router, React Navigation)… Use when building, reviewing, or debugging RN/Expo apps" — React Navigation typing IS a RN framework concern, not a generic TS generics question | ✓ |
| NM: "I have a React `useEffect` that sets up an interval and I need to clean it up when the component unmounts" | react | react — "hooks… Use when writing, reviewing, or debugging React UIs, re-renders/effects" | ✓ |

**Trigger pass rate:** 5/5 (target phrasings). Near-misses all correctly deflected.

**Note on NM3 (React Navigation typing):** The trigger file correctly routes this to react-native. The typescript description's "framework-specific concerns live in react/nodejs/nextjs/react-native skills" explicitly hands this off. The react-native description's "navigation (Expo Router, React Navigation)" makes it unambiguous. An agent using descriptions-only correctly loads react-native.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/react-native/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

The blocking issue is identical to `react`: D9 requires ≥4 POLICY scenarios in the skill body; only 1 is present. The same trim-then-expand resolution applies: reduce the Quick Reference (currently ~18 bullet points with moderate section-body duplication) by ~300 words, then inline three scenarios from `references/scenarios.md` — targeting the EAS Update OTA boundary, the Android `BackHandler` oversight, and the Reanimated worklet vs Animated API choice as the highest-value judgment calls not covered by Scenario 1.

The nextjs skill's `docs-version` provenance model is a pattern worth adopting here — given that Expo SDK and RN version gates are the most volatile facts in this skill, adding `sdk-version` and `rn-version` frontmatter fields analogous to nextjs's `docs-version` would improve D11 to 3.
