---
name: salesforce-marketing-cloud-email-specialist
description: Building Salesforce Marketing Cloud (SFMC) email campaigns, journeys, and automation — Journey Builder welcome/nurture flows, Automation Studio batch pipelines, Content Builder, AMPscript personalization, data extensions and SQL Data Views, Triggered/Single/User-Initiated sends, deliverability (SPF/DKIM/DMARC, IP warming, bounce handling), Marketing Cloud Connect to CRM, and inbox analytics. Use when designing or reviewing SFMC email, journeys, segmentation, or deliverability. This is SFMC (Studio/Builder stack) — not core CRM email or Pardot/Account Engagement. Scoped and benchmarked by the Marketing Cloud Email Specialist (MC-202) blueprint.
metadata:
  credential: Salesforce Certified Marketing Cloud Email Specialist
  exam-code: MC-202
  domain: salesforce
  type: certification-playbook
---

# Salesforce Marketing Cloud Email Specialist — Skills Reference

## Overview

The **Salesforce Certified Marketing Cloud Email Specialist** (exam code **MC-202**) validates
proven knowledge, skills, and hands-on experience in email marketing best practices within the
Salesforce Marketing Cloud (SFMC) platform. It covers message design, subscriber and data
management, marketing automation, deliverability, and inbox analytics.

This is the primary entry-level certification in the Marketing Cloud track. It is a prerequisite
for advanced credentials such as Marketing Cloud Consultant, Marketing Cloud Developer, and
Marketing Cloud Account Engagement Specialist. Salesforce recommends 6–12 months of hands-on
Marketing Cloud experience before attempting.

**When to reach for Marketing Cloud:** SFMC is the platform for *marketing* sends — donor appeals,
program updates, recruitment — with engagement tracking, unsubscribe management, and journey
automation. *Transactional* 1:1 mail (submit confirmations, password resets, magic-link delivery)
is often better served by a cheaper transactional email service (e.g. Amazon SES) unless a
Triggered Send is already justified by the broader MC adoption. The rules below let an agent make
the transactional-vs-marketing call, design a compliant journey, and avoid the deliverability and
data-model traps that bite teams integrating MC with a CRM.

**This file is an operational playbook, not an exam outline.** Each section states the actual rules
an agent must apply, the concrete limits, the decision criteria for picking a tool, and the
anti-patterns to catch in review.

> **Deeper context:** Study resources (official Salesforce + community) and the NPSP/nonprofit
> relevance notes live in [references/study-resources.md](references/study-resources.md)
> (loaded on demand). For org-specific applications of these rules, keep a per-org appendix in
> your own project, referenced from a CLAUDE.md.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## 1. Email Marketing Best Practices — Operational Rules

### Compliance is non-negotiable; build it into every send

- **Every commercial email MUST carry a physical postal address and a working one-click
  unsubscribe.** CAN-SPAM requires this; omitting it is a per-message violation (up to ~$53,088 per
  email in U.S. penalties). In SFMC this lives in the email footer / Delivery Profile, not the body —
  set it at the Delivery Profile so it can't be forgotten per-send.
- **Honor unsubscribes within 10 business days** (CAN-SPAM). SFMC suppresses immediately, so never
  re-add an unsubscribed address via a fresh import — that re-subscribes them and is a violation.
- **Decision — which consent model:**

  | Audience / law | Required consent | Action |
  |---|---|---|
  | U.S. marketing (CAN-SPAM) | Implied OK; opt-out must work | Single opt-in acceptable; footer unsubscribe mandatory |
  | Canada (CASL) | **Express opt-in** required | Capture explicit consent + date/source; no purchased lists |
  | EU/UK (GDPR) | Lawful basis (usually consent) | Double opt-in; honor right-to-erasure; store consent proof |
  | New / risky list, deliverability-sensitive | — | Use **double opt-in (DOI)** regardless of law |

- **RED FLAG:** any plan to send to a *purchased or rented list*. Stop. It tanks sender reputation,
  hits spam traps, and violates CASL/GDPR. Build lists with Web Collect / Smart Capture / DOI only.

### Deliverability — protect the sending domain

- **Authenticate the sending domain with all three: SPF, DKIM, DMARC.** Missing DKIM/DMARC is the
  most common cause of Gmail/Yahoo bulk-sender rejection (both enforce SPF+DKIM+DMARC for senders
  >5,000/day since Feb 2024). Verify DNS before the first send, not after bounces appear.
