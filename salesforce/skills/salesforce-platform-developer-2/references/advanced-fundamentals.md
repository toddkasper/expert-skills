# Advanced Fundamentals — Deep Detail

Referenced from the main SKILL.md Advanced Fundamentals section. Load this file when choosing a configuration storage mechanism (CMT vs Custom Settings), implementing multi-currency logic, or designing an enterprise-layer architecture (fflib).

---

## Custom Metadata Types vs Custom Settings

- **CMT (`__mdt`):** deployable, packageable, SOQL-queryable **without consuming the SOQL governor limit** (cached). Use for configuration that ships with the app and needs version control or packaging.
- **Custom Settings — List type:** global constants accessible in-memory via `MySettings__c.getInstance()`, no SOQL cost, not packageable in the same way.
- **Custom Settings — Hierarchy type:** per-profile/per-user runtime toggles. `getInstance(userId)` walks the hierarchy (user → profile → org default). No SOQL cost.
- **Decision:** needs deployment/packaging/relationships between config records → CMT. Per-user/profile runtime toggle → Hierarchy Custom Setting.

## Multi-Currency

- `CurrencyIsoCode` field on records; `DatedConversionRate` for historical exchange rates.
- Guard currency-dependent logic with `UserInfo.isMultiCurrencyOrganization()`.
- Never hardcode conversion math — always use the platform's stored rates.

## Design Patterns

- **Singleton:** one instance per transaction (static variable holding the instance). Use for shared state (e.g. a cache of query results) that should not be re-queried within the same transaction.
- **Strategy:** swap algorithm at runtime via an interface. Use when the algorithm varies by record type, org config, or caller context without changing the calling code.
- **Decorator:** wrap an sObject in a domain class that adds behavior without subclassing.
- **Bulk State Transition:** use `Trigger.oldMap`/`newMap` to act only on records whose watched field actually changed — avoids re-processing unchanged records in bulk operations.
- **Facade:** simplify a complex subsystem behind a single class. Common in integration layers.
- **Enterprise Service / Selector / Domain layering (fflib):** Service = orchestration logic; Selector = SOQL encapsulation with FLS; Domain = trigger handler logic. Enforces separation of concerns at scale.
