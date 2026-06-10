# React — Decision Scenarios

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
