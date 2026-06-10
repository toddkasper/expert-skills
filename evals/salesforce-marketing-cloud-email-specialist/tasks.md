# Application tasks — salesforce-marketing-cloud-email-specialist (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Welcome journey design with re-entry and deliverability traps

**Prompt to the agent:** A nonprofit client is building a new-donor welcome journey in Journey Builder. Their digital team has drafted the journey configuration notes below. Review the spec, redline every error, and produce a corrected design document they can hand to their SFMC admin for implementation.

**Spec (flawed — embedded traps):**

> **Entry:**
> - Entry Source: Salesforce Data, synced from the CRM Contact object. Entry criteria: `Donor_Status__c = "New"`.
> - Re-entry setting: **Always re-enter.** The team says new donors should always get the welcome series even if they entered before.
>
> **Journey steps:**
> - Day 0: Welcome email (Email 1 — "Welcome to our mission").
> - Day 3: Impact story email (Email 2).
> - Day 7: First-ask email (Email 3 — soft donation ask).
> - No exit criteria configured. The journey has no end date.
>
> **Email content:**
> - All three emails are created in Content Builder and connected to the journey. The team updated Email 2's copy last week by editing it directly in Content Builder after the journey was activated. They confirmed the new copy appears in the Content Builder preview.
>
> **Sending domain and deliverability:**
> - The nonprofit recently acquired a new subdomain `mail.give-nonprofitname.org` for sending. SPF is configured. DKIM is not yet set up because "SPF alone is enough for most ISPs."
> - The first send using this new subdomain will go to 180,000 subscribers (the full active list) on launch day.
>
> **Suppression:**
> - Unsubscribe link is in the footer using the standard SFMC CloudPages unsubscribe method. The unsubscribe scope is set to **"Business Unit."** The nonprofit operates one business unit.
> - Contacts who have already donated again (i.e., converted from "New" to "Active") are not explicitly removed from the journey once they enter.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — "Always re-enter" with no exit criteria means a donor who converts and then makes another gift will re-enter the welcome series and receive the Day-0 welcome email again — a double-welcome problem. Agent must flag this and recommend either (a) re-entry set to "No re-entry" or (b) an exit criterion that removes contacts when `Donor_Status__c != "New"` (i.e., once they convert to Active).
- [ ] Trap 2 — Editing Email 2 directly in Content Builder after journey activation does NOT update the email inside the live journey. Journey Builder locks a snapshot of the email at activation; changes in Content Builder are not reflected until the journey is paused, the email is replaced or re-selected, and the journey is re-activated. Agent must flag this and prescribe the correct update path.
- [ ] Trap 3 — SPF alone is insufficient: most major ISPs (Gmail, Yahoo, Outlook) now require DKIM alignment (and increasingly DMARC) for deliverability and to avoid junking. Sending 180,000 messages from a brand-new subdomain with no DKIM record will result in high deferral/spam rates. Agent must flag missing DKIM and recommend setting up DKIM signing in SFMC (Private Domain setup) before any sends.
- [ ] Trap 4 — Sending the full 180,000-subscriber list on day one from a new subdomain with no IP warming schedule will trigger ISP throttling and deferrals (similar to IP warming, domain reputation also requires gradual ramp-up). Agent must flag the absence of a ramp schedule and provide a recommended IP/domain warming sequence (e.g., 5k → 20k → 50k → 100k → full list over 2–3 weeks).
- [ ] Trap 5 — Unsubscribe scope set to "Business Unit" means unsubscribes only suppress within this business unit. If the nonprofit ever adds a second business unit or uses All Subscribers list across BUs, unsubs will not propagate. Additionally, if the client is subject to Canadian CAN-SPAM-equivalent (CASL), a BU-scoped unsubscribe may not constitute valid global consent withdrawal. Agent must note the scope risk and recommend "All Subscribers" unsubscribe scope (or at minimum document the CASL gap if Canadian donors are on the list).
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Re-entry correction: set re-entry to "No re-entry" (or add exit criterion `Donor_Status__c = "Active"`); document the double-welcome scenario.
- Content-update path: pause journey → open journey → select updated email from Content Builder (ensure it is a new version or re-selected asset) → re-activate; note that active contacts in the journey receive whichever email version was live when they hit that step.
- DKIM setup: add Private Domain in SFMC Admin > Account Settings > Private Domains; publish DKIM TXT record to DNS; verify alignment before first send.
- IP/domain warming plan: table with weekly send volumes (5k, 20k, 50k, 100k, 180k) monitoring bounce rate (<2%) and complaint rate (<0.08%) as gates.
- Unsubscribe scope: change to "All Subscribers" scope; if multi-BU is in roadmap, also implement a global unsubscribe CloudPage.

