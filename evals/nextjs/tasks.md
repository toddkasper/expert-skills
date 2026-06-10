# Application tasks — nextjs (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

## Task 1 — Redline this App Router page for client/server boundary and secret-leakage flaws

**Prompt to the agent:** Review the following Next.js App Router page and produce a written redline identifying every client/server boundary violation, secret leakage, caching, and security flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```tsx
// app/dashboard/orders/page.tsx
'use client';

import { useState, useEffect } from 'react';

const API_SECRET = process.env.STRIPE_SECRET_KEY;

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    fetch('/api/orders', {
      headers: { Authorization: `Bearer ${API_SECRET}` },
    })
      .then(r => r.json())
      .then(setOrders);
  }, []);

  const cancelOrder = async (id: string) => {
    await fetch(`/api/orders/${id}/cancel`, { method: 'POST' });
    setOrders(prev => prev.filter(o => o.id !== id));
  };

  return (
    <ul>
      {orders.map(o => (
        <li key={o.id}>
          {o.reference} <button onClick={() => cancelOrder(o.id)}>Cancel</button>
        </li>
      ))}
    </ul>
  );
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `'use client'` on a data-fetching page: a page that only fetches data and renders a list should be a Server Component; marking it `'use client'` forces all data fetching to the browser, adding a waterfall, and exposes the fetch to client-side inspection; fix is to remove `'use client'` and use a Server Component with `async/await` fetch.
- [ ] Trap 2 — `process.env.STRIPE_SECRET_KEY` read in a Client Component: any `process.env` variable accessed in a `'use client'` file is inlined into the client bundle by the Next.js compiler; the Stripe secret key is exposed in the browser's JavaScript; fix is to move the secret read to a Server Component, Server Action, or Route Handler.
- [ ] Trap 3 — `fetch` inside `useEffect` with no cache or revalidation strategy: the client-side fetch has no caching layer; every navigation to the page re-fetches; if moved server-side, the `fetch` needs an explicit `{ cache: 'force-cache' }` or `revalidate` option (or `unstable_cache` wrapper) to avoid per-request waterfall.
- [ ] Trap 4 — Cancel mutation directly via `fetch` without a Server Action or cache invalidation: after canceling, `setOrders` optimistically removes the item client-side, but no server-side cache tag is invalidated; if the page is ever server-rendered with cached data, the order will reappear on next navigation; a Server Action with `revalidatePath` / `revalidateTag` is the correct pattern.
- [ ] Trap 5 — No loading or error state: `useEffect` + `fetch` has no error branch; if `/api/orders` returns a non-2xx, `r.json()` may throw or return an error shape and `setOrders` receives garbage, rendering silently broken UI; add error/loading states or use the Server Component approach which surfaces errors via `error.tsx`.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Identifies `'use client'` on a data-only page as the root structural mistake and prescribes converting to an async Server Component.
- Explicitly names the secret-leakage mechanism (Next.js inlines non-`NEXT_PUBLIC_` env vars accessed in client files) and prescribes server-side access.
- Distinguishes fetch caching on the server (where Next.js `fetch` extensions apply) from client-side fetch (where they don't).
- Recommends a Server Action with `revalidateTag` or `revalidatePath` for the cancel mutation, not an ad-hoc `fetch` + optimistic update.
- Notes missing error/loading states as a reliability concern secondary to the structural issues.
- Does not introduce a new secret leak in the prescription (e.g., does not suggest `NEXT_PUBLIC_STRIPE_SECRET_KEY`).

---

## Task 2 — Redline this Server Action and Route Handler for security and caching flaws

**Prompt to the agent:** Review the following Next.js Server Action and Route Handler and produce a written redline identifying every authentication, cache-invalidation, and data-handling flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```tsx
// app/profile/actions.ts
'use server';

import { db } from '@/lib/db';

export async function updateProfile(formData: FormData) {
  const name = formData.get('name') as string;
  const bio  = formData.get('bio')  as string;

  await db.users.update({
    where: { id: formData.get('userId') as string },
    data: { name, bio },
  });

  revalidatePath('/profile');
}
```

```tsx
// app/api/webhooks/stripe/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function POST(req: Request) {
  const event = await req.json();

  if (event.type === 'checkout.session.completed') {
    await db.orders.update({
      where: { id: event.data.object.metadata.orderId },
      data: { status: 'paid' },
    });
    revalidateTag('orders');
  }

  return NextResponse.json({ received: true });
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Server Action has no authentication check: `updateProfile` trusts `formData.get('userId')` from the client to identify which user to update; any authenticated (or even unauthenticated) client can forge a different `userId` and overwrite another user's profile; the action must read the session server-side (e.g., `auth()` or `getServerSession()`) and update only the current user's record.
- [ ] Trap 2 — `revalidateTag('orders')` called from a Route Handler does nothing in production: `revalidateTag` and `revalidatePath` are only effective when called from Server Components, Server Actions, or Route Handlers that run within the Next.js rendering pipeline with on-demand ISR enabled; in a standalone Route Handler that is not part of a page render, these calls silently no-op in most deployment configurations; the correct approach for webhook-triggered cache busting is `revalidateTag` inside a Server Action invoked from the webhook, or ensuring the Route Handler is in a deployment context where on-demand revalidation is supported.
- [ ] Trap 3 — Stripe webhook has no signature verification: the handler processes any POST to the endpoint as a legitimate Stripe event; an attacker can forge events (e.g., fake `checkout.session.completed`) to mark orders as paid without actual payment; fix is `stripe.webhooks.constructEvent(rawBody, sig, secret)` before processing.
- [ ] Trap 4 — `revalidatePath('/profile')` in the Server Action revalidates the whole profile path but does not account for the cached user query: if the profile data is fetched with a tagged cache (`unstable_cache` with `tags: ['user']`), `revalidatePath` alone may not bust the per-user cache entry; `revalidateTag('user')` or a user-specific tag is more precise.
- [ ] Trap 5 — `req.json()` in the webhook handler consumes the raw body stream: Stripe signature verification requires the **raw** bytes of the request body; after `req.json()` is called, the raw body is gone; the signature check must use `await req.text()` (or `req.arrayBuffer()`) before parsing, not `req.json()`.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Identifies the IDOR/missing auth check in the Server Action as the most critical flaw and prescribes server-side session read.
- Explains why `revalidateTag` is silent in Route Handlers in certain deployment contexts (not just "move it somewhere else").
- Names Stripe webhook signature verification specifically and shows the `constructEvent` pattern.
- Distinguishes `revalidatePath` (page-level) from `revalidateTag` (data-level) and explains when each is needed.
- Calls out the raw-body consumption issue with `req.json()` and prescribes `req.text()` before signature check.
- Does not introduce a new security hole in prescriptions (e.g., does not suggest storing the Stripe secret in a `NEXT_PUBLIC_` variable).
