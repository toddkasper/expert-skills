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

### `useReducer` — when to prefer over `useState`

Use `useReducer` when: (a) next state depends on previous in complex ways, (b) several state fields change together as a unit, or (c) you want to move update logic out of the component for testability. Reducer functions are pure — they receive state + action and return the next state; no side effects inside.

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

### `useRef` — mutable, non-reactive

Refs hold a value that doesn't trigger re-renders when changed. Use for: DOM node references, storing the previous value of a prop, holding a timer ID, tracking whether a component has mounted. Do **not** read or write a ref during rendering — refs are outside the React data flow.

### `useContext` — boundaries matter

Context eliminates prop-drilling for genuinely cross-cutting values (theme, locale, current user). It is not a replacement for server-state caching or complex shared state — for those, use TanStack Query or an external store (Zustand, Redux Toolkit). Every subscriber re-renders when context value changes, so split contexts by change frequency to avoid over-renders; memoize the provider value object.

### Custom hooks

A custom hook is a JavaScript function whose name starts with `use` that calls other hooks. Extract into a custom hook when the same stateful logic appears in two or more components. A custom hook does not share *state* between callers — each call gets independent state. Shared behavior, not shared state.

---

## 2. Rendering & Performance

### How React renders

Rendering = calling your component function to produce a new JSX tree. React compares the new tree to the previous one (reconciliation) and commits only the changed DOM nodes. The DOM is NOT touched unless something changed. Three phases: **Trigger** (state update or initial mount) → **Render** (pure function call) → **Commit** (DOM update).

**State updates are batched** in React 18+. Multiple `setState` calls in a single event handler are batched into a single re-render.

### When to memoize — and when not to

Default: don't. Re-renders are cheap unless profiling shows otherwise. The React Compiler (stable as of late 2025, production-ready) automatically inserts the equivalent of `React.memo`, `useMemo`, and `useCallback` where they're beneficial — in compiler-enabled projects, manual memoization is usually redundant.

Without the compiler, apply the trio only after measuring:

| Tool | Memoizes | Correct use |
|---|---|---|
| `React.memo(Component)` | The component's render output | A child that re-renders frequently with the same props and has expensive render logic |
| `useMemo(fn, deps)` | The return value of `fn` | An expensive pure calculation whose deps change infrequently |
| `useCallback(fn, deps)` | The function reference | A callback passed as prop to a `memo`-wrapped child, to prevent spurious re-renders |

`useMemo` and `useCallback` only help when the wrapped value is passed to a component or hook that checks referential equality. Wrapping everything is not free — there is overhead, and it clutters the code.

**Structural patterns that avoid re-renders without memoization:**
- Accept JSX children as `children` prop so the parent, not the consumer, controls when children re-render.
- Keep state local — don't lift it higher than necessary.
- Split contexts by update frequency.

### Key prop — the reset lever

Giving a component a different `key` tells React to unmount the old instance and mount a new one, resetting all its state. This is the correct fix for "reset form when user changes" — `<Form key={userId} />` — not an effect that clears state fields.

### Concurrent features (React 18+)

- `useTransition` / `startTransition` — mark a state update as non-urgent; React can interrupt it to stay responsive. Use for expensive renders triggered by user input (e.g., filtering a large list while keeping the input responsive).
- `useDeferredValue` — defer re-rendering a slow child with a stale value until the browser is idle. Similar to debounce but integrated with React's scheduler.
- `Suspense` — declaratively show a fallback while async content (lazy-loaded components, data-fetching with frameworks) is loading. Wrap slow subtrees; place boundaries close to where the loading state should appear.

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
| Optimistic updates before server confirmation | `useOptimistic` (React 19) or TanStack Query's `optimisticUpdate` |
| Form submission with loading/error state | `useActionState` (React 19) replaces the `useState` + `onSubmit` + loading flag pattern |
| Client/global UI state | `useState` / `useReducer` + context, or Zustand |
| Complex cross-component state | Redux Toolkit or Zustand |

Avoid writing `useEffect` + `fetch` + `useState` for server data — you get no caching, no deduplication, and race conditions. Use TanStack Query or SWR instead.

**Race condition:** when a component fetches data on a changing prop (e.g. userId), a slow response from the old request can overwrite the new response. Fix: use the effect cleanup function to set an `ignore` flag, or use a library that handles this automatically.

```js
// Correct pattern if you must use useEffect + fetch
useEffect(() => {
  let ignore = false;
  fetchUser(userId).then(data => {
    if (!ignore) setUser(data);
  });
  return () => { ignore = true; };
}, [userId]);
```

### State architecture decisions

| Question | Guidance |
|---|---|
| Does only one component need this? | Keep it local with `useState` |
| Do sibling components need the same data? | Lift to closest common ancestor |
| Is it remote/server data that must be cached? | TanStack Query / SWR, not context |
| Is it shared UI state across many unrelated components? | Context (if low-frequency updates) or Zustand |
| Is the update logic complex or shared? | `useReducer` with context, or Redux Toolkit |

### Folder / feature structure

No single correct structure exists, but prefer **feature-based co-location** over type-based grouping. Co-locate tests, styles, and subcomponents with the feature they belong to. Avoid deep nesting. Keep shared UI primitives in a `components/ui` or `components/common` layer; keep business logic in hooks or service modules, not inside JSX.

### Framework scope boundary

**Next.js concerns (App Router, Server Components, Server Actions, layouts, `generateStaticParams`):** see the `nextjs` skill. This skill covers React client components only. The React 19 `use()` hook, `useActionState`, `useOptimistic`, and `useFormStatus` are React-layer primitives usable across frameworks — they are in scope here.

**React Native / Expo concerns** (StyleSheet, navigation, native modules, Metro bundler): see the `react-native` skill.

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

## Decision Scenarios

**Scenario 1 — Context provider value object recreated every render causes all consumers to re-render**

> **Situation:** A `ThemeProvider` component holds `{ theme, setTheme }` as a context value created inline: `<ThemeContext.Provider value={{ theme, setTheme }}>`. Profiling reveals that every component consuming the context re-renders whenever *any* state anywhere in the app changes — even unrelated state that re-renders the `ThemeProvider` parent.

> **Competent move:** Memoize the context value: `const value = useMemo(() => ({ theme, setTheme }), [theme, setTheme])`. The inline `{}` creates a new object reference on every render, and React's context compares values by reference — all subscribers see a "changed" value and re-render. Memoizing the object ensures consumers only re-render when `theme` or `setTheme` actually changes.

> **Tempting-but-wrong:** Wrapping each consumer component in `React.memo`. `React.memo` skips re-renders due to unchanged props, but context changes are not props — `React.memo` does not prevent context-triggered re-renders. The fix must be at the provider, not the consumer.

> **Verify:** Use React DevTools Profiler before and after the fix. Before: every context consumer shows a re-render reason of "context changed" on every unrelated state update. After memoization: consumers only re-render when `theme` itself changes.

Further scenarios: [references/scenarios.md](references/scenarios.md)

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

_Independent educational content for upskilling AI agents. React is a trademark of Meta Platforms, Inc. Not affiliated with, authorized by, endorsed by, or sponsored by Meta. All guidance is provided as-is; verify against official documentation and the live react.dev site before acting. No credential or certification outcome is implied._
