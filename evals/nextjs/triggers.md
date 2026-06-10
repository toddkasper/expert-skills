# Trigger tests — nextjs (Lens 2)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to nextjs  (5)

1. "Our Next.js Server Component calls `fetch` on every request even though the data doesn't change — how do I cache the response between requests?"
2. "I have a Server Action that mutates data but the page still shows the old values after it completes — I need to invalidate the cache"
3. "We're getting a 'Server Component cannot be a child of a Client Component' error in our App Router layout — how do we structure this?"
4. "Our Next.js middleware is reading an environment variable that starts with `NEXT_PUBLIC_` — a security reviewer flagged it. What's the issue?"
5. "We added a `route.ts` file in the same `app/dashboard` directory as `page.tsx` and the build is failing"

## Near-misses → a sibling  (4)

1. "Our React component fetches data in `useEffect` and we want to cache the result across multiple uses of the same hook" → `react`  (a client-side React data-fetching and custom-hook concern, not a Next.js server-rendering or caching concern)
2. "I want to add rate limiting to my Express API routes using a Redis store" → `nodejs`  (a raw Node.js/Express HTTP service concern; Next.js Route Handlers have a different API and caching model)
3. "TypeScript says `params` in my Next.js page is typed as `Promise<{ id: string }>` and I don't know how to unwrap it" → `nextjs`  (this is actually a Next.js v15+ async params API question, not a general TypeScript generics question — routes here, not `typescript`)
4. "I'm building a React hook that subscribes to a WebSocket and want to make sure it cleans up correctly" → `react`  (pure React hooks lifecycle / cleanup concern; no Next.js-specific routing or rendering involved)
