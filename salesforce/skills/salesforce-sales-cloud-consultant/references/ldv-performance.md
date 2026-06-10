# Large Data Volume (LDV) & Performance — Sales Cloud Reference

> Load this file when designing for millions of records or diagnosing query timeouts. Moved from SKILL.md §7 to keep body ≤ ~4,500 words.

## Rules

- **Avoid data skew.**
  - *Ownership skew*: > ~10,000 records owned by one user slows sharing recalculation.
  - *Lookup skew*: > ~10,000 child records pointing at one parent causes record-lock contention on parallel loads.
- **Index your filters.** Selective SOQL (indexed field, < 10% of rows / < 300k rows returned) avoids full table scans. Standard indexed fields: Id, Name, External Id, lookups, audit fields. Custom: mark the field `External Id` or request a custom index from Salesforce Support.
- **Skinny tables** — Salesforce-support-managed tables that pre-join frequently queried fields. Useful for read-heavy reporting on millions of rows; must be requested via Support.
- **Big Objects** — for high-volume archival data (audit trails, activity history) that doesn't need to be in the main org schema. Query via SOQL with indexed fields only.
- **Defer sharing recalculation** during large bulk loads — enable "Defer Sharing Calculation" in Setup, run the load, then re-enable. Prevents row-level lock contention.
- **Archive cold data** — move records that will never be active again (old closed opportunities, archived cases) to Big Objects or an external data warehouse to keep the active dataset lean.

## Anti-pattern

Non-selective SOQL on a multi-million-row object (no indexed field in the WHERE clause) → query timeout / `QueryException`. Always add at least one indexed filter.
