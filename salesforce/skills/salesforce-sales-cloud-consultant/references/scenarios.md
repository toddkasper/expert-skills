# Decision Scenarios 4–5 — Sales Cloud Reference

> Scenarios 1–3 are in SKILL.md. Load this file for the forecasting/territory gotchas. Moved from SKILL.md body to keep body ≤ ~4,500 words.

---

**Scenario 4 — Forecast Category vs. Stage drift**

> **Situation:** Sales leadership complains that the Collaborative Forecast shows much higher revenue in "Commit" than deals actually close. A review of Opportunity Stages shows several Stage values (e.g., "Legal Review") map to the "Commit" Forecast Category despite being early-stage deals.
>
> **Competent move:** Audit and realign the Stage-to-ForecastCategory mapping in Setup → Opportunities → Fields → Stage → Stage Picklist Values. Remap "Legal Review" to "Best Case" or "Pipeline." Re-train reps that Forecast Category represents their confidence in closing, not just process position.
>
> **Tempting-but-wrong:** Adding more stages or building a complex Flow to auto-adjust Forecast Category at close. The root cause is misconfigured Stage metadata, not missing automation. Over-engineering the fix introduces new drift opportunities.
>
> **Verify:** Open a representative Opportunity in each Stage, hover the Forecast Category, and confirm it matches the intent. Pull a forecast report before and after the fix and compare "Commit" totals to actual prior-period close rates.

---

**Scenario 5 — Territory model activation**

> **Situation:** An administrator creates a new Enterprise Territory Management model with updated assignment rules, configures territories, and tests by manually checking Account assignments in the Draft model. She activates the model. Sales reps now report they can see Accounts that belong to other regions.
>
> **Competent move:** Review the territory assignment rules — specifically, look for overly broad criteria (e.g., a rule matching all Accounts with a non-null BillingCountry) that assign more records than intended. Correct the rules, run "Run Rules" on the model in Draft state, verify the assignment preview, then re-activate.
>
> **Tempting-but-wrong:** Changing the OWD to Private in a panic. OWD affects the sharing baseline for all access mechanisms; changing it to fix a territory rule misconfiguration can break other access paths (sharing rules, team access). Fix the territory rules, not the OWD.
>
> **Verify:** In ETM Setup, use the "Preview" feature before activating to see which Accounts each territory will claim. After fix, log in as a rep and confirm Account visibility matches their assigned territory only.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
