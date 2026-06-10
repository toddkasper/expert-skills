# React — Study Resources

Official and community resources for deepening React competence. Verify links are current before use.

## Official Documentation

- **react.dev** — the canonical reference. Start here. Covers all built-in hooks, the component model, rendering, data flow, performance, and testing integration. <https://react.dev>
- **React blog** — announces releases, deprecations, and migration guides. Follow for React 19+ changes (useActionState, Server Actions, Compiler). <https://react.dev/blog>
- **React Compiler docs** — introduction, setup, and caveats for automatic memoization. <https://react.dev/learn/react-compiler/introduction>

## Hooks Reference

- Built-in hooks listed with signatures and canonical examples: <https://react.dev/reference/react/hooks>
- "You Might Not Need an Effect" — the single most important reading for effect discipline: <https://react.dev/learn/you-might-not-need-an-effect>
- Rules of hooks: <https://react.dev/reference/rules/rules-of-hooks>

## Testing

- **React Testing Library** — primary test utilities, query priority guide, async patterns: <https://testing-library.com/docs/react-testing-library/intro/>
- **jest-dom** — custom matchers (toBeDisabled, toHaveValue, etc.): <https://github.com/testing-library/jest-dom>
- **user-event** — realistic event simulation (prefer over `fireEvent`): <https://testing-library.com/docs/user-event/intro>
- Testing custom hooks with `renderHook`: <https://testing-library.com/docs/react-testing-library/api/#renderhook>

## Accessibility

- React accessibility guide (legacy docs, still accurate): <https://legacy.reactjs.org/docs/accessibility.html>
- MDN — ARIA authoring practices, role reference: <https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA>
- WAI-ARIA Authoring Practices Guide (APG) — patterns for common widgets (modal, listbox, tabs): <https://www.w3.org/WAI/ARIA/apg/>

## Performance

- React DevTools Profiler: <https://react.dev/learn/react-developer-tools>
- React.memo, useMemo, useCallback reference: <https://react.dev/reference/react/memo>
- Concurrent features (Suspense, useTransition, useDeferredValue): <https://react.dev/reference/react/Suspense>

## Data Fetching

- TanStack Query (formerly React Query) — server-state caching, background refetch, stale-while-revalidate: <https://tanstack.com/query/latest>
- SWR — lightweight alternative from Vercel: <https://swr.vercel.app>
- React 19 `use()` hook and Server Functions: <https://react.dev/reference/rsc/server-functions>

## State Management

- Zustand — minimal external store: <https://zustand-demo.pmnd.rs/>
- Jotai — atomic state: <https://jotai.org/>
- Redux Toolkit — for complex, shared global state: <https://redux-toolkit.js.org/>
- Context vs external store guidance: <https://react.dev/learn/scaling-up-with-reducer-and-context>

## Framework-Specific Resources (deferred to sibling skills)

- **Next.js** — App Router, Server Components, Server Actions: see the `nextjs` skill
- **React Native / Expo** — mobile-specific rendering, navigation, native modules: see the `react-native` skill

---

_Independent educational content. React is a trademark of the React Foundation (a Linux Foundation project) `[volatile — verify live]`. Not affiliated with or endorsed by the React Foundation or any contributor. See react.dev/blog/2026/02/24/the-react-foundation._