- **Warm a new dedicated IP over ~30 days**, ramping volume gradually (e.g. day 1: ~50/send, doubling
  every few days). Blasting full volume on a cold IP gets you throttled or blocklisted.
- **Bounce handling — know the status transition:**

  | Bounce type | Cause | SFMC subscriber status result |
  |---|---|---|
  | **Hard bounce** | Permanent — invalid/nonexistent address | → **Bounced** (auto-suppressed) |
  | **Soft bounce** | Temporary — full mailbox, server timeout, message too large | retried; repeated soft → **Held** |
  | Spam complaint | Recipient hit "report spam" | → **Unsubscribed** |

- **Keep spam-complaint rate < 0.1% and hard-bounce rate low** — Gmail enforces a 0.3% complaint
  threshold. Use **List Detective** to screen imports for role addresses (`info@`, `sales@`) and known
  spam-trap patterns before they enter a send.
- **RED FLAG in review:** sending to a list/DE that hasn't been mailed in 6–12+ months with no
  re-permission step → high bounce + complaint risk. Re-engage or suppress stale addresses first.

### Email design

- Mobile-first: design fluid/responsive with `@media` queries; ~half of opens are mobile. Use large
  tap targets, big fonts, and single-column layouts — especially for older audiences.
- Subject line + preheader are the open-rate levers. Avoid spam-trigger words, ALL CAPS, excessive `!`.
- A/B test ONE variable at a time (subject OR from-name OR send-time), define the winner metric up
  front (open vs. click vs. conversion), and use a large enough test cell to be significant.

---

## 2. Content Creation & Delivery — Operational Rules

### Use Content Builder; treat Classic as legacy

- **Build all new content in Content Builder, not Classic Email Studio.** Content Builder is the
  modern cross-channel CMS (blocks, templates, shared folders). Classic is legacy — only touch it for
  existing assets you must maintain.
- Build reusable **content blocks** (image/text/button/free-form HTML) and **templates** to enforce
  brand consistency. A template change propagates; copy-pasted HTML does not — prefer templates.

### Personalization — pick the right tool

| Need | Use | Notes |
|---|---|---|
| Simple field merge (`First Name`) | **Personalization String** `%%FirstName%%` | Pulls from subscriber attribute / DE field |
| Conditional content, cross-DE lookups | **AMPscript** | `Lookup()`, `IF/THEN`, runs at send time |
| Repeatable row/loop content (e.g. donation list) | **GTL** (Guide Template Language) | Cleaner than AMPscript loops |
| Heavy integration / API calls in-email | **SSJS** | Last resort; slower, harder to debug |
| AI optimization | **Einstein** | See decision table below |

- **Always provide a default/fallback** for personalization strings. `Dear %%FirstName%%,` with a null
  field renders `Dear ,`. Use `IIF(empty(@FirstName), "Friend", @FirstName)` style fallbacks.
- **Einstein feature decision:**

  | Goal | Feature |
  |---|---|
  | Send each contact at their best individual time | Einstein **Send Time Optimization (ESTO)** |
  | Score who's likely to open/click/unsubscribe | Einstein **Engagement Scoring** |
  | Get subject-line copy suggestions | Einstein **Copy Insights** |

### Send configuration — three send types, know which one

| Send type | Trigger | Use when |
|---|---|---|
| **User-Initiated Send** | Manual / scheduled by a user | One-off or scheduled batch campaign (annual appeal) |
| **Triggered Send** | Real-time API/event call | Transactional 1:1 (confirmation, password reset, magic-link/upload email) |
| **Automated Send** | Automation Studio step | Recurring batch on a schedule (weekly digest) |

- **Sender Profile** = From Name / From Address / Reply-To. **Delivery Profile** = header/footer,
  private domain, IP assignment. **Send Classification** = the binding of a Sender + Delivery Profile
  to a CAN-SPAM publication list. Configure the Send Classification once; reuse it so every send
  inherits the compliant footer and correct IP.
- **Always validate before send:** Test Send + Subscriber Preview (render against a real subscriber
  record) + a rendering check (Litmus/Validate). Catch broken personalization and mobile breakage here.
- **RED FLAG:** sending to a list without a Suppression List applied → you may mail unsubscribed or
  bounced addresses. Confirm publication + suppression lists are both wired in the send pipeline.

### Triggered Sends

- A **Triggered Send Definition (TSD)** must be *started/active* to fire. Pausing queues messages;
  republishing is required after editing the email. **RED FLAG:** "the confirmation email stopped
  going out" → first check the TSD is in *Active*, not *Paused*, and was republished after the last edit.

