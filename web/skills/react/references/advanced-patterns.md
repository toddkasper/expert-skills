# Advanced Patterns Reference — React

> Loaded on demand from the React skill body. Sections here are linked with explicit load cues.

---

## Memoization

Default: don't. Re-renders are cheap unless profiling shows otherwise. The React Compiler (stable as of late 2025, production-ready) `[volatile — verify live]` automatically inserts the equivalent of `React.memo`, `useMemo`, and `useCallback` where they're beneficial — in compiler-enabled projects, manual memoization is usually redundant.

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

---

## Custom Hooks

A custom hook is a JavaScript function whose name starts with `use` that calls other hooks. Extract into a custom hook when the same stateful logic appears in two or more components. A custom hook does not share *state* between callers — each call gets independent state. Shared behavior, not shared state.

---

## Concurrent Features

- **`useTransition` / `startTransition`** — mark a state update as non-urgent; React can interrupt and restart the deferred work to stay responsive. Use when you control the state update (e.g., you own the `setState` call). **Critical constraint:** `useTransition` cannot be used to control text inputs — react.dev states this explicitly. Trying to wrap `setInputValue` in `startTransition` will not work correctly for controlled inputs. Source: react.dev/reference/react/useTransition.
- **`useDeferredValue`** — pass a value whose derived/expensive rendering should be deferred. React immediately starts an interruptible background re-render with the new value while keeping the previous value visible. **This is not a debounce/timer** — no delay is introduced; the deferred render starts immediately but is interruptible by more-urgent updates. **`useDeferredValue` only helps when the expensive consumer is wrapped in `React.memo`** (or otherwise memoized) — without memoization, the child re-renders synchronously regardless of the deferred value. Correct pattern for a laggy controlled filter input: keep `value` in state (controlled), pass `useDeferredValue(value)` to a `memo`-wrapped expensive list. Source: react.dev/reference/react/useDeferredValue.
- **`Suspense`** — declaratively show a fallback while async content (lazy-loaded components, data-fetching with frameworks) is loading. Wrap slow subtrees; place boundaries close to where the loading state should appear.

**Quick tool-selection guide:**

| Scenario | Correct tool |
|---|---|
| You control the state update (non-text) | `useTransition` / `startTransition` |
| Laggy *controlled* text input + expensive child | `useDeferredValue` + `memo` on consumer (or two-state split) |
| You receive a value you don't control (from prop/context) | `useDeferredValue` + `memo` on consumer |
| Slow-loading component or data source | `Suspense` + lazy / data library |

---

## Race Condition

When a component fetches data on a changing prop (e.g. `userId`), a slow response from the old request can overwrite the new response. Fix: use the effect cleanup function to set an `ignore` flag, or use a library (TanStack Query, SWR) that handles this automatically.

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

---

## Folder Structure and Framework Scope

**Folder / feature structure:** no single correct structure exists, but prefer **feature-based co-location** over type-based grouping. Co-locate tests, styles, and subcomponents with the feature they belong to. Avoid deep nesting. Keep shared UI primitives in a `components/ui` or `components/common` layer; keep business logic in hooks or service modules, not inside JSX.

**Framework scope boundary:**

- **Next.js concerns** (App Router, Server Components, Server Actions, layouts, `generateStaticParams`): see the `nextjs` skill. This skill covers React client components only. The React 19 `use()` hook, `useActionState`, `useOptimistic`, and `useFormStatus` are React-layer primitives usable across frameworks — they are in scope here.
- **React Native / Expo concerns** (StyleSheet, navigation, native modules, Metro bundler): see the `react-native` skill.

---

## Accessibility: Input Accessible Name

| Scenario | Correct fix |
|---|---|
| Text input missing a label | `<label htmlFor="inputId">` + matching `id` on input (or wrap input inside label) |
| Icon-only button (no visible text) | `aria-label="Descriptive action"` on the button — correct and complete here |
| Input with only placeholder text | Add a visible label; placeholder disappears on type and has poor contrast |
| Input where space truly forbids a visible label | `aria-label` or `aria-labelledby` as last resort; document the trade-off |

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