---

## Task 2 — Automation Studio batch pipeline design and Data Extension audit

**Prompt to the agent:** A retail nonprofit is running a year-end appeal via Automation Studio. Their data team has shared the pipeline design below. Review it for errors, produce a corrected pipeline spec, and flag every trap that would cause the wrong audience to receive the appeal or suppress too many (or too few) records.

**Spec (flawed — embedded traps):**

> **Automation structure (single automation, all steps in Step 1):**
> 1. SQL Query activity — writes active donors to `YE_Appeal_Audience` DE.
> 2. SQL Query activity — writes lapsed donors to `YE_Lapsed_Audience` DE.
> 3. Send Email activity — sends "Year-End Appeal" email to `YE_Appeal_Audience`.
> 4. Send Email activity — sends "Lapsed Donor Re-engagement" email to `YE_Lapsed_Audience`.
>
> The team placed all four activities in a single Step (Step 1) to "keep it simple."
>
> **Audience source:**
> - `YE_Appeal_Audience` is a Data Extension with a `Subscriber Key` field.
> - The SQL query populates the DE using an `INSERT` (not `OVERWRITE`). The automation runs nightly for the 7-day appeal window.
>
> **Suppression:**
> - Donors who have already given during the appeal window should be suppressed. The team plans to add them to the Publication List named "YE_Appeal_Suppression."
> - In the Send Email activity, the suppression field is left blank (the team says "the Publication List handles it automatically").
>
> **List vs. Data Extension:**
> - The lapsed-donor query result was originally stored in a Salesforce Campaign (synced via MCC). The team switched to a DE last week but the Send Email activity for the lapsed email still points to the old Campaign / List source.
>
> **Re-engagement metric:**
> - The team defines "re-engaged" as any lapsed donor who opened the re-engagement email in the past 90 days (queried from `_Open` Data View). Any contact with an open event is removed from the lapsed segment.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — All four activities in a single Automation Studio Step execute in parallel, not sequentially. The SQL Query activities and the Send Email activities fire at the same time; emails will send before the SQL queries finish populating the DEs, resulting in sends against stale or empty target DEs. Agent must flag this and prescribe placing each SQL Query in its own step, followed by the Send Email in a subsequent step (Steps 1 → 2 → 3 → 4, or Steps 1+2 parallel → Step 3+4 after).
- [ ] Trap 2 — `INSERT` mode on a nightly-running query will append rows every run, creating duplicate subscriber records in `YE_Appeal_Audience` after the second run. By day 7, each subscriber could appear 7 times, causing 7 sends per contact. Agent must flag the INSERT mode and require `OVERWRITE` (or `UPDATE` with a deduplication approach) for a nightly refresh.
- [ ] Trap 3 — Publication List suppression does NOT work automatically in a Send Email activity targeted at a Data Extension. Publication Lists suppress when the send is targeted at a List; for DE-targeted sends, suppression must be configured via a Suppression List DE linked in the Send Email activity's suppression field, or via a `NOT EXISTS` clause in the SQL query. Agent must flag the blank suppression field and prescribe the correct DE-based suppression mechanism.
- [ ] Trap 4 — The lapsed-email Send Email activity still points to the old Campaign/List source, not the new `YE_Lapsed_Audience` DE. The recent DE switch was not applied to the Send definition. Agent must flag the stale send target and require the Send Email activity to be updated to reference `YE_Lapsed_Audience`.
- [ ] Trap 5 — Using `_Open` Data View opens as the "re-engaged" signal is unreliable because machine-opens (Apple Mail Privacy Protection, email security scanners) inflate open counts and cause actively unengaged contacts to be incorrectly retained in the lapsed segment. Agent must flag the open-metric problem and recommend a click-based or donation-based re-engagement signal instead.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Step sequencing: diagram with Step 1 (SQL Query 1 + SQL Query 2 in parallel), Step 2 (Send Email 1 + Send Email 2 in parallel, after Step 1 completes).
- INSERT → OVERWRITE: change both SQL Query activities to `OVERWRITE` mode on their target DEs to prevent duplication across nightly runs.
- DE suppression: create a `YE_Appeal_Suppression_DE` and add it as a Suppression Data Extension in each Send Email activity; document that Publication List suppression does not apply to DE-targeted sends.
- Send target correction: update the lapsed Send Email activity to target `YE_Lapsed_Audience` DE; confirm field mapping (Subscriber Key).
- Re-engagement signal: replace `_Open`-based filter with a click-based metric (`_Click` Data View) or a CRM-side donation event synced via MCC; document the Apple MPP false-positive risk.