---

## 3. Marketing Automation — Operational Rules

### Journey Builder vs. Automation Studio — the core decision

| Criterion | Journey Builder | Automation Studio |
|---|---|---|
| Pattern | 1:1, contact-centric, real-time orchestration | Batch, data-centric, scheduled processing |
| Best for | Donor welcome series, lapsed-donor nurture, event drip | Nightly data import, SQL segmentation, file transfer/extract |
| Multi-step waits & branching | Yes (Decision/Engagement/Random splits, Wait) | Limited (sequential steps) |
| Entry | Entry Source (DE, Salesforce Data, API, CloudPage…) | Schedule (cron-like) or File Drop (SFTP) |
| Decision rule | "react to each contact as they qualify" → JB | "process a batch on a cadence" → AS |

### Journey Builder

- **Choose the right re-entry mode — it changes who gets re-messaged:**

  | Mode | Behavior |
  |---|---|
  | **No Re-entry** | Contact can be in the journey only once, ever |
  | **Re-entry Any Time** | Contact can be in multiple instances simultaneously |
  | **Re-entry Only After Exiting** | Must finish/exit before qualifying again |

  Welcome series → usually **No Re-entry** (don't welcome a donor twice). Recurring reminder →
  **Re-entry Only After Exiting**.
- **Decision Split** branches on a contact *attribute*; **Engagement Split** branches on *opened/clicked*
  a prior journey email. Use Engagement Split to send a follow-up only to non-openers.
- Set a **Goal** to measure conversion and (optionally) auto-remove contacts who convert. Set **Exit
  Criteria** to pull contacts out when they no longer qualify (e.g. donor unsubscribed).
- **Path Optimizer** tests up to **10** path variants and auto-promotes the winner.
- **Versioning trap:** editing a *running* journey requires a **new version**; in-flight contacts stay
  on the old version until they exit. Stopping a journey ejects in-flight contacts. **RED FLAG:**
  "I changed the email but contacts still get the old one" → they're on the prior published version.

### Automation Studio

- Build automations from these activities: **SQL Query** (run SQL against DEs/Data Views → target DE),
  **Import File** (SFTP CSV → DE), **Data Extract** (export tracking → SFTP file), **File Transfer**
  (move/decrypt SFTP files), **Filter** (Data Filter → Filtered DE), **Send Email**, **Wait**.
- **Execution order:** activities placed in the *same step* run **in parallel**; **steps** run
  **sequentially**. So put dependent work (Import → SQL → Send) in *separate steps* in order, never
  side-by-side. **RED FLAG:** an Import and the SQL that reads it sitting in the same step → race
  condition; the SQL may run against stale data.
- The typical segment-send chain: **SQL Query** (build the audience DE) → **Send Email** (to that DE),
  often preceded by **Import File** (load fresh CRM/SFTP data) and an opening **Wait** for timing.

---

## 4. Subscriber & Data Management — Operational Rules

### Data Extensions over Lists (almost always)

- **Default to Data Extensions, not Subscriber Lists.** Lists are the older, flat, attribute-limited
  model; DEs are relational, column-defined, scalable, and required for sendable segmentation and SQL.
  Use a List only for simple publication/subscription grouping.
- **DE types:**

  | Type | What it is | Use when |
  |---|---|---|
  | **Standard** | Manually defined schema | Most cases — your own data structure |
  | **Filtered** | Subset of a parent DE via a Data Filter | Reusable segment that auto-refreshes from parent |
  | **Random** | Random sample of a parent DE | A/B holdouts, statistical sampling |

- **Design the schema deliberately:** pick correct data types (Text, Number, Decimal, Date, Boolean,
  EmailAddress, Phone, Locale), set a **Primary Key** (prevents duplicate rows on Add/Update), and mark
  nullable fields. A **Sendable DE** must have a field relating it to the Subscriber Key.
- **Subscriber Key** = the unique subscriber identifier across all business units. Decide it once
  (often the CRM Contact ID via MCC) and never change it — it's the spine of all tracking.
- **Mirror source field lengths when designing DE column widths.** When syncing CRM fields into a DE,
  size the DE column to match the source field length so imports don't silently truncate.

### Subscriber status lifecycle — and unsubscribe scope

- Four statuses: **Active**, **Bounced** (hard bounce), **Held** (undeliverable after repeated soft
  bounces), **Unsubscribed**.
- **Unsubscribe scope — one wrong word changes blast radius:**

  | Scope | Effect |
  |---|---|
  | **List Unsubscribe** | Off one specific list/publication only |
  | **Global Unsubscribe** | Off *all* lists in the **business unit** |
  | **Master Unsubscribe** | Off **everything across the entire MC account** (all BUs) |

  **RED FLAG:** processing a one-list opt-out as a Master Unsubscribe → you silently kill that
  contact's eligibility for every future send org-wide.

### Profile & preference management

- **Profile Attributes** = identity fields. **Preference Attributes** = opt-in/opt-out toggles by
  category (e.g. "Donor appeals" vs. "Volunteer updates"). Give people granular preferences via the
  **Subscription Center** so they downgrade instead of fully unsubscribing.
- Capture/update subscribers with **Web Collect** (forms posting to MC) or **Smart Capture** (forms on
  CloudPages). For consent-sensitive lists, gate activation behind **Double Opt-In**.

### Data import — pick the update mode

| Mode | Effect | Use when |
|---|---|---|
| **Add/Update** | Insert new, update existing (matched on PK) | Default for ongoing syncs |
| **Add Only** | Insert new, skip existing | Append-only feeds |
| **Update Only** | Update existing, skip new | Enriching known records |
| **Overwrite** | **Truncate the DE, then load** | Full nightly snapshot replacement — destructive |
| **Delete** | Remove matching rows | Targeted removal |

- **RED FLAG:** using **Overwrite** on a DE that another process appends to → you wipe their data
  every run. Overwrite is for full-snapshot DEs only.

### Segmentation — Data Filters vs. SQL

- **Data Filter** for simple AND/OR on attributes (drag-and-drop, produces a Filtered DE).
- **SQL Query Activity** for anything relational, aggregated, or cross-Data-View (e.g. "subscribers
  with no `_Click` in 90 days"). SQL writes to a *target DE*; it cannot send directly.
- **Key queryable Data Views (read-only system tables):** `_Sent`, `_Open`, `_Click`, `_Bounce`,
  `_Unsubscribe`, `_Complaint`, `_Job`, `_Subscriber`, `_ListSubscribers`. Data Views retain ~6 months
  of data by default — for longer history, extract to a DE on a schedule.

### Marketing Cloud Connect (MCC) — the CRM bridge

- MCC is the integration layer between SFMC and Salesforce CRM. Two modes: **Synchronized Data Sources**
  (replicate CRM objects into MC as Synchronized DEs for segmentation) and **Salesforce Send** (send
  tied to a CRM Campaign, tracking flows back to the Contact/Lead activity timeline).
- MCC uses tenant-specific endpoints + an integration user with API access. **Verify the CRM objects
  you intend to segment on are actually synced** before building a journey on them.
- **Verify field-level security for the MCC integration user.** A field can be synced but unreadable —
  if FLS isn't granted to the integration user, the synced field returns blank or "Invalid field."
  Confirm read access for every field you intend to segment on.
- **Exposing a custom object to MC** is possible via the connected/external client app, but the app's
  permission assignment and consumer-key retrieval often have org-specific friction — verify the
  integration user can actually query the object before designing segments on it.

---

## 5. Insights & Analytics — Operational Rules

### Know the metric definitions cold

- **Delivered** = Sent − Hard Bounces
- **Open Rate** = Unique Opens / Delivered
- **Click-to-Open Rate (CTOR)** = Unique Clicks / Unique Opens (the truest engagement signal)
- **Click Rate** = Unique Clicks / Delivered
- **Bounce Rate** = Total Bounces / Sent
- **Unsubscribe Rate** = Unsubscribes / Delivered
- **Spam Complaint Rate** = Complaints / Delivered (keep < 0.1%)
- **Measures** are numeric/aggregated (total unsubs/30d); **Dimensions** are categorical (domain, date,
  region). Reports cross a Measure with a Dimension.
- **Open tracking is pixel-based** → inflated/unreliable since Apple Mail Privacy Protection pre-fetches
  pixels. **Lean on clicks/CTOR, not opens**, for true engagement and re-engagement suppression decisions.

### Reports — which one answers which question

| Question | Report |
|---|---|
| How did all sends perform this month? | Account Send Summary |
| How did one campaign do? | Campaign Email Tracking |
| Is Gmail throttling us vs. Yahoo? | Email Performance by Domain |
| Are we trending up or down? | Email Performance Over Time |
| What did this one person do? | Subscriber Engagement |
| Why are bounces up? | Bounce Summary |
| Are we getting spam complaints? | Spam Complaint Report |

- For raw event-level analysis, use **Tracking Extracts** (Automation Studio → SFTP) or **SQL Query**
  against Data Views into a DE. To re-engage, query `_Click` for no activity in N days → suppression DE.

---

## Operational Rules Quick Reference

- **DO** put a physical postal address + working unsubscribe in every commercial email (set at the
  Delivery Profile / Send Classification, not per-send).
- **DO** authenticate the sending domain with SPF + DKIM + DMARC before the first send.
- **DO** warm a new dedicated IP over ~30 days with a gradual volume ramp.
- **DO** default to **Data Extensions** over Subscriber Lists; set a Primary Key to avoid dupes.
- **DO** use **Triggered Sends** for 1:1 transactional, **Journey Builder** for 1:1 real-time
  orchestration, **Automation Studio** for scheduled batch.
- **DO** apply a Suppression List to every send and validate with Test Send + Subscriber Preview first.
- **DO** provide a fallback for every personalization string (no `Dear ,`).
- **DO** put dependent automation activities in *separate sequential steps* (same-step = parallel).
- **DO** lean on **clicks/CTOR** over open rate (pixel opens are unreliable post-MPP).
- **DO** verify CRM objects are actually synced — and FLS-readable to the integration user — via MCC
  before building journeys on them.
- **DON'T** ever mail a purchased or rented list — reputation, spam traps, CASL/GDPR violation.
- **DON'T** re-import an unsubscribed/bounced address — it silently re-subscribes them (violation).
- **DON'T** confuse unsubscribe scope: List ≠ Global (whole BU) ≠ Master (whole account).
- **DON'T** use **Overwrite** import on a DE that another process appends to — it truncates first.
- **DON'T** edit a running Journey and expect in-flight contacts to switch — publish a new version.
- **DON'T** trust open rate alone for re-engagement/suppression decisions (Apple MPP inflates it).
- **DON'T** leave a Triggered Send Definition Paused or un-republished after an email edit, then wonder
  why nothing sends.
- **DON'T** put an Import and the SQL that reads it in the same automation step (race condition).
- **DON'T** treat soft and hard bounces alike: hard → Bounced/suppressed; repeated soft → Held.

> For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

---

## 6. Coverage Additions

Extended rules for Content Builder slot-based templates, Automation Studio File Drop / Run Once,
AMPscript `Lookup()` empty-return, Marketing Cloud Intelligence (Datorama), and publication vs.
suppression list wiring: [references/coverage-additions.md](references/coverage-additions.md).

---

## Decision Scenarios

### Scenario 1 — Automation step ordering

**Situation:** A nightly automation imports a fresh CSV from SFTP into a Contacts DE, then runs a SQL
query that joins that DE with `_Click` to build today's re-engagement audience. A developer places
both activities side-by-side in Step 1 to "save time."

**Competent move:** Separate the Import and the SQL into sequential steps — Import in Step 1, SQL in
Step 2. Activities in the same step run in parallel, so the SQL executes concurrently with the import
and reads stale or partially loaded data. Moving them to separate steps guarantees the import commits
before the SQL starts.

**Tempting-but-wrong:** Assuming SFMC runs activities left-to-right within a step. It does not; same-
step activities are parallel by design. Adding a Wait activity inside the same step does not fix it —
Wait is a step-level construct, not an intra-step sequencer.

**Verify:** In Automation Studio, open the automation and confirm the Import activity and SQL Query
activity are in *different numbered steps*, with the Import step preceding the SQL step. Check the
Activity History after a run — both activities show a start timestamp; if they match to the second,
they ran concurrently.

---

### Scenario 2 — Unsubscribe scope error

**Situation:** A subscriber replies "remove me from your volunteer list." A support agent opens SFMC
and clicks the subscriber record's global "Unsubscribe" button to process the request quickly.

**Competent move:** Use a **List Unsubscribe** scoped to the volunteer publication list only, not the
global action. The global unsubscribe removes the contact from every send in the entire business unit —
they will also stop receiving donation receipts, event confirmations, and any other publication.
Instead, navigate to the subscriber's list subscriptions, find the volunteer list, and change their
status on that list to Unsubscribed.

**Tempting-but-wrong:** Using the "Unsubscribe" button on the subscriber profile page, which applies a
Global Unsubscribe at the BU level. It looks like the right action — it's prominently placed and the
label says "Unsubscribe" — but it silently kills delivery eligibility across all programs.

**Verify:** After processing, check the subscriber's **Subscription Summary**: they should show
*Unsubscribed* on the volunteer list and *Active* on all other publication lists. If they appear
globally unsubscribed, reverse by setting their All Subscribers status back to Active and reprocessing
as a list-scoped opt-out.

---

### Scenario 3 — Journey re-entry mode for a recurring reminder

**Situation:** A nonprofit sends a recurring "membership renewal reminder" journey. Contacts who
renewed last year should re-enter the journey again when their next renewal window opens.

**Competent move:** Set re-entry mode to **Re-entry Only After Exiting**. This lets a contact re-enter
after they have fully exited the journey (renewal cycle completed), while preventing them from being
in two concurrent instances of the same journey. Configure an Exit Criteria tied to "membership
renewed = true" so contacts leave as soon as they act, not after sitting through all wait steps.

**Tempting-but-wrong:** Setting **Re-entry Any Time**, which allows a contact to be in multiple
simultaneous instances. In a renewal journey, that means a contact who qualifies for two consecutive
cycles could receive two parallel sequences of renewal emails — duplicate messaging that damages trust.
Alternatively, leaving it as **No Re-entry** means a contact who renewed last year never receives
another renewal journey, which defeats the recurring purpose.

**Verify:** In Journey Builder, open the Journey Settings panel and confirm the re-entry mode. After
a contact exits and re-qualifies, check Journey History to confirm a new entry record was created
for that contact (distinct journey entry ID) in the new cycle.

---

### Scenario 4 — Triggered Send Definition left paused after edit

**Situation:** A developer updates the copy in a transactional order-confirmation email (fixing a typo
in the footer). They save the email in Content Builder and mark the ticket done. The next day, the
support team reports no confirmation emails have gone out since the edit.

**Competent move:** After editing any email used by a Triggered Send Definition, the TSD must be
**stopped, then republished (restarted)** to pick up the new email version. The TSD holds a reference
to the published email at the time it was last started. Editing the email in Content Builder does not
automatically propagate into an active TSD. The developer should have stopped the TSD, confirmed the
updated email is associated, then restarted it.

**Tempting-but-wrong:** Assuming that saving the email in Content Builder automatically updates the
live TSD. It does not. The TSD keeps sending the pre-edit version of the email until it is republished.
Some developers also try pausing (not stopping) the TSD — messages queue during pause and flush when
resumed, but the email version is still not refreshed until a full stop-and-restart cycle.

**Verify:** In Email Studio → Triggered Sends, open the TSD and confirm its status is *Active* and the
associated email reflects the current version. Send a test trigger via the API or a test script and
confirm the received email contains the updated copy.

---

### Scenario 5 — AMPscript Lookup() returning blank without error

**Situation:** A welcome email uses AMPscript to look up a "gift tier" label from a reference DE
(`GiftTiers`) based on the subscriber's most recent gift amount. Some recipients receive an email
where the gift tier line is completely blank, but no error bounce or send failure is logged.

**Competent move:** `Lookup()` returns an empty string when the lookup key finds no matching row — it
does not halt rendering or produce an error. Add an `IF Empty()` guard: if the lookup returns empty,
render a safe fallback string (e.g. "supporter") instead of a blank line. Investigate why those
subscribers have no matching row in `GiftTiers` — they may have a gift amount that falls outside the
DE's tier ranges, or a data type mismatch between the subscriber field and the DE's key column.

**Tempting-but-wrong:** Concluding that "no error = the lookup worked" and searching for a rendering
bug in the HTML instead. The blank is not a rendering bug — the AMPscript ran successfully and
returned an empty string exactly as designed. Without an `IF Empty()` guard, blank returns are
invisible in Test Sends when the test subscriber happens to have a matching row.

**Verify:** In Subscriber Preview, select a subscriber who received the blank line and inspect the
rendered email. Then open the `GiftTiers` DE and query for that subscriber's gift amount value — a
missing or mismatched row confirms the lookup miss. Add the guard, re-preview with the same subscriber,
and confirm the fallback renders.

---

## Study resources & relevance

Study resources, recommended study plan, exam traps, and NPSP/nonprofit notes:
[references/study-resources.md](references/study-resources.md).

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce;
all trademarks belong to their respective owners. Guidance only — verify against official documentation
and live orgs before acting. No certification outcome is implied or guaranteed.*
