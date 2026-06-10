# Application tasks — react (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

## Task 1 — Redline this component for effect, closure, and rendering flaws

**Prompt to the agent:** Review the following React component and produce a written redline identifying every hook, effect, closure, and rendering flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```tsx
import React, { useState, useEffect, useCallback } from 'react';

function UserList({ teamId }: { teamId: string }) {
  const [users, setUsers] = useState([]);
  const [filter, setFilter] = useState('');

  // Derived state: filter users when filter or users change
  const [filteredUsers, setFilteredUsers] = useState([]);
  useEffect(() => {
    setFilteredUsers(users.filter(u => u.name.includes(filter)));
  }, [users, filter]);

  useEffect(() => {
    fetch(`/api/teams/${teamId}/users`)
      .then(r => r.json())
      .then(data => setUsers(data));
  }, [teamId]);

  const handleSelect = useCallback((userId: string) => {
    console.log(`Selected ${userId} in team ${teamId}`);
  }, []);   // missing teamId dependency

  function UserCard({ user }: { user: any }) {
    return <div onClick={() => handleSelect(user.id)}>{user.name}</div>;
  }

  return (
    <div>
      <input value={filter} onChange={e => setFilter(e.target.value)} />
      {filteredUsers.map((u, i) => (
        <UserCard key={i} user={u} />
      ))}
    </div>
  );
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Derived state via `useEffect` + `useState` for `filteredUsers`: filtering is pure computation; maintaining a second state slice with an effect adds a render cycle and can cause tearing; fix is to compute `filteredUsers` directly during render (`const filteredUsers = users.filter(...)`).
- [ ] Trap 2 — Component defined inside another component (`UserCard` inside `UserList`): React creates a new component type on every render of `UserList`; this destroys and remounts `UserCard` on every render, losing any internal state and causing focus loss; fix is to hoist `UserCard` outside `UserList`.
- [ ] Trap 3 — `useCallback` with an empty dependency array but closes over `teamId`: the `handleSelect` callback captures the initial `teamId` and never updates; when `teamId` prop changes, `handleSelect` logs the stale value; fix is to include `teamId` in the dependency array.
- [ ] Trap 4 — `key={i}` (array index) on a filterable list: as `filter` changes the list contents, index keys cause React to reuse DOM nodes incorrectly; fix is `key={u.id}` using a stable identity.
- [ ] Trap 5 — `fetch` inside `useEffect` without a cleanup / AbortController: if `teamId` changes before the fetch resolves, the stale response still calls `setUsers`, potentially replacing fresh data; fix is an `AbortController` with cleanup.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Identifies derived-state-via-effect as an anti-pattern and names the extra render cycle / tearing risk; prescribes inline computation.
- Names "component defined inside a component" explicitly and explains the remount consequence (not just "performance issue").
- Identifies the stale closure in `useCallback` with the specific missing dependency (`teamId`).
- Explains why index keys fail specifically for filtered/reordered lists (not just "use stable keys").
- Shows the `AbortController` cleanup pattern for the fetch effect.
- Does not introduce new issues (e.g., does not suggest `useMemo` for the filter when a plain variable suffices).

---

## Task 2 — Redline this data-fetching and memoization component for common React traps

**Prompt to the agent:** Review the following React component and produce a written redline identifying every memoization, data-fetching, and hook-misuse flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```tsx
import React, { useState, useEffect, useMemo, useRef } from 'react';

type Config = { pageSize: number; sortField: string };

function ProductCatalog({ config }: { config: Config }) {
  const [page, setPage] = useState(1);
  const [products, setProducts] = useState<any[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);

  // Memoize the sort function
  const sortedProducts = useMemo(
    () => [...products].sort((a, b) => a[config.sortField] > b[config.sortField] ? 1 : -1),
    [products]   // config.sortField missing from deps
  );

  useEffect(() => {
    fetch(`/api/products?page=${page}&size=${config.pageSize}`)
      .then(r => r.json())
      .then(data => setProducts(data.items));
  }, [page]);   // config.pageSize missing from deps

  // Scroll to top on page change
  useEffect(() => {
    containerRef.current.scrollTo(0, 0);
  }, [page]);   // no null guard

  return (
    <div ref={containerRef}>
      {sortedProducts.map((p, index) => (
        <div key={index}>
          <strong>{p.name}</strong> — ${p.price}
        </div>
      ))}
      <button onClick={() => setPage(p => p + 1)}>Next</button>
    </div>
  );
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `useMemo` dependency array omits `config.sortField`: when `sortField` changes, `sortedProducts` is not recomputed and shows the wrong sort order silently; the linter exhaustive-deps rule catches this; fix is to add `config.sortField` (or the full `config`) to the deps array.
- [ ] Trap 2 — `useEffect` fetch omits `config.pageSize`: when the parent changes `pageSize`, the fetch does not re-run and stale page-size data is displayed; same fix — add `config.pageSize` to the effect deps.
- [ ] Trap 3 — `containerRef.current.scrollTo(0, 0)` without a null guard: on first render or if the element is conditionally unmounted, `containerRef.current` is `null`; calling `.scrollTo` throws a TypeError; fix is `containerRef.current?.scrollTo(0, 0)`.
- [ ] Trap 4 — `key={index}` on a paginated product list: when the page changes, products change but index 0 is reused; React does not remount the card, potentially showing stale state from the previous page's item; fix is `key={p.id}`.
- [ ] Trap 5 — `setProducts(data.items)` with no error handling or loading state: if the fetch fails (network error, non-2xx status), `data.items` is undefined and the UI silently renders an empty list with no user feedback; fix is a `try/catch` and loading/error state.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Calls out both missing dependency arrays (useMemo and useEffect) as separate, distinct bugs with separate consequences.
- Identifies the null-dereference on `containerRef.current` and prescribes optional chaining or an existence check.
- Explains the page-change / index-key collision for paginated lists specifically (not just generic "use stable keys").
- Flags missing error handling on the fetch and names the silent-empty-list failure mode.
- Does not introduce new issues such as unnecessary `useCallback` wrappers on non-passed callbacks or converting the `useRef` scroll to an effect with state.
