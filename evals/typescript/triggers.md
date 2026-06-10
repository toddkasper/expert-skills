# Trigger tests — typescript (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to typescript  (5)

1. "Our published npm package's `.d.ts` file declares a method that was removed in v2 but consumers' type-checks still pass — how do I fix the declaration file?"
2. "I have a generic function `function wrap<T>(val: T): Box<T>` and I can't constrain T to only object types — what's the correct constraint syntax?"
3. "TypeScript is widening my string literal to `string` when I infer it through a generic — how do I preserve the literal type?"
4. "We cast the result of `JSON.parse()` to our `ApiResponse` type with `as` and now we're getting runtime crashes — what's the type-safe pattern?"
5. "I'm getting a TS error: 'Type string is not assignable to type never' inside my exhaustive switch — what does that mean and how do I add a proper exhaustiveness check?"

## Near-misses → a sibling  (4)

1. "Our React component props have a TypeScript error: 'Property children does not exist on type IntrinsicElements'" → `react`  (the question is about React's JSX component model and `PropsWithChildren`; the typing is incidental to React's component contract, not a standalone TS type-system concern)
2. "The Next.js `generateStaticParams` function is returning the wrong type and the build fails" → `nextjs`  (a Next.js framework API type mismatch, not a general TypeScript pattern question)
3. "My Node.js service's `process.env.PORT` is typed as `string | undefined` and I need to narrow it before passing to `parseInt`" → `nodejs`  (while narrowing is a TS concept, the question is scoped to Node.js runtime env-var patterns; the skill description explicitly says 'typing Node APIs' lives in typescript but this framing is a Node service concern — a borderline case; however because the phrasing is 'my Node.js service' it routes to nodejs first)
4. "Expo's `useLocalSearchParams` is returning `string | string[]` for a param I know is always a single string — how do I handle this in my screen?" → `react-native`  (an Expo Router / React Native navigation API question; the type narrowing is subordinate to the mobile framework concern)
