---
name: nextjs
description: Building and reviewing Next.js applications — the App Router, Server and Client Components, rendering and caching (use cache, PPR, streaming), data fetching, Route Handlers, Server Actions and their security rules, and the Proxy (formerly Middleware) layer. Use when building, reviewing, or debugging Next.js apps, routing, caching, or server actions. Excludes React fundamentals (see react) and the Node.js runtime (see nodejs). Competence skill anchored on official Next.js docs (v16.x) — no first-party certification.
metadata:
  credential: None — competence skill (no first-party Next.js certification)
  domain: web
  type: competence-playbook
  status: operational
  docs-version: "16.2.7"
  docs-retrieved: "2026-06-07"
---

# Next.js — Skills Reference

> **Version-sensitive.** Next.js moves fast. Caching semantics, middleware conventions, and
> rendering defaults differ materially between v14, v15, and v16. Every claim here is anchored
> to the official docs at version 16.2.7 (May 2026). When working on a project, check the
> installed version (`package.json`) and consult the matching docs. Study resources and version
> landmarks live in [references/study-resources.md](references/study-resources.md).

## Overview

A strong Next.js engineer reasons about **three orthogonal axes** simultaneously: (1) where code
runs (server vs client), (2) when it runs (build/prerender vs request time), and (3) how long the
result is cached. Most bugs and performance problems come from getting one of these wrong —
shipping secrets to the client, blocking renders on slow fetches, or serving stale data because
a cache was not invalidated after a mutation.

This playbook covers the App Router model (the `app/` directory). The Pages Router (`pages/`) is
a legacy path — do not build new features there.

> **Verify steps assume nothing about your tooling** — use your project's own scripts and the language toolchain (`tsc`, `node`, the test runner, the package manager), in that order of preference.

---

## 1. App Router & Component Model

### File-System Conventions

A route is only public when a `page.tsx` (or `route.ts`) file exists at the segment. Folders alone
do not expose routes. Key special filenames:

| File | Purpose | Notes |
|---|---|---|
| `layout.tsx` | Persistent shell wrapping child segments | Root layout must include `<html>` and `<body>` |
| `page.tsx` | Public route UI | Receives `params` and `searchParams` props |
| `loading.tsx` | Suspense fallback for the segment | Wraps `page.tsx` in a `<Suspense>` automatically |
| `error.tsx` | React error boundary for the segment | Must be a Client Component |
| `not-found.tsx` | Rendered by `notFound()` | |
| `template.tsx` | Like layout but re-mounts on navigation | Use sparingly — prefer layout |
| `route.ts` | Route Handler (API endpoint) | Cannot coexist with `page.tsx` in the same segment |
| `default.tsx` | Parallel route fallback | Required when using `@slot` parallel routes |
| `global-error.tsx` | Root-level error boundary | Replaces the root layout on error |

**Folder conventions:**

| Convention | Effect |
|---|---|
| `[slug]` | Dynamic segment — accessible via `params.slug` |
| `[...slug]` | Catch-all — matches one or more segments |
| `[[...slug]]` | Optional catch-all — also matches the parent path |
| `(group)` | Route group — organizes files without affecting the URL |
| `_folder` | Private folder — excluded from routing entirely |
| `@slot` | Parallel route named slot — rendered by the parent layout |
| `(.)sibling` | Intercepting route — renders sibling route in the current context |

**Component hierarchy inside a segment** (outer → inner):
`layout` → `template` → `error` → `loading` → `not-found` → `page`

### Server vs Client Components

**Default: every layout and page is a Server Component** unless `"use client"` is declared.

| Need | Component type |
|---|---|
| `useState`, `useEffect`, event handlers (`onClick`, `onChange`) | Client |
| Browser APIs (`localStorage`, `window`, `navigator`) | Client |
| Custom hooks that use state or effects | Client |
| Direct DB/ORM queries, secrets, `process.env` non-public vars | Server |
| Large static subtrees with no interactivity | Server |

