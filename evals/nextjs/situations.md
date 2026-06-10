# Eval situations — nextjs

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. You are reviewing a PR that adds a `UserDashboard` page. The `page.tsx` begins with `"use client"` and contains an `async` function that calls `db.query(...)` directly, rendering the results. A teammate says "it works in dev." What is wrong, and what is the correct structure?

2. A component deep in the tree reads from `localStorage` to decide which theme banner to show. It is currently a Server Component and throws at runtime. Your fix is to add `"use client"` to the component's file. A senior engineer says that is wrong — the real fix is different. What should you do instead, and why?

3. You have a `ProductList` Server Component and a `CartButton` Client Component. You want `CartButton` to appear inside `ProductList` without converting `ProductList` to a Client Component. How do you structure this — and what is the one pattern that silently fails if you get it wrong?

4. Your `app/dashboard/route.ts` is a Route Handler that returns user analytics. The same app has `app/dashboard/page.tsx`. Deployments succeed locally but the production build throws. What is the conflict, and how do you resolve it while preserving both the API endpoint and the dashboard page?

5. A Server Action handles a form submission that updates the current user's profile. The page-level layout already calls `auth()` and redirects unauthenticated users. A reviewer flags the action as a security hole even though no unauthenticated user can reach the page. Why, and what must the action do?

6. After a user submits a "publish post" form backed by a Server Action, they briefly still see their old post count on the page. The action calls `revalidateTag('posts')` before returning. Why might the count still be stale for that specific user immediately after submit, and what should you call instead?

7. You are migrating a v14 Next.js app to v16. The old `middleware.ts` uses `export { middleware }` and a `matcher` config. The app starts but the proxy never runs. What two migration steps are required, and which codemod covers them?

8. You have a `fetchProductPrices()` async function called from three different Server Components on the same page render. Each call hits an external pricing API. Users are reporting the page is slow. What is the correct fix to ensure the API is called only once per request, and what scope does the cache have?

9. A component accesses `cookies()` to read the session token and is used inside a `layout.tsx`. Testers report that the page never streams — users always wait for the full layout before seeing any content. Why, and what is the minimal structural change to fix it?

10. A Route Handler at `app/api/webhook/route.ts` processes incoming webhook events and calls `updateTag('orders')` to immediately flush the orders cache after each event. Code review passes, but `updateTag` silently does nothing in production. Why, and what should the handler call instead?

11. You deploy a new feature where a Server Component passes a `createdAt: Date` object as a prop to a Client Component. Everything works in local dev (Node.js serializes Dates). The production build throws a serialization error. What is wrong, and what is the correct fix?

12. A security audit flags your app: the `proxy.ts` file checks the session cookie and redirects unauthenticated requests to `/login`. The auditor marks the auth as insufficient even though 100% of unauthenticated browser requests are correctly redirected. What is the auditors concern, and what must you add?

13. A developer migrating a Next.js 15 app to v16 reads that the project already had `experimental.useCache: true` in `next.config.ts`. They assume this means `cacheComponents` is already active in v16 and skip setting it. They then notice that all `use cache` directives silently have no effect. What is the root cause, and what must they do to restore caching? Additionally, a teammate argues the v15 app "already had PPR on" because `experimental.ppr` was enabled — what is the precise relationship between `experimental.ppr` in v15 and `cacheComponents` in v16?
