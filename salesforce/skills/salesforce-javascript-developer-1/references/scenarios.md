# Additional Decision Scenarios

These scenarios overflow from SKILL.md to keep the main file under 500 lines. Format follows
POLICY.md: Situation → Competent move → Tempting-but-wrong → Verify.

---

### Scenario 3 — `fetch` silently swallowing a 500

**Situation:** A developer calls a Salesforce Connected App REST endpoint from a Node.js script:

```js
const res = await fetch(endpointUrl, { headers });
const data = await res.json();
console.log(data.records);
```

The script logs `undefined` and exits silently when the Connected App returns an HTTP 500 with a
JSON error body. No exception is ever raised.

**Competent move:** Add an explicit status check before calling `.json()`:

```js
const res = await fetch(endpointUrl, { headers });
if (!res.ok) {
  const errBody = await res.text();
  throw new Error(`HTTP ${res.status}: ${errBody}`);
}
const data = await res.json();
```

`fetch` only rejects its Promise on a network-level failure (DNS, TCP). A 4xx or 5xx response is
a *resolved* Promise with `ok: false`. Calling `.json()` on it silently parses the error body
(or throws an opaque parse error if the body isn't JSON), never surfacing the real status.

**Tempting-but-wrong:** Wrapping the whole block in `try/catch` and assuming any server error will
be caught there. A `try/catch` around `fetch` only catches network failures and JSON parse errors —
not HTTP error statuses. The error body detail disappears entirely.

**Verify:** In a Jest test, mock `fetch` to return `{ ok: false, status: 500, text: () =>
Promise.resolve('Internal Server Error') }` and confirm the function throws with the status code
in the message. In a live integration test, deliberately misconfigure the endpoint URL and confirm
the error path is exercised before shipping.

---

### Scenario 4 — Parallel vs. sequential Apex imperative calls

**Situation:** An LWC component needs three independent pieces of data on load: the current user's
profile, a list of open cases, and a set of account metadata records. A developer writes three
sequential `await` calls to imperative Apex methods in `connectedCallback`. The component loads
noticeably slowly. A teammate suggests using `@wire` for all three instead.

**Competent move:** Fan the three independent calls out with `Promise.all`:

```js
const [profile, cases, metadata] = await Promise.all([
  getProfile(),
  getOpenCases({ userId }),
  getAccountMetadata({ accountId }),
]);
```

Because the three queries are independent (none needs a result from another to form its query),
they can be inflight simultaneously. `Promise.all` waits for all three and returns their results
together, reducing wall-clock time from `sum(latencies)` to `max(latency)`.

**Tempting-but-wrong:** Switching to `@wire` for all three, assuming the framework will
automatically parallelize them. `@wire` is declarative and Salesforce does optimize wired calls,
but it is the wrong tool for calls that need results *before* rendering logic runs (e.g. to
combine/transform across all three). `@wire` provisions data reactively and asynchronously in a
way that makes coordinating three results in a single reactive update awkward. `Promise.all` is
the right explicit tool for "wait for all, then act once."

**Verify:** In the LWC jest test, mock all three Apex imports with `mockResolvedValue`, call the
load handler, and assert with `Promise.all` that all three mocks were called and the component
state reflects the combined result. Measure load time in a scratch org DevTools Network tab with
throttling enabled — sequential calls produce a visible waterfall; parallel calls collapse it.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
