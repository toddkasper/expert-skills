# Application tasks — salesforce-service-cloud-consultant (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Entitlement process and milestone design review

**Prompt to the agent:** A financial-services client is about to go live with a new SLA tier model in Service Cloud. Their solution architect has shared the entitlement configuration spec below. Review it, produce a redlined design document, and flag every trap before UAT starts Monday.

**Spec (flawed — embedded traps):**

> **SLA tiers:**
> - Tier 1 (Standard): First Response — 8 business hours; Resolution — 5 business days.
> - Tier 2 (Priority): First Response — 2 business hours; Resolution — 1 business day.
>
> **Business Hours:** Mon–Fri 9 AM–6 PM Eastern. Configured in Setup as a single Business Hours record named "Standard."
>
> **Milestone configuration:**
> - Both tiers share one Entitlement Process ("Global SLA Process"). Each tier's milestone criteria are distinguished by Case Priority field (Standard → Priority = "Medium"; Priority tier → Priority = "High").
> - The "First Response" milestone completion criterion is: agent changes Case Status from "New" to any other value.
> - Milestone "Time Trigger" for First Response is set to **0 minutes** from case creation (i.e., starts immediately).
>
> **On-Hold behavior:**
> - When a customer does not reply for 24 hours, agents set Status to "Waiting on Customer." The team expects the milestone clock to pause automatically when Status = "Waiting on Customer."
>
> **Escalation:**
> - An escalation action fires 30 minutes before the First Response `TargetDate` to notify the queue manager by email.
>
> **Entitlement assignment:**
> - A Flow sets the Entitlement on the Case record 5 minutes after case creation by querying the Account's active Entitlement via SOQL and updating the Case.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Clock does NOT pause automatically when Status changes to "Waiting on Customer." Milestone clocks pause only when an explicit **Milestone Action** of type "Stop" is configured on the Entitlement Process for that status transition, or when a stop criterion is met. The spec assumes automatic pausing; the agent must flag this and describe adding a Stop milestone action (or a criterion-based stop action) for the "Waiting on Customer" status.
- [ ] Trap 2 — `TargetDate` is calculated at the moment the Entitlement is stamped on the Case, not at case creation. Because the Flow stamps the Entitlement 5 minutes after creation, the First Response `TargetDate` will be 5 minutes later than expected for every case — a systematic SLA drift. Agent must flag the delay and recommend setting the Entitlement at case creation (e.g., in the Web-to-Case assignment, or a before-save Flow on insert).
- [ ] Trap 3 — One shared Entitlement Process with milestone criteria differentiated only by Case Priority is fragile: if Priority is blank or mis-set on intake, neither tier's milestone will fire correctly, and there is no fallback. The safer design is two separate Entitlement Processes (one per tier) mapped to distinct Entitlement records, so tier assignment is enforced at the Entitlement level, not inside a single process. Agent must call out the single-process risk and recommend the two-process pattern.
- [ ] Trap 4 — The escalation action fires 30 minutes before `TargetDate` but `TargetDate` is a business-hours datetime. The 30-minute pre-fire window is also a business-hours interval; if the case is created at 5:45 PM (15 minutes before close), the `TargetDate` falls the next morning but the 30-minute warning fires relative to that date and may coincide with non-business hours. Agent must note that escalation action timing respects Business Hours and should be tested at edge-of-day case creation.
- [ ] Trap 5 — Milestone completion criterion "Status changes from New to any other value" will complete the milestone even if the agent merely moves to "Waiting on Customer" — which is not a genuine first response. Agent must flag that the completion criterion should require a meaningful response action (e.g., a custom "Agent Responded" checkbox or Status = "In Progress" set by agent action, not by automation).
- [ ] No new errors introduced

**Reference — a competent artifact:**
- On-hold fix: add explicit Stop milestone action on "Waiting on Customer" status and a Resume action on customer reply; document that this is not automatic.
- Entitlement-stamp timing: move Entitlement lookup and stamp to a before-save Flow on Case insert (or Web-to-Case default), eliminating the 5-minute drift.
- Two-Entitlement-Process design: one process per tier assigned to tier-specific Entitlement records; Priority field becomes a routing field, not a milestone filter.
- Edge-of-day escalation note: test cases created in the last 30 business minutes of the day; verify escalation fires at next-day business open, not in dead overnight hours.
- Completion criterion tightening: use a custom checkbox `First_Response_Sent__c` set by a Flow triggered on agent-sent email action (or EmailMessage insert), not Status change.

---

## Task 2 — Knowledge base structure and agent search gap diagnosis

**Prompt to the agent:** A healthcare-adjacent software company is three weeks post-go-live on Service Cloud with Knowledge enabled. Agents complain that Knowledge search in the Service Console returns no results. The admin has shared their configuration notes below. Diagnose every gap and produce a remediation checklist the admin can execute today.

**Spec (flawed — embedded traps):**

> **Knowledge setup:**
> - Knowledge is enabled in Setup. One article record type: "Product FAQ." Data categories: one category group "Product Lines" with three categories: "Platform," "Analytics," "Mobile."
> - All 55 articles are in Published status and assigned to the "Platform" category.
> - **Channel visibility:** The article record type's channel settings show "Internal App" = unchecked, "Customer" = checked, "Partner" = checked.
> - **Agent search:** Agents use the Knowledge component in the Lightning Service Console. The Knowledge sidebar is added to the Case record page via App Builder.
> - **Permission:** The "Support Specialist" permission set includes "Knowledge User" = true. All agents are assigned this permission set.
> - **Data category visibility:** No Data Category Visibility rules have been configured — the admin left this blank because "the categories are simple."
>
> **Web-to-Case:**
> - The org also has Web-to-Case enabled. The daily submission limit is not monitored. The team expects up to 400 submissions per day from the new public form.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — "Internal App" channel is unchecked on the article record type. The Knowledge component in the Service Console searches the **Internal App** channel for agents; articles only marked for Customer/Partner channels are invisible to agents searching internally. Agent must flag the channel setting and instruct the admin to check "Internal App" on the Product FAQ record type.
- [ ] Trap 2 — Data Category Visibility is blank. When no visibility rules are configured, users with no explicit category access see **no articles** in category-enabled orgs unless the org default is set to "All Categories." Agent must explain that blank visibility = no access (not all access), and prescribe either assigning category visibility roles or temporarily setting the default visibility to "All" while proper role-based visibility is designed.
- [ ] Trap 3 — Web-to-Case daily limit is 5,000 submissions per 24 hours (org-wide). At 400/day the team is well under the limit today, but the agent should note this limit explicitly and recommend monitoring (via daily report or Flow-based counter) so the team knows before they approach capacity — especially since 400/day leaves headroom but product growth could hit the cap. Agent should state the 5,000 limit and the monitoring recommendation.
- [ ] Trap 4 — The Knowledge sidebar added via App Builder must also be **activated** (the page layout published) and the record page must be assigned to the correct App/Profile/Record Type combination. If the page was saved but not activated, or assigned only to the default app and agents use a custom app, the sidebar won't appear. Agent must call out the activation and app-assignment step as a gap to verify.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Channel fix: check "Internal App" on Product FAQ record type in Knowledge Settings; confirm change and republish affected articles if required.
- Data category visibility fix: assign the "Support Specialist" role (or all internal user roles) visibility to the "Product Lines" category group with all three subcategories; document the blank-default = no-access rule.
- Web-to-Case limit callout: state the 5,000/day cap; recommend a daily summary report with alert threshold at 4,000.
- Console page activation checklist: confirm App Builder page is activated for the Service Console app and the correct profile/record type assignment; provide the Setup path.
