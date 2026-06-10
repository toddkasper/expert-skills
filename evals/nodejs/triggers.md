# Trigger tests — nodejs (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to nodejs  (5)

1. "Our Node.js service is OOMing under load — we're piping a large file to the HTTP response, help me find the backpressure problem"
2. "Review this Express middleware: it calls `exec(userInput)` to run a shell command and logs the full request body to stdout"
3. "My npm package has both a `main` and an `exports` field but ESM consumers get 'not a module' errors — what's the correct exports map?"
4. "We have a floating Promise inside a forEach loop that calls our database; the function returns before the writes finish"
5. "A Lambda handler uses `fs.readFileSync` in the hot path — is this a problem and how do I fix it?"

## Near-misses → a sibling  (4)

1. "Our Next.js API route streams a large file to the browser and memory is growing" → `nextjs`  (the concern is a Route Handler inside the Next.js framework, not the raw Node runtime; the fix involves Next.js streaming primitives, not `.pipe()` backpressure directly)
2. "I keep getting 'Property does not exist' errors after I narrowed a union type in TypeScript — how do I fix the type guards?" → `typescript`  (pure type-system question; no Node runtime involved)
3. "Our React app makes a `fetch` call inside `useEffect` on mount — is this the right pattern?" → `react`  (a UI data-fetching lifecycle concern, not a Node service concern)
4. "The getServerSideProps function in our Next.js page calls `db.query()` synchronously — should it be async?" → `nextjs`  (Next.js data-fetching API, not the Node runtime in isolation)
