# Service Cloud Consultant Decision Scenarios — Extended Set

> Overflow scenarios from SKILL.md. Load when working through Entitlement TargetDate Business Hours bugs or Web-to-Case spike capacity planning.

---

**Scenario 4 — Entitlement milestone inserted but TargetDate is wrong**

**Situation:** A "First Response" milestone is inserted on new cases, but its `TargetDate` is 24 hours from creation regardless of the account's VIP Business Hours (which should be 8 business hours). The org default Business Hours are 9–5, Mon–Fri.

**Competent move:** The Entitlement attached to the account is using org-default Business Hours instead of the VIP 24-hour Business Hours record. Open the Entitlement record and set the Business Hours field to the correct VIP record. The milestone clock respects the Business Hours on the Entitlement, not the org default. After the fix, create a test case and query `CaseMilestone.TargetDate` to confirm it reflects 8 VIP business hours.

**Tempting-but-wrong:** Editing the milestone target time directly on the Entitlement Process — that changes the duration for all Entitlements using this process, not just VIP accounts. Alternatively, changing the org default Business Hours — this impacts every SLA in the org, including non-VIP tiers.

**Verify:** Run `SELECT Id, TargetDate FROM CaseMilestone WHERE CaseId = '<test case id>'` (MCP / `sf data query` / Developer Console) and confirm `TargetDate` aligns with VIP Business Hours math. Cross-check the Entitlement record's `BusinessHoursId` field.

---

**Scenario 5 — Web-to-Case submission spike drops cases silently**

**Situation:** An organization runs an annual open-enrollment drive. Historically they receive 200 applications/day but expect 800–1,000 on peak days during the two-week window. They plan to use native Web-to-Case.

**Competent move:** Native Web-to-Case is hard-capped at 500 cases/day — submissions beyond that are silently dropped (no error to the submitter, no record in Salesforce). For peak volumes that exceed 500/day, replace or supplement the intake path: either a custom web form that POSTs to an Experience Cloud / Salesforce Site Apex REST endpoint (no 500-cap), or a queue-based async path (e.g. Platform Events / MuleSoft). Implement a server-side acknowledgment email from the intake endpoint so applicants have proof of submission regardless of path.

**Tempting-but-wrong:** Assuming the cap is a soft throttle that queues overflow for later processing — it is not; over-cap submissions are lost. Another trap: proposing an authenticated Experience Cloud portal to solve the cap — that solves the volume problem but adds login friction that is a real cost for a one-time, low-tech applicant population.

**Verify:** Load-test the custom intake path at 2× expected peak using a staging org or sandbox. Query `Case` count after the test to confirm all records landed. Monitor the sandbox error logs for any governor limit hits at the intake endpoint.
