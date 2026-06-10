# Application tasks — typescript (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

## Task 1 — Redline these types and declaration file for soundness flaws

**Prompt to the agent:** Review the following TypeScript module and its hand-authored `.d.ts` declaration file. Produce a written redline identifying every unsound type, lying declaration, unsafe cast, and structural flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```ts
// user-service.ts  (implementation)
export function getUser(id: number) {
  return fetch(`/api/users/${id}`).then(r => r.json());
}

export function findUsers(filter: object) {
  return fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify(filter),
  }).then(r => r.json());
}

export class IdBag {
  private ids: number[] = [];
  add(id: number) { this.ids.push(id); }
  // toArray was removed in v2 — intentionally deleted
}
```

```ts
// user-service.d.ts  (hand-authored declaration file)
export function getUser(id: number): Promise<any>;

export function findUsers<T>(filter: T): Promise<T[]>;

export class IdBag {
  add(id: number): void;
  toArray(): number[];          // declared but removed from implementation
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `toArray()` declared in `.d.ts` but absent from the implementation: a lying declaration; callers will type-check successfully but get a runtime `TypeError: idBag.toArray is not a function`; fix is to remove the declaration or restore the method.
- [ ] Trap 2 — `getUser` returns `Promise<any>`: the `any` return silently poisons every consumer's type safety; the declaration should return `Promise<User>` (or `Promise<unknown>`) and the caller must validate the shape at the boundary.
- [ ] Trap 3 — `findUsers<T>(filter: T): Promise<T[]>`: the unconstrained generic implies the response array elements have the same shape as the filter, which is structurally false; the generic T adds no safety and misleads callers into thinking the response is typed; fix is `findUsers(filter: Record<string, unknown>): Promise<unknown[]>` with runtime validation, or a well-constrained overload.
- [ ] Trap 4 — `filter: object` in the implementation is overly broad and blocks structural property access; `object` is not the same as `Record<string, unknown>` — callers can pass non-serializable values like class instances or functions; prescribe `Record<string, unknown>` or a named interface.
- [ ] Trap 5 — Both `getUser` and `findUsers` return `Promise<any>` / `Promise<T[]>` with no boundary validation: `JSON.parse` / `r.json()` returns `any`; a runtime `as SomeType` or unchecked generic cast at the network boundary is a soundness hole; fix is a Zod schema or manual type-guard at the parse site.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Identifies the lying `toArray()` declaration as the most severe flaw (causes runtime crash despite type-check passing) and prescribes removal.
- Flags `Promise<any>` as a type-system escape hatch, not just a style issue, and explains how it propagates unsoundness downstream.
- Explains why `findUsers<T>(filter: T): Promise<T[]>` is structurally dishonest (the type parameter flows in but has no relation to the response shape) and proposes a sound alternative.
- Distinguishes `object` vs `Record<string, unknown>` and explains the serialization risk.
- Recommends a validation boundary (Zod, `io-ts`, or a manual type guard) for all `.json()` / `JSON.parse` results.
- Does not introduce new `any` casts or phantom generics in the prescriptions.

---

## Task 2 — Redline this generic utility and branded-ID usage for structural and safety flaws

**Prompt to the agent:** Review the following TypeScript utility types and usage code. Produce a written redline identifying every unsound generic, structural subtype confusion, and missing boundary-validation flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```ts
// ids.ts
type UserId = number;
type OrderId = number;

function transferOrder(userId: UserId, orderId: OrderId): void {
  // ... implementation
}

// caller — somewhere in the codebase
const uid: UserId = 42;
const oid: OrderId = 99;
transferOrder(oid, uid);   // accidentally swapped — compiles fine


// utils.ts
function merge<T, U>(a: T, b: U): T & U {
  return { ...a, ...b } as T & U;
}

const result = merge({ role: 'admin' }, { role: 'viewer' });
// result.role is typed as string & string = string, but runtime value is 'viewer'


// api.ts
async function loadConfig(): Promise<Record<string, unknown>> {
  const raw = await fetch('/config').then(r => r.text());
  const parsed = JSON.parse(raw) as Record<string, unknown>;
  return parsed;
}

function getTimeout(cfg: Record<string, unknown>): number {
  return cfg['timeout'] as number;
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `UserId` and `OrderId` are both aliases for `number` (structural equivalence): TypeScript treats them as identical, so accidentally swapping them at a call site compiles silently; fix is nominal/branded types (`type UserId = number & { readonly _brand: 'UserId' }`).
- [ ] Trap 2 — `merge<T, U>` intersection cast `as T & U`: the spread `{...a, ...b}` silently discards `a`'s `role` when `b` has the same key; the returned type is `T & U` (compile-time) but the runtime value only has `b`'s version of conflicting keys — a type/runtime mismatch; the `as` cast hides this.
- [ ] Trap 3 — `cfg['timeout'] as number` is an unsafe cast over an `unknown`-typed value: if `timeout` is missing or is a string, the cast silently returns `undefined` typed as `number`, causing downstream arithmetic to produce `NaN` silently; fix is a type guard or Zod schema.
- [ ] Trap 4 — `JSON.parse(raw) as Record<string, unknown>`: the `as` cast does not validate the shape; if the server returns an array or a primitive, subsequent property accesses are unsafe; `unknown` is better than `any` but the cast still skips runtime validation; a schema parse should follow.
- [ ] Trap 5 — `merge`'s unconstrained `<T, U>` accepts non-object types (primitives, arrays) where spreading is either a no-op or produces unexpected results; constraining to `T extends object, U extends object` prevents the most egregious misuse.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Explains that type aliases over primitives are structurally equivalent in TypeScript, making accidental swaps invisible; prescribes branded/nominal types with the correct syntax.
- Names the specific `T & U` / spread-key-conflict as a type/runtime divergence (not merely a style issue) and explains why the intersection type is misleading.
- Distinguishes `as number` (unsafe, silences errors) from a type guard or schema parse (safe); prescribes a concrete fix (`typeof cfg['timeout'] === 'number'` guard or Zod).
- Acknowledges `unknown` is better than `any` but explains why the `as` cast still bypasses validation.
- Adds the `extends object` constraint on `merge` and explains what it prevents.
- Prescriptions introduce no new `as` casts, no `any`, and no phantom generics.
