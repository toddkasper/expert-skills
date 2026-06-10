---
name: react
description: Building and reviewing React applications — components and JSX, hooks (useState/useReducer/useEffect/useRef/useContext, custom hooks), the rules of hooks, state and data flow, rendering and memoization, concurrent features, accessibility, and testing with React Testing Library. Use when writing, reviewing, or debugging React UIs, re-renders/effects, or state architecture. Excludes Next.js (see nextjs) and React Native/Expo (see react-native). Competence skill anchored on react.dev — no first-party certification.
metadata:
  credential: None — competence skill (no first-party React certification exists)
  domain: web
  type: competence-playbook
  status: operational
  last-reviewed: 2026-06-09
---

# React — Skills Reference

## Overview

No vendor certification exists for React. This playbook encodes the working competence applied when building, reviewing, or debugging a React application — anchored entirely on official React documentation (react.dev) and broadly accepted community best practices. Anchor all claims to react.dev; verify against it before acting.

**Scope of this skill:** React itself — components, hooks, state, rendering, data-fetching patterns, accessibility, and testing. Framework concerns (Next.js App Router, Server Components, Expo) are deferred to the `nextjs` and `react-native` sibling skills.

> **Load this skill when…** writing or reviewing React components, hooks, or state architecture; debugging re-renders, stale closures, or effect dependencies; auditing accessibility (ARIA, focus management); writing or fixing React Testing Library tests.
> **Not this skill:** Next.js App Router, Server/Client Components, Server Actions → see `nextjs`; React Native / Expo mobile apps → see `react-native`.

> Study resources and data-fetching library links live in [references/study-resources.md](references/study-resources.md).

> **Verify steps assume nothing about your tooling** — use your project's own scripts and the language toolchain (`tsc`, `node`, the test runner, the package manager), in that order of preference.

---

## Uncertainty & Escalation