**The boundary rule:** `"use client"` at the top of a file marks a boundary. Everything that
file imports — its entire module graph — becomes part of the client bundle. Server Components
can be passed *into* a Client Component as `children` or other props and still render on the
server; they just cannot be *imported* inside the client module graph.

**Key patterns:**

- Push `"use client"` to leaf components. Never put it on a page or layout unless the entire
  route is interactive — that ships all the data fetching logic to the client.
- Third-party components that use client-only APIs but lack `"use client"` must be wrapped in
  a thin Client Component that adds the directive.
- Props passed from Server to Client Components must be **serializable** (no functions, no
  class instances, no Dates as objects — use ISO strings).
- Use `import 'server-only'` in any module that must never reach the client (DAL, secret
  access). Next.js turns this into a build-time error if the module is imported in a Client
  Component.
- `NEXT_PUBLIC_` prefix is required for any env var that the client bundle may read. All
  others are stripped to an empty string in the client build.

**Red flags in review:**
- A `page.tsx` or `layout.tsx` that starts with `"use client"` but does data fetching — move
  the fetch to a Server Component parent and pass the result as props.
- A Server Component importing a module that uses `window` or `localStorage` — will fail at
  runtime.
- A Client Component prop typed as a full DB row — narrows to a DTO to avoid over-sharing.
- A `useEffect` fetch in a Client Component where a Server Component async fetch would work.

---

## 2. Rendering & Caching

### Rendering Model (PPR + Cache Components, v15+)

With `cacheComponents: true` in `next.config.ts` (the recommended default in v15+), Next.js
uses **Partial Prerendering (PPR)** as the default:

- Components marked `"use cache"` → rendered at build time and included in the static shell.
- Components accessing runtime APIs (`cookies()`, `headers()`, `searchParams`, uncached fetches)
  → wrapped in `<Suspense>` → their fallback is in the static shell; content streams at request
  time.
- Pure synchronous/deterministic computations → included in the static shell automatically.

**Outcome:** the browser receives a complete HTML shell instantly on any page load; dynamic
personalized content streams in after.

**Legacy rendering without Cache Components:** uses `export const dynamic`, `export const revalidate`, and `fetch()` cache options. See [references/study-resources.md](references/study-resources.md) for the legacy guide link. Do not mix the two models in the same file.

### Caching APIs (`use cache` model)

```
'use cache'           — directive on an async function or component
cacheLife(profile)    — sets stale/revalidate/expire (call inside "use cache" scope)
cacheTag('name')      — tags the cache entry for on-demand invalidation
```

**Built-in `cacheLife` profiles:**

| Profile | Stale | Revalidate | Expire |
|---|---|---|---|
| `seconds` | 0 | 1s | 60s |
| `minutes` | 5m | 1m | 1h |
| `hours` | 5m | 1h | 1d |
| `days` | 5m | 1d | 1w |
| `weeks` | 5m | 1w | 30d |
| `max` | 5m | 30d | ~indefinite |

Short-lived profiles (`seconds`, or `revalidate: 0`, or `expire` < 5 min) are automatically
excluded from prerenders and become dynamic streaming holes.

### Revalidation Decision Table

| Scenario | API to use | Where callable |
|---|---|---|
| User submits a form; they must see their change immediately | `updateTag('tag')` | Server Actions only |
| CMS updates content; slight delay to other users is fine | `revalidateTag('tag')` | Server Actions + Route Handlers |
| Revalidate by path when tags are not known | `revalidatePath('/route')` | Server Actions + Route Handlers |
| Time-based automatic refresh | `cacheLife(profile)` inside `use cache` | Any async function/component |

**Prefer tag-based over path-based** — `revalidatePath` over-invalidates (everything on that
path) whereas tags are surgical.

### Streaming

Two mechanisms to stream at request time:

1. **`loading.tsx`** — streams the entire page segment; the loading UI is the Suspense fallback.
   Avoid putting uncached runtime data access in `layout.tsx` — the layout's `loading.tsx`
   cannot cover it, blocking the whole segment.
