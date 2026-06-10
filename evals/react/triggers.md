# Trigger tests — react (Lens 2)

Routing regression set. Test each phrings against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to react  (5)

1. "My `useEffect` runs on every render even though I passed a dependency array — the linter says I'm missing a dependency but adding it causes an infinite loop"
2. "I defined a child component inside the render function of the parent and now inputs inside it lose focus on every keystroke — what's happening?"
3. "I'm mapping over a list with `key={index}` and after reordering, checkboxes show the wrong checked state"
4. "How do I debounce a search input in React without using a library, and why does putting the debounce inside the component cause bugs?"
5. "My `React.memo` wrapped component still re-renders every time the parent renders — what should I check?"

## Near-misses → a sibling  (3)

1. "In our Next.js app a Server Component fetches data but it re-fetches on every request instead of caching — how do I control that?" → `nextjs`  (a Next.js caching and `fetch` configuration concern, not a React hooks/rendering question)
2. "Our React Native FlatList re-renders every item when any state changes — how do I optimize this?" → `react-native`  (mobile-specific FlatList performance and `getItemLayout`; the `react-native` skill covers the mobile component deltas)
3. "I want to add an `onClick` handler to a custom component but TypeScript says the prop doesn't exist" → `typescript`  (a type-system question about component prop typing / event handler types, not a React rendering or hooks concern)