- **Always re-verify live:** React evolves rapidly — hooks, concurrent features, and the React Compiler change behavior across minor versions. `[volatile — verify live]` marks apply to: React Compiler availability and defaults (production-ready late 2025 — check the project's `babel-plugin-react-compiler` or `eslint-plugin-react-compiler` version before assuming it is active); `useActionState` and `useOptimistic` (React 19+ only — `[volatile — verify live]`); React 18 batching behavior in non-React-managed event handlers (verify with React 18+); TanStack Query and SWR API surface (major-version breaking changes — always check installed version). Check `react` in `package.json` — React 18 and 19 differ on form actions, optimistic updates, and compiler support.
- **Live wins:** the installed React version's actual behavior and [react.dev](https://react.dev) are authoritative over this file → log discrepancies via Feedback protocol below.
- **Escalate to a human:** upgrading from React 17→18 or 18→19 in a production app (concurrent mode and batching changes can surface latent bugs); removing `StrictMode` from a production app; major data-fetching library upgrades (TanStack Query v4→v5 API changes); production deploys.
- **Confidence taxonomy:** facts in this file are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

---

## 1. Components, Hooks & State

### Component fundamentals

- **Every component must be a pure function of its inputs (props + state).** Same inputs → same JSX output, every time. Side effects in the render body (mutations, subscriptions, timers) are bugs waiting to surface under Strict Mode's double-invoke or the React Compiler.
- **Never define a component inside another component.** Each render call creates a new function reference; React sees it as a different component type, unmounts the inner component, and resets its state. Define all components at module top level.
- **Key correctness.** Keys tell React which items in a list are the same across renders. Use stable IDs (database id, slug); never use array index as a key on a list that can be reordered, filtered, or have items inserted — React will misapply state and DOM attributes.

### Rules of hooks (non-negotiable)

1. Call hooks only at the top level of a React function — never inside loops, conditionals, or early returns.
2. Call hooks only from React function components or from other custom hooks, never from plain functions.

Violating either rule makes hook call order unstable across renders; React will corrupt state. ESLint's `eslint-plugin-react-hooks` enforces both rules automatically — enable and trust it.

### `useState` — right tool, right scope

- **Don't sync derived values into state with an effect.** If a value can be computed from existing state or props, compute it during render: `const fullName = firstName + ' ' + lastName`. Storing it in state and synchronizing it via `useEffect` creates a double-render and is a category of bug, not a pattern.
- **Lift state to the closest common ancestor** of all components that need it. Over-lifting (global state for local concerns) creates unnecessary coupling and re-renders.
- **Don't mirror props into state** at initialization unless you explicitly intend to decouple updates. If you do decouple, name the variable to signal it: `const [editedTitle, setEditedTitle] = useState(initialTitle)`.

**Prop-mirroring trap — and the two correct fixes:**

When a child holds internal state that should reset when a controlling prop changes (e.g. a `<TabContent>` that tracks its own selection, reset when the parent's `tab` prop changes), there are exactly two correct approaches:

| Situation | Correct fix |
|---|---|
| Child should reset all state when prop changes | Give the child a `key` equal to the controlling prop from the parent: `<TabContent key={tab} />`. React unmounts and remounts the child cleanly — no effect needed. |
| Child should be fully controlled (no local selection state) | Remove the local state entirely; accept the value as a prop. |

**Red flags — wrong approaches for this scenario:**
- `useEffect(() => { setState(prop); }, [prop])` — still fires a double render (the stale state renders first, then the effect corrects it) and produces a brief flash of the old value.
- Adding a guard (`if (localState !== prop) setLocalState(prop)`) inside the effect — same double-render problem; the component still renders once with stale state before the effect runs.
- Using `useEffect` to "sync" prop-derived state is almost always avoidable; the `key` prop or full controlled pattern removes the need entirely.

**`useReducer`** — prefer over `useState` when next state depends on previous in complex ways, multiple fields change together as a unit, or you want pure update logic outside the component for testability. Reducer functions are pure: state + action → next state, no side effects.

### `useEffect` — the discipline

`useEffect` synchronizes a component with an **external system** (DOM APIs, browser subscriptions, third-party libraries, network). If there is no external system, you don't need an effect.

**Dependency array rules:**
- Every reactive value read inside the effect (props, state, variables derived from them) must appear in the deps array. Omitting deps to "run less" is a stale-closure bug.
- Don't add deps to suppress the lint warning — instead, restructure the effect to need fewer reactive values (move objects/functions inside the effect, or use `useReducer` dispatch which is stable).
- An empty dep array `[]` means "run once after mount and clean up on unmount" — correct for subscriptions, wrong for effects that should react to prop/state changes.

**Always return a cleanup function** when the effect sets up a subscription, timer, or connection. Without cleanup, re-mounting, StrictMode double-invoke, or hot reload will leak.

**Common effect over-use patterns — and the fix:**

| Mistaken pattern | Fix |
|---|---|
| `useEffect` updates state from props | Compute derived value during render; or use `key` prop to reset the component |
| `useEffect` sends a POST after state flag | Call the API in the event handler directly |
| Chain of effects updating each other | Collect all state changes in the event handler; compute final state together |
| `useEffect` notifies parent via callback | Call the parent callback directly in the event handler |
| `useEffect` transforms data for render | Calculate during render (or `useMemo` if expensive) |

**`useRef`** — holds a mutable value that doesn't trigger re-renders. Use for: DOM node references, timer IDs, tracking mount state, previous prop values. Never read or write refs during rendering.

**`useContext`** — eliminates prop-drilling for cross-cutting values (theme, locale, current user). Not a replacement for server-state caching — use TanStack Query or Zustand for that. Every subscriber re-renders on context value changes: split contexts by change frequency and memoize the provider value object.

**Custom hooks:** a function whose name starts with `use` that calls other hooks. Extract shared stateful logic into custom hooks; each call gets its own independent state instance. Extended guidance: [references/advanced-patterns.md](references/advanced-patterns.md) → "Custom Hooks."

---

## 2. Rendering & Performance

### How React renders

Rendering = calling your component function to produce a new JSX tree. React compares the new tree to the previous one (reconciliation) and commits only the changed DOM nodes. The DOM is NOT touched unless something changed. Three phases: **Trigger** (state update or initial mount) → **Render** (pure function call) → **Commit** (DOM update).

**State updates are batched** in React 18+. Multiple `setState` calls in a single event handler are batched into a single re-render.

**Memoization:** don't memoize without measuring. In React Compiler projects `[volatile — verify live]`, the compiler inserts `React.memo`/`useMemo`/`useCallback` automatically — manual memoization is usually redundant. Without the compiler, apply after profiling: `React.memo` memoizes render output, `useMemo` memoizes a computed value, `useCallback` memoizes a function reference (only useful when passed to a `memo`-wrapped child). Prefer structural patterns first: accept `children` as a prop, keep state local, split contexts by change frequency. Full comparison table and when-to-apply criteria: [references/advanced-patterns.md](references/advanced-patterns.md) → "Memoization."

### Key prop — the reset lever

Giving a component a different `key` tells React to unmount the old instance and mount a new one, resetting all its state. This is the correct fix for "reset form when user changes" — `<Form key={userId} />` — not an effect that clears state fields.

**Concurrent features (React 18+) — load [references/advanced-patterns.md](references/advanced-patterns.md) → "Concurrent Features" for `useTransition`, `useDeferredValue`, and `Suspense` usage patterns.**

### Profiling

Use React DevTools Profiler before optimizing. It shows which components rendered, why, and how long. Optimize the actual bottleneck, not the assumed one.

**Red flags in review:**
- `useMemo` / `useCallback` applied everywhere without measurement
- Component definitions nested inside other component render bodies
- Array index used as `key` on a sortable/filterable list
- `useEffect` reading a value not in the dep array (stale closure)
- `useState` holding a value that's derivable from other state
- Multiple sequential `setState` calls that each force a re-render (batch or use `useReducer`)

---

## 3. Data & Architecture

### Data fetching

React itself has no built-in data-fetching — use a library that handles caching, background refresh, loading/error states, and deduplication.

| Need | Tool |
|---|---|
| Server state (remote data, REST/GraphQL) | TanStack Query (React Query) or SWR |
| Optimistic updates before server confirmation | `useOptimistic` (React 19) `[volatile — verify live]` or TanStack Query's `optimisticUpdate` |
| Form submission with loading/error state | `useActionState` (React 19) `[volatile — verify live]` replaces the `useState` + `onSubmit` + loading flag pattern |
| Client/global UI state | `useState` / `useReducer` + context, or Zustand |
| Complex cross-component state | Redux Toolkit or Zustand |

Avoid writing `useEffect` + `fetch` + `useState` for server data — you get no caching, no deduplication, and race conditions. Use TanStack Query or SWR instead.

**Race condition:** when a component fetches data on a changing prop, a slow response from an old request can overwrite the new response. Fix: use the effect cleanup to set an `ignore` flag, or use a library that handles this automatically. Example pattern: [references/advanced-patterns.md](references/advanced-patterns.md) → "Race Condition."

### State architecture decisions

| Question | Guidance |
|---|---|
| Does only one component need this? | Keep it local with `useState` |
| Do sibling components need the same data? | Lift to closest common ancestor |
| Is it remote/server data that must be cached? | TanStack Query / SWR, not context |
| Is it shared UI state across many unrelated components? | Context (if low-frequency updates) or Zustand |
| Is the update logic complex or shared? | `useReducer` with context, or Redux Toolkit |

**Folder / feature structure and framework scope boundary** (Next.js/RN handoff rules, feature-based co-location guidance): [references/advanced-patterns.md](references/advanced-patterns.md) → "Folder Structure and Framework Scope."

---

## 4. Accessibility & Testing

### Accessibility

React renders to the DOM — all standard HTML accessibility rules apply. React-specific concerns:

- **Prefer semantic HTML.** A `<button>` is keyboard-focusable and announces its role to screen readers automatically. A `<div onClick>` is not. Use the correct element before reaching for ARIA.
- **Every interactive element needs an accessible name.** Buttons and links must have visible text or `aria-label`/`aria-labelledby`. Icon-only buttons (no visible text by design) must have `aria-label` — that is the correct and complete fix for that case.
- **`aria-label` is not a substitute for a visible `<label>`.** For form inputs that sighted users will interact with, the correct fix is always a persistent visible label (`<label htmlFor="id">` or wrapping the input). Adding `aria-label` to an unlabeled input satisfies the programmatic-name requirement for screen readers but leaves sighted users — including cognitive accessibility users — without a persistent field name. The label disappears on focus; `aria-label` is invisible. Treat `aria-label` on a form field as a lower-quality fix; flag it in review and prefer the visible label.

  **Decision table — input accessible name:**

  | Scenario | Correct fix |
  |---|---|
  | Text input missing a label | `<label htmlFor="inputId">` + matching `id` on input (or wrap input inside label) |
  | Icon-only button (no visible text) | `aria-label="Descriptive action"` on the button — this is the right answer here |
  | Input with only placeholder text | Add a visible label; placeholder alone disappears on type and has poor contrast |
  | Input where space truly forbids a visible label | `aria-label` or `aria-labelledby` as last resort; document the trade-off |
- **Associate form inputs with labels.** Use `<label htmlFor="inputId">` (note: `htmlFor` not `for` in JSX) or wrap the input inside the label. Never rely on placeholder text alone — it disappears on input and has poor contrast.
- **Focus management on dynamic content.** When a modal opens, move focus inside it; trap Tab within the modal; when it closes, return focus to the trigger. Use `useRef` + `element.focus()`. For lists that update (e.g. after a filter), ensure the user's position is not lost.
- **ARIA roles supplement, not replace, semantics.** Add `role`, `aria-expanded`, `aria-controls`, `aria-live` when native HTML can't convey the interaction. An `aria-live="polite"` region announces dynamic updates (search results count, toast notifications) to screen readers without moving focus.
- **Keyboard navigation.** Every action available by mouse must be reachable by keyboard. Tab/Shift-Tab navigate focusable elements; Enter/Space activate buttons; Escape dismisses overlays. Custom widgets (combobox, date picker, slider) must implement the ARIA Authoring Practices patterns.

**Red flags in review:**
- `onClick` on a non-interactive element with no `role` or `tabIndex`
- `<img>` without `alt` (or `alt=""` for decorative images)
- `<input>` without associated `<label>`
- Focus not managed after modal open/close
- Color alone used to convey meaning

### Testing with React Testing Library

**Core principle:** test what the user sees and does, not what the component stores internally. Tests that assert on state variables or component internals break on refactor while behavior stays the same.

**Query priority (use the highest-confidence query first):**
1. `getByRole` — finds by ARIA role + accessible name. The most robust query; also validates accessibility.
2. `getByLabelText` — finds form inputs by their label.
3. `getByPlaceholderText` — acceptable fallback for inputs without labels (but fix the a11y issue too).
4. `getByText` — for non-interactive text.
5. `getByTestId` — last resort; use when nothing else is stable. Prefer a `data-testid` attribute over class names or DOM structure.

**Interaction:** use `@testing-library/user-event` (`userEvent.click`, `userEvent.type`) rather than `fireEvent`. `userEvent` simulates the full browser event sequence (pointerdown, mousedown, focus, click, etc.); `fireEvent` fires a single synthetic event and misses side effects.

**Async patterns:**
- `findBy*` queries return a Promise and retry until the element appears or times out — use for anything that renders after an async operation.
- `waitFor(() => expect(...))` retries the assertion — use when multiple things must be true after an async operation.
- Never use `act()` manually in tests that use `userEvent` v14+ — it wraps automatically.

**What not to test:**
- Internal state values (test what the UI shows instead)
- Exact CSS classes (test behavior, not styling implementation)
- That a mock was called with internal component details (test the resulting UI, not the wiring)

**Custom hooks:** test via `renderHook` from `@testing-library/react`. Invoke the hook, manipulate inputs via `act()`, assert on the returned values.

**Decision scenario:**

> **Situation:** A button triggers a network call, and after success a confirmation message appears. The test clicks the button and immediately asserts on the message — but the assertion fails.
> **Competent move:** Switch to `await screen.findByText('Confirmation')` or wrap the assertion in `await waitFor(() => expect(screen.getByText('Confirmation')).toBeInTheDocument())`. The message renders asynchronously; `getBy*` queries are synchronous and fail immediately.
> **Tempting-but-wrong:** Adding `await act(async () => userEvent.click(button))` and then a synchronous `getBy*`. This works in some cases but is fragile and masks the real intent.
> **Verify:** Run the test with `--verbose`; confirm the query waits and passes when the message appears.

---

## Executable Workflows

### Workflow 1 — Place state correctly (compute-during-render vs lift vs key-reset — avoid effect-sync)

1. Ask: "Can this value be derived from existing state or props?" If yes, compute it during render — no `useState`, no `useEffect`. → gate: removing the derived state and computing inline produces identical UI with no console warnings.
2. Ask: "Does only one component need this value?" If yes, keep it local with `useState` in that component. Move on.
3. Ask: "Do two sibling components need the same value?" Lift state to their closest common ancestor. Pass as props. → gate: both siblings render the same value; changing it in one sibling updates the other.
4. Ask: "Should a child reset all its state when a controlling prop changes?" Give the child a `key` equal to the controlling prop: `<Form key={userId} />`. Do not write `useEffect(() => { setState(prop) }, [prop])`. → gate: change the controlling prop; confirm the child's internal state resets cleanly (React DevTools Components tab shows the instance unmounted and remounted).
5. Ask: "Is this server/remote data?" Use TanStack Query or SWR — not `useEffect + fetch + useState`. → gate: remove the `useEffect` + `fetch`; queries deduplicate, cache, and handle loading/error states automatically.

### Workflow 2 — Diagnose an extra/infinite re-render (profiler → identity/deps → memo decision)

1. Open React DevTools Profiler. Record a session covering the unexpected re-render. Click the component that re-renders unexpectedly — the "Why did this render?" panel lists the prop or state that changed. → gate: you can name the specific prop/state/context value that triggered the render.
2. If the triggering value is an object or function, check whether its reference is stable. Inline `{}` and `() => {}` in render produce a new reference every render. → gate: `console.log(Object.is(prev, next))` (or React DevTools) confirms the reference is changing.
3. If the reference instability is in a context value, wrap with `useMemo(() => ({ … }), [deps])` at the provider. If it is a callback prop, wrap with `useCallback(fn, deps)` at the parent. → gate: re-record in Profiler; the component should no longer appear in the flame chart for unrelated parent renders.
4. For infinite render loops: check whether a `useEffect` sets state unconditionally (no condition before `setState`) or whether its deps array contains an unstable object that it also updates. → gate: enable `eslint-plugin-react-hooks` — `exhaustive-deps` warns on missing/extra deps; fix the root cause, not the warning.
5. Only add `React.memo` after confirming the re-render is measurably slow (Profiler "render duration" > 2ms under real load). In React Compiler projects, skip manual memo entirely. → gate: Profiler shows reduced render count without introducing stale prop bugs.

### Workflow 3 — Test a component's behavior with React Testing Library

1. Render the component with `render(<MyComponent …/>)`. Import from `@testing-library/react`.
2. Query for elements with the highest-confidence query first: `getByRole('button', { name: /submit/i })`, then `getByLabelText`, then `getByText`, never `getByClassName`. → gate: the query finds exactly one element; if it throws "Unable to find…", run `screen.debug()` to inspect the rendered tree.
3. Interact using `@testing-library/user-event`: `await userEvent.click(button)`, `await userEvent.type(input, 'hello')`. Do not use `fireEvent` unless you need low-level synthetic events. → gate: `userEvent.setup()` is called once per test (v14+ API); all interactions are awaited.
4. For async outcomes (data loaded, UI updated after an API call), use `await screen.findByText('Expected text')` or `await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument())`. Never query synchronously for async results. → gate: the test passes consistently without artificial `setTimeout` or `sleep` calls.
5. Assert on what the user sees, not on internal state. `expect(screen.getByRole('status')).toHaveTextContent('Saved')` — not `expect(component.state.saved).toBe(true)`. → gate: refactoring the component's state shape without changing visible behavior does not break the test.

---

## Decision Scenarios

**Scenario 1 — Context provider value object recreated every render causes all consumers to re-render**

> **Situation:** A `ThemeProvider` component holds `{ theme, setTheme }` as a context value created inline: `<ThemeContext.Provider value={{ theme, setTheme }}>`. Profiling reveals that every component consuming the context re-renders whenever *any* state anywhere in the app changes — even unrelated state that re-renders the `ThemeProvider` parent.

> **Competent move:** Memoize the context value: `const value = useMemo(() => ({ theme, setTheme }), [theme, setTheme])`. The inline `{}` creates a new object reference on every render, and React's context compares values by reference — all subscribers see a "changed" value and re-render. Memoizing the object ensures consumers only re-render when `theme` or `setTheme` actually changes.

> **Tempting-but-wrong:** Wrapping each consumer component in `React.memo`. `React.memo` skips re-renders due to unchanged props, but context changes are not props — `React.memo` does not prevent context-triggered re-renders. The fix must be at the provider, not the consumer.

> **Verify:** Use React DevTools Profiler before and after the fix. Before: every context consumer shows a re-render reason of "context changed" on every unrelated state update. After memoization: consumers only re-render when `theme` itself changes.

---

**Scenario 2 — `useEffect` cleanup missing from a `setInterval` in a polling component**

> **Situation:** A `LivePriceTicker` component starts a `setInterval` that fetches a price every 3 seconds inside a `useEffect` with an empty dependency array `[]`. In development (Strict Mode), multiple fetch calls fire simultaneously on mount, creating duplicate network requests. In production the component unmounts and remounts during navigation, and after navigating away the polling continues in the background.

> **Competent move:** Return a cleanup function from the effect: `return () => clearInterval(intervalId)`. React Strict Mode double-invokes effects in development to surface missing cleanup — the duplicate requests are the diagnostic signal, not a bug to suppress. The cleanup function runs on unmount and on every re-run in Strict Mode, stopping the interval correctly in both environments.

> **Tempting-but-wrong:** Disabling Strict Mode to stop the duplicate requests in development. Strict Mode is revealing a real production bug (the leaked interval after unmount). Removing it hides the signal without fixing the problem.

> **Verify:** Wrap the component in a toggle button so it can be mounted and unmounted. Without cleanup, open the browser Network tab and confirm requests continue after the component is hidden. With cleanup, requests stop immediately on unmount.

---

**Scenario 3 — `useActionState` for form submission vs manual `useState` + `onSubmit` loading flag**

> **Situation:** A React 19 project has a comment-submission form implemented with three `useState` variables (`value`, `isLoading`, `error`) and a `handleSubmit` function that sets them manually. A reviewer suggests replacing the whole pattern with `useActionState`.

> **Competent move:** Replace the three-variable pattern with `const [state, submitAction, isPending] = useActionState(postCommentAction, initialState)`. `useActionState` (React 19) encapsulates the loading/error/result lifecycle for an async action, provides a stable `isPending` boolean, and supports progressive enhancement when used with `<form action={submitAction}>`. The manual pattern is error-prone (forgetting to reset `isLoading` on error is a common bug) and requires more code.

> **Tempting-but-wrong:** Using `useReducer` to consolidate the three state fields. `useReducer` removes the multi-setState problem but still requires manual `isLoading` management and does not integrate with `<form action>` for progressive enhancement. `useActionState` is the purpose-built React 19 primitive for this exact pattern.

> **Verify:** Confirm the project is on React 19+ (`package.json`). Implement `useActionState` and verify `isPending` becomes `true` during the async call and `false` after — test with a slow mock action using `setTimeout` inside a wrapper.

---

**Scenario 4 — Testing a custom hook with `renderHook` and `act` — asserting synchronous state**

> **Situation:** A developer tests a custom `useCounter` hook by calling `renderHook(() => useCounter(0))` and immediately asserting `result.current.count === 0`. The test passes. They then call the `increment` function and assert `result.current.count === 1` — but the assertion fails because the value is still `0`.

> **Competent move:** Wrap the state-mutating call in `act()`: `act(() => { result.current.increment(); })`. React batches and flushes state updates asynchronously. `act()` tells React Testing Library to flush all pending state updates and effects before the assertion runs, so `result.current.count` reflects the post-update value.

> **Tempting-but-wrong:** Using `waitFor(() => expect(result.current.count).toBe(1))`. `waitFor` is for asynchronous operations (network calls, timers). A synchronous state update triggered by calling a hook function should be wrapped in `act()`, not awaited — using `waitFor` here works but signals a misunderstanding of what is synchronous vs asynchronous.

> **Verify:** Run the test with `act()` wrapping the `increment` call. The assertion should pass without any timeout. Also verify that omitting `act()` produces a React testing warning about "not wrapped in act" in the console — that warning is the diagnostic signal for this pattern.

---

## Operational Rules Quick Reference

Read this before writing or reviewing any React code.

- **DO** keep components pure — same props + state → same JSX, every render, no side effects in the render body.
- **DON'T** define components inside other components — each render creates a new reference; React unmounts and resets state.
- **DO** place state at the closest common ancestor of the consumers; no higher.
- **DON'T** sync derived values into state via `useEffect` — compute them during render.
- **DO** include every reactive value read inside an effect in the deps array. Never omit deps to reduce runs.
- **DON'T** write `useEffect` + `fetch` + `useState` for server data — use TanStack Query or SWR.
- **DO** return a cleanup function from every effect that sets up a subscription, timer, or connection.
- **DON'T** use array index as `key` on any list that can be reordered, filtered, or have items inserted.
- **DO** use `key` prop to intentionally reset a component's state (e.g. `<TabContent key={tab} />`, `<Form key={userId} />`). This is the preferred fix when a child's state should reset on a controlling prop change — not a `useEffect` that mirrors the prop into state.
- **DON'T** use `useEffect` to sync a prop into local state (`useEffect(() => { setState(prop) }, [prop])`). The component renders once with stale state before the effect fires. Use `key` to remount or make the component fully controlled instead.
- **DON'T** treat `aria-label` as a substitute for a visible `<label>` on form inputs — it satisfies screen readers but leaves sighted users without a persistent label. Use a visible label element for inputs; reserve `aria-label` for icon-only buttons and other cases where no visible label text is appropriate.
- **DON'T** memoize (`React.memo` / `useMemo` / `useCallback`) without measuring first — in React Compiler projects, the compiler handles this automatically.
- **DO** use `useTransition` to keep the UI responsive during expensive non-urgent renders.
- **DO** use semantic HTML first (`<button>`, `<label htmlFor>`, `<nav>`, `<main>`) before reaching for ARIA.
- **DON'T** put `onClick` on a non-interactive element without `role` and `tabIndex`.
- **DO** manage focus programmatically when modals open/close or content changes significantly.
- **DO** query with `getByRole` first in RTL tests; fall back to `getByTestId` only as a last resort.
- **DON'T** test internal state or implementation details — test what the user sees and can do.
- **DO** use `findBy*` or `waitFor` for anything that renders after an async operation.
- **DO** use `userEvent` (not `fireEvent`) for interaction in tests.
- **DO** verify against official react.dev documentation before treating any of the above as ground truth — React evolves.

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/react.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. `last-reviewed` set to 2026-06-09.
- **2026-06-09** — Curation pass (inbox: D9 audit finding): inlined 3 decision scenarios into the body (Scenarios 2–4: useEffect cleanup/Strict Mode, useActionState vs useState, renderHook/act) to meet the teaching-scenario standard (≥4 inline). references/scenarios.md deleted (all scenarios now inline). Custom hooks, Concurrent features, race-condition code block, and Folder/framework scope subsections moved to references/advanced-patterns.md to offset body length.

---

_Independent educational content for upskilling AI agents. React is a trademark of Meta Platforms, Inc. Not affiliated with, authorized by, endorsed by, or sponsored by Meta. All guidance is provided as-is; verify against official documentation and the live react.dev site before acting. No credential or certification outcome is implied._