2. **`<Suspense fallback={...}>`** — streams individual components. Wrap any component that
   accesses runtime data. The fallback is part of the static shell.

**Do not** `await` an empty `<Suspense fallback={null}>` over the `<body>` in the root layout —
it opts the entire app out of the static shell, making every request fully dynamic.

**Red flags in review:**
- An async function without `'use cache'` that fetches data not wrapped in `<Suspense>` — will
  emit a build error (`Uncached data was accessed outside of <Suspense>`).
- `cacheLife` called outside a `'use cache'` scope — silently ignored.
- `use cache` directly in a Route Handler body — must be extracted to a helper function.
- `updateTag` called from a Route Handler — only valid in Server Actions.
- Using `revalidatePath` where a tag would be precise enough — creates unnecessary cache churn.

---

## 3. Data Fetching, Mutations & Cross-Cutting

### Data Fetching Patterns

**Server Components** are the primary data-fetching location. Query the DB or call APIs directly:

```
async function Page() {
  const data = await db.query(...)   // runs only on server, never ships to client
  return <UI data={data} />
}
```

**Parallel fetching:** initiate multiple independent requests without `await`, then
`Promise.all([...])` — never chain sequential `await` calls when requests are independent.

**`React.cache`:** wrap a data-fetching function in `React.cache()` to memoize within a single
request. Multiple Server Components calling the same cached function pay the fetch cost once.
Scope is per-request only — no sharing across requests.

**Client Components** should fetch data via:
- The React `use()` API — accept a Promise prop from a Server Component parent and call
  `use(promise)` inside a `<Suspense>` boundary.
- SWR / TanStack Query — for post-render client-side fetching (user interactions, polling).

Do not `fetch()` inside a `useEffect` to load initial data when a Server Component async fetch
would work — the latter avoids shipping the fetch logic, API URL, and any secrets to the client.

### Route Handlers vs Server Actions

| | Route Handlers (`route.ts`) | Server Actions (`"use server"`) |
|---|---|---|
| Protocol | Any HTTP verb | POST only |
| Primary use | External callers (webhooks, mobile apps, public APIs), or GET endpoints that benefit from explicit caching | In-app mutations triggered by forms or UI events |
| Caching (`GET`) | Not cached by default; opt in with `export const dynamic = 'force-static'` or `use cache` helper | N/A |
| Type safety | Manual | Automatic (same-repo call) |
| Progressive enhancement | No | Yes (works without JS) |
| `route.ts` + `page.ts` conflict | Cannot coexist in the same segment | N/A |

**Rule:** if the caller is inside the same Next.js app (a Server or Client Component), reach
for a Server Action. Use a Route Handler only when you need an HTTP endpoint reachable by
external consumers.

### Server Action Security Rules

These are non-negotiable. Every Server Action is a reachable POST endpoint:

1. **Always re-verify authentication inside the action.** A page-level auth check does not
   extend to its actions. The UI redirect prevents the UI from rendering; it does not block a
   direct POST to the action's ID.
2. **Always check authorization (not just authentication).** Confirm the caller owns the
   resource they are mutating — prevents Insecure Direct Object Reference (IDOR).
3. **Validate all inputs.** `formData`, `searchParams`, and URL params are user-controlled.
4. **Return only what the UI needs.** Never return a raw DB record — strip to a DTO.
5. **CSRF:** Next.js compares `Origin` vs `Host` (or `X-Forwarded-Host`) and aborts if they
   differ. For reverse-proxy setups, set `serverActions.allowedOrigins` in `next.config.js`.
   Session cookies must use `SameSite=Lax` or `Strict`.
6. **Closure encryption:** closed-over variables in inline Server Actions are encrypted and
   round-trip through the client. Do not rely on encryption alone — avoid capturing secrets
   in closures. For multi-server deployments, set `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`.

**Data Access Layer (DAL) pattern** (recommended for any serious app):

- Keep all DB queries + auth/authz checks in a `server-only` module (`import 'server-only'`).
- Server Actions are thin wrappers that call DAL functions and then call `updateTag` /
  `revalidatePath`.
