# Consulting Practices & Discovery — Sales Cloud Reference

> Load this file when running discovery or scoping a Sales Cloud implementation. Moved from SKILL.md §13 to keep body ≤ ~4,500 words.

## Rules

- Gather requirements as **business outcomes**, not features. Use a **fit/gap matrix**: standard (no build) → configuration → custom (Apex/integration). Tilt toward standard to reduce maintenance burden.
- Distinguish **current-state pain** from **future-state requirements** to prevent scope creep.
- **Phase 1 = core + adoption.** A lean launch with high adoption beats a full launch with low adoption. Training and enablement are deliverables, not afterthoughts.
- **Define success metrics up front** (pipeline coverage ratio, lead conversion rate, forecast accuracy) — no agreed metrics means no objective project completion criterion.

## Fit/gap matrix guidance

| Fit | What it means | Action |
|---|---|---|
| Standard fit | OOTB feature meets the requirement | Configure; no build |
| Config gap | Requirement addressable with declarative tools | Flow, validation rule, record type, sharing rule |
| Custom gap | Requires Apex, integration, or managed package | Estimate, scope, justify — last resort |

A requirement that lands in "Custom gap" should always be challenged with "can we accept a slightly different business process that fits Standard?" before committing to code.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
