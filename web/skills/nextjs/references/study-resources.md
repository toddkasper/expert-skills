# Next.js — Study Resources

Official sources only. No third-party content reproduced here — link and read directly.

## Official Documentation

| Resource | URL | Notes |
|---|---|---|
| Next.js Docs (App Router) | https://nextjs.org/docs/app | Primary reference; version-sensitive — check `version` in frontmatter |
| Server & Client Components | https://nextjs.org/docs/app/getting-started/server-and-client-components | Boundary rules, composition patterns |
| Project Structure | https://nextjs.org/docs/app/getting-started/project-structure | File conventions, routing primitives |
| Fetching Data | https://nextjs.org/docs/app/getting-started/fetching-data | fetch API, ORM patterns, parallel/sequential |
| Caching (Cache Components model) | https://nextjs.org/docs/app/getting-started/caching | `use cache`, PPR, streaming — requires `cacheComponents: true` |
| Caching (previous model) | https://nextjs.org/docs/app/guides/caching-without-cache-components | Legacy `fetch` cache options, `export const dynamic` |
| Revalidating | https://nextjs.org/docs/app/getting-started/revalidating | `cacheLife`, `cacheTag`, `revalidateTag`, `updateTag`, `revalidatePath` |
| Route Handlers | https://nextjs.org/docs/app/getting-started/route-handlers | `route.ts`, HTTP methods, caching behavior |
| Data Security | https://nextjs.org/docs/app/guides/data-security | DAL pattern, Server Action security, taint API |
| Proxy (formerly Middleware) | https://nextjs.org/docs/app/api-reference/file-conventions/proxy | Renamed in v16; matcher, cookies, headers, CORS |
| Edge Runtime | https://nextjs.org/docs/app/api-reference/edge | Available APIs; what is NOT available |
| Authentication Guide | https://nextjs.org/docs/app/guides/authentication | Auth patterns for App Router |
| Forms Guide | https://nextjs.org/docs/app/guides/forms | Server Actions + useActionState |
| Streaming Guide | https://nextjs.org/docs/app/guides/streaming | Suspense, loading.js, PPR trade-offs |
| `use cache` directive | https://nextjs.org/docs/app/api-reference/directives/use-cache | Serialization constraints, cache keys |
| `use client` directive | https://nextjs.org/docs/app/api-reference/directives/use-client | Boundary semantics |
| `use server` directive | https://nextjs.org/docs/app/api-reference/directives/use-server | Server Action security, allowed origins |
| Deploying | https://nextjs.org/docs/app/getting-started/deploying | Node.js server, Docker, static export, adapters |

## Version Landmarks (as of 2026-06-07)

Docs retrieved at version **16.2.7** (May 2026). Key version-sensitive changes:

| Version | Change |
|---|---|
| v16.0.0 | `middleware.ts` deprecated; renamed to `proxy.ts`; Proxy defaults to Node.js runtime (was Edge) |
| v15.5.0 | Proxy/Middleware Node.js runtime stable |
| v15.2.0 | Proxy/Middleware Node.js runtime experimental |
| v15.x | `fetch()` requests **not cached by default** (previous model changed from v14) |
| v15.x | `cacheComponents` flag introduced (enables `use cache` + PPR as default) |
| v13.4 | Server Actions (experimental) |
| v14.0 | Server Actions stable |

> Always check the `version` and `lastUpdated` fields in the Next.js docs frontmatter for the deployed version of the project you are working on. Caching semantics in particular differ significantly between v14 and v15+.

## Sibling Skills

- `react` — React fundamentals (hooks, context, Suspense) that underpin Server/Client Components
- `nodejs` — Node.js runtime, streams, and ecosystem (relevant for server-side code in Next.js routes)

_Independent educational content. Next.js is a trademark of Vercel, Inc. Not affiliated with or endorsed by Vercel._