- Pages and components call DAL functions directly — never `fetch` their own app's API routes.

**Red flags in review:**
- A Server Action that calls `auth()` only at the page level, not inside the action itself.
- An action that returns `db.user.findUnique(...)` directly — returns raw DB record.
- An action that does not check `post.authorId === session.user.id` before updating a record.
- `'use server'` at file level with no auth check in every exported function.

### Proxy (formerly Middleware)

> `middleware.ts` was renamed to `proxy.ts` in Next.js v16. The `npx @next/codemod@canary
> middleware-to-proxy .` codemod migrates the file and the export name. Proxy now defaults to
> the **Node.js runtime** (previously required Edge).

Proxy runs before routes are rendered. Use it for:
- Auth redirects (check cookie/token → redirect to login)
- Request header injection (add user context headers for downstream Server Components)
- CORS preflight handling for Route Handlers
- URL rewrites / A-B routing at the CDN layer

**Critical security rule (CVE-2025-29927):** Proxy alone is not a sufficient auth gate. An
attacker can manipulate internal headers to bypass proxy checks. Always re-verify auth inside
every Server Action and every sensitive Route Handler — the Data Access Layer pattern enforces
this. Proxy is a UX layer (redirect to login), not the security enforcement layer.

**Proxy rules:**
- Without a `matcher`, Proxy runs on every request including static assets. Always configure a
  matcher that excludes `_next/static`, `_next/image`, and `favicon.ico`.
- `matcher` values must be constants — no dynamic values; they are statically analyzed.
- Pass data to the app via headers, cookies, rewrites, or redirects — not shared globals.
- Do not put ORM imports or heavy business logic in proxy — it runs outside the main runtime.
- `_next/data` routes are still covered by Proxy even when excluded from a negative matcher.

**Red flags:**
- Auth enforcement only in `proxy.ts` with no check inside the Server Action or Route Handler.
- Missing matcher exclusions causing Proxy to run on static file requests.
- Importing a full ORM or database client in proxy.

---

## Operational Rules Quick Reference

- **DO** treat Server Components as the default; reach for `"use client"` only when hooks,
  event handlers, or browser APIs are needed.
- **DON'T** put `"use client"` on a page or layout that primarily fetches data — ship the
  fetch to a Server Component parent.
- **DO** use `import 'server-only'` in every module that accesses secrets, DB, or auth logic.
- **DON'T** pass secrets or full DB records as props to Client Components — narrow to a DTO.
- **DO** call `use cache` + `cacheLife` on any async function whose result can be reused across
  requests; wrap request-time data in `<Suspense>`.
- **DON'T** put `use cache` directly in a Route Handler body — extract to a helper function.
- **DO** prefer `updateTag` (immediate) for read-your-own-writes after a form submit; use
  `revalidateTag` (stale-while-revalidate) for background content freshness.
- **DON'T** use `updateTag` from a Route Handler — it is Server Actions only.
- **DO** verify auth and authz inside every Server Action, independently of any page-level check.
- **DON'T** trust `searchParams`, `params`, or form data without validation inside the action.
- **DO** use `Promise.all` for independent parallel fetches; never chain sequential `await`s
  on unrelated requests.
- **DON'T** access runtime APIs (`cookies()`, `headers()`) in a component without wrapping it
  in `<Suspense>` — or wrapping it in a `use cache` component that extracts the value as an arg.
- **DO** configure a Proxy `matcher` that excludes static assets; without one, Proxy fires on
  every asset request.
- **DON'T** rely on Proxy alone for security — always re-verify in the Server Action / Route
  Handler (CVE-2025-29927).
- **DO** check the installed `next` version in `package.json` before applying caching or
  middleware guidance — semantics changed materially in v15 and v16.

---

> Study resources live in [references/study-resources.md](references/study-resources.md).

---

_Independent educational content to upskill AI agents. Next.js is a trademark of Vercel, Inc.
Not affiliated with or endorsed by Vercel. Guidance only — verify against official documentation
for the version installed in your project._
