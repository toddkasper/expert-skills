# Apex Governor Limits & Bulkification — Sales Cloud Reference

> Load this file when writing or reviewing Apex triggers, Batch Apex, or callout logic. Moved from SKILL.md body to keep body ≤ ~4,500 words.

## The rule

**Bulkify everything. Never put SOQL or DML inside a `for` loop.** Query once into a `Map`, iterate in memory, collect into a `List`, DML once at the end.

## Limits per synchronous transaction `[volatile — verify live]`

| Limit | Value |
|---|---|
| SOQL queries | **100** |
| DML statements | **150** |
| Rows retrieved by SOQL | **50,000** |
| Rows processed per DML | **10,000** |
| Records per trigger invocation (batch) | **200** |
| CPU time (sync) | **10,000 ms** |
| Heap (sync) | **6 MB** |
| Callouts | **100** per transaction; **120 s** total callout time |
| Future methods | **50** per transaction |
| Async (Batch/Queueable) SOQL rows | **50,000**, CPU **60,000 ms**, heap **12 MB** |

## Decision criteria

- > 50,000 rows or > 10,000 DML rows in one go → **Batch Apex** (200-record chunks) or **Bulk API** for data loads, not a single trigger transaction.
- External HTTP calls → never inside a trigger's synchronous path if avoidable; use `@future(callout=true)` or Queueable so a slow endpoint doesn't blow the 120 s callout ceiling and roll back the user's save.

## Anti-patterns / red flags to catch in review

- Any `[SELECT ...]` or `insert`/`update`/`delete`/`upsert` inside a `for` loop body.
- Trigger logic that assumes `Trigger.new` has one record (it can have 200).
- Hard-coded record IDs.
- Recursion with no static guard (trigger re-firing itself).
- Truncation that silently loses data instead of validating upstream. A defensive truncate in Apex is at best a last-line fallback for legacy / direct-API records — it is never a substitute for validating field length at the application/integration boundary against the field's real max length.
