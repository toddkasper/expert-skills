# Service Cloud Consultant Decision Scenarios — Extended Set

> Overflow scenarios from SKILL.md. Load when working through Entitlement TargetDate Business Hours bugs or Web-to-Case spike capacity planning.

---

**Scenario 4 — Entitlement milestone inserted but TargetDate is wrong**

**Situation:** A "First Response" milestone is inserted on new cases, but its `TargetDate` is 24 hours from creation regardless of the account's VIP Business Hours (which should be 8 business hours). The org default Business Hours are 9–5, Mon–Fri.

**Competent move:** The Entitlement attached to the account is using org-default Business Hours instead of the VIP 24-hour Business Hours record. Open the Entitlement record and set the Business Hours field to the correct VIP record. The milestone clock respects the Business Hours on the Entitlement, not the org default. After the fix, create a test case and query `CaseMilestone.TargetDate` to confirm it reflects 8 VIP business hours.

**Tempting-but-wrong:** Editing the milestone target time directly on the Entitlement Process — that changes the duration for all Entitlements using this process, not just VIP accounts. Alternatively, changing the org default Business Hours — this impacts every SLA in the org, including non-VIP tiers.

**Verify:** Run `SELECT Id, TargetDate FROM CaseMilestone WHERE CaseId = '<test case id>'` (MCP / `sf data query` / Developer Console) and confirm `TargetDate` aligns with VIP Business Hours math. Cross-check the Entitlement record's `BusinessHoursId` field.

---

**Scenario 5 — Web-to-Case submission spike risks delayed or lost cases**

**Situation:** An organization runs an annual open-enrollment drive. Historically they receive 200 applications/day but expect 800–1,000 on peak days during the two-week window. They plan to use native Web-to-Case.

**Competent move:** Native Web-to-Case is capped at 5,000 cases/24 hours `[volatile — verify live]`. At 800–1,000/day the org stays well under that cap, so the volume concern is not a blocking issue for native Web-to-Case. However, the correct recommendation still considers failure modes: if the org runs other intake flows (Web-to-Lead, batch imports) that could push the shared pending queue toward its 50,000-request combined limit, or if volumes could spike unexpectedly beyond 5,000/day, a custom REST endpoint removes the dependency entirely. Overflow beyond 5,000/24 h goes into a shared pending request queue (Web-to-Case + Web-to-Lead combined, 50k cap) and is processed after the next midnight UTC reset — it is NOT silently dropped unless the pending queue is also full. Implement a server-side acknowledgment email from the intake endpoint so applicants have proof of submission regardless of path.

**Tempting-but-wrong:** Assuming the cap is 500/day (that is the Web-to-Lead limit, not Web-to-Case). Also wrong: assuming overflow is silently lost — queued requests are held and processed after the limit resets, though the queue itself has a 50k cap beyond which requests are permanently lost. Another trap: proposing an authenticated Experience Cloud portal to solve a volume concern — that adds login friction that is a real cost for a one-time, low-tech applicant population.

**Verify:** Confirm the org's current Web-to-Case daily volume vs. the 5,000/24-h cap in Setup → Web-to-Case. If a custom endpoint is chosen, load-test it at 2× expected peak using a sandbox and query `Case` count to confirm all records landed.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
