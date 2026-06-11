---
name: salesforce-marketing-cloud-email-specialist
description: Building Salesforce Marketing Cloud (SFMC) email campaigns, journeys, and automation — Journey Builder welcome/nurture flows, Automation Studio batch pipelines, Content Builder, AMPscript personalization, data extensions and SQL Data Views, Triggered/Single/User-Initiated sends, deliverability (SPF/DKIM/DMARC, IP warming, bounce handling), Marketing Cloud Connect to CRM, and inbox analytics. Use when designing or reviewing SFMC email, journeys, segmentation, or deliverability. This is SFMC (Studio/Builder stack) — not core CRM email or Pardot/Account Engagement. Scoped and benchmarked by the Marketing Cloud Email Specialist (MC-202) blueprint.
metadata:
  anchor-credential: Salesforce Certified Marketing Cloud Email Specialist
  exam-code: MC-202
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-10
  blueprint-verified: 2026-06-07
---

# Salesforce Marketing Cloud Email Specialist — Skills Reference

## Overview

The **Salesforce Certified Marketing Cloud Email Specialist** (exam code **MC-202**) validates
proven knowledge, skills, and hands-on experience in email marketing best practices within the
Salesforce Marketing Cloud (SFMC) platform. The six exam domains are: Email Marketing Best
Practices, Email Message Design, Content Creation & Delivery, Marketing Automation, Subscriber &
Data Management, and Tracking & Reporting (see domain weights in
[references/study-resources.md](references/study-resources.md)) `[volatile — verify live]`.

This is the primary entry-level certification in the Marketing Cloud track. It is a prerequisite
for advanced credentials such as Marketing Cloud Consultant, Marketing Cloud Developer, and
Marketing Cloud Account Engagement Specialist. Salesforce recommends 6–12 months of hands-on
Marketing Cloud experience before attempting.

**When to reach for Marketing Cloud:** SFMC is the platform for *marketing* sends — campaigns, program updates, recruitment, lifecycle messaging — with engagement tracking, unsubscribe management, and journey automation. *Transactional* 1:1 mail (submit confirmations, password resets, magic-link delivery)
is often better served by a cheaper transactional email service (e.g. Amazon SES) unless a
Triggered Send is already justified by the broader MC adoption. The rules below let an agent make
the transactional-vs-marketing call, design a compliant journey, and avoid the deliverability and
data-model traps that bite teams integrating MC with a CRM.

**This file is an operational playbook, not an exam outline.** Each section states the actual rules
an agent must apply, the concrete limits, the decision criteria for picking a tool, and the
anti-patterns to catch in review.

> **Load this skill when…** designing or reviewing Salesforce Marketing Cloud email campaigns, Journey Builder flows, or Automation Studio pipelines; configuring deliverability (SPF/DKIM/DMARC, IP warming, bounce handling); working with data extensions, AMPscript personalization, or Marketing Cloud Connect; or diagnosing send failures, subscriber status issues, or inbox analytics.
> **Not this skill:** this is SFMC (Studio/Builder stack) — not core CRM email alerts or Pardot/Account Engagement; for CRM email activity tied to Sales or Service Cloud objects, see `salesforce-sales-cloud-consultant` or `salesforce-service-cloud-consultant`.

> **Deeper context:** Study resources (official Salesforce + community) live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, keep a per-org appendix in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** volatile facts in this skill include CAN-SPAM penalty amounts, Gmail/Yahoo bulk-sender thresholds and enforcement dates, 10DLC registration requirements, Data Views default retention periods, IP warming ramp schedules, and any Einstein feature availability or prerequisite — verify against current RFC/FTC/ISP documentation and your SFMC org before acting.
- **Live wins:** when the live org or official documentation contradicts a statement in this file, trust the live source and log the discrepancy via the Feedback protocol below.
- **Escalate to a human before proceeding on:** any production send to an audience > ~50,000 contacts on a new or warmed-but-unvalidated IP; any send that re-activates a list segment not mailed in > 6 months without a re-permission step; enabling or modifying the Master Unsubscribe list; any compliance-related consent or data-erasure workflow.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. If you act on an untagged fact and the live system disagrees, file feedback — do not silently trust this file over the live org.

---

## 1. Email Marketing Best Practices — Operational Rules

### Compliance is non-negotiable; build it into every send

- **Every commercial email MUST carry a physical postal address and a working one-click
  unsubscribe.** CAN-SPAM requires this; omitting it is a per-message violation (up to ~$53,088 per
  email in U.S. penalties `[volatile — verify live]`). In SFMC this lives in the email footer / Delivery Profile, not the body —
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
  >5,000/day `[volatile — verify live]`). Verify DNS before the first send, not after bounces appear.
- **Warm a new dedicated IP over ~30 days**, ramping volume gradually (e.g. day 1: ~50/send, doubling
  every few days). Blasting full volume on a cold IP gets you throttled or blocklisted.
- **Bounce handling — know the status transition:**

  | Bounce type | Cause | SFMC subscriber status result |
  |---|---|---|
  | **Hard bounce** | Permanent — invalid/nonexistent address | → **Bounced** (auto-suppressed) |
  | **Soft bounce** | Temporary — full mailbox, server timeout, message too large | retried; repeated soft → **Held** |
  | Spam complaint | Recipient hit "report spam" | → **Unsubscribed** |

- **Keep spam-complaint rate < 0.1% and hard-bounce rate low** — Gmail enforces a 0.3% complaint
  threshold `[volatile — verify live]`. Use **List Detective** to screen imports for role addresses (`info@`, `sales@`) and known
  spam-trap patterns before they enter a send.
- **RED FLAG in review:** sending to a list/DE that hasn't been mailed in 6–12+ months with no
  re-permission step → high bounce + complaint risk. Re-engage or suppress stale addresses first.

Email design rules (mobile-first, subject/preheader, A/B test discipline): [references/coverage-additions.md](references/coverage-additions.md).

---

## 1b. Email Message Design — Operational Rules

This is a standalone blueprint domain (13% of the exam `[volatile — verify live]`) covering the design, testing, and approval of email messages before send.

**Core rules to hold inline:**

- **A/B test one variable at a time** — subject line OR from-name OR send-time; define the winner metric (open vs. click vs. conversion) *before* launching; ensure test cells are large enough to be statistically significant. Do not stack multiple variables in a single test.
- **Approvals workflow:** if your SFMC account has the Approvals feature enabled, a send or journey activation that requires approval will be blocked until an approver acts. Build approval lead-time into the send schedule; a pending-approval block is the most common cause of a delayed send that "looks ready."
- **Template vs. free-form:** slot-based templates enforce brand compliance and are the correct choice for multi-author or multi-BU environments; free-form HTML emails are for one-off or developer-built sends. Never edit a template's locked slot structure per-send — that is the compliance control.
- **Rendering validation:** always run a cross-client render check (Litmus or Validate) before a major send. Outlook uses the Word rendering engine and is the most common source of broken layouts; test on Outlook explicitly.

Full email design rules (mobile-first, responsive layout, preheader best practices): [references/coverage-additions.md](references/coverage-additions.md) — the "Email design rules" and "Content Builder: slot-based templates" sections.

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
| Best for | Welcome series, nurture sequences, event drip | Nightly data import, SQL segmentation, file transfer/extract |
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

  Welcome series → usually **No Re-entry** (don't welcome a contact twice). Recurring reminder →
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

Profile Attributes vs. Preference Attributes, Subscription Center configuration, Web Collect vs. Smart Capture, and Double Opt-In setup: [references/coverage-additions.md](references/coverage-additions.md).

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
  of data by default `[volatile — verify live]` — for longer history, extract to a DE on a schedule.

### Marketing Cloud Connect (MCC) — the CRM bridge

MCC deep-dive (Synchronized Data Sources vs. Salesforce Send, integration user FLS verification, custom object exposure): [references/coverage-additions.md](references/coverage-additions.md).

Core rule to hold inline: **verify the CRM objects you intend to segment on are actually synced AND that the MCC integration user has FLS Read on every field** before building a journey — a synced field with no FLS returns blank, not an error.

---

## 5. Tracking & Reporting — Operational Rules

Key metric definitions (Delivered, Open Rate, CTOR, Click Rate, Bounce Rate, Unsubscribe Rate, Spam Complaint Rate), the report-selection table (Account Send Summary, Campaign Email Tracking, Email Performance by Domain, Bounce Summary, etc.), and guidance on Tracking Extracts and Data View SQL for re-engagement suppression: [references/analytics-reports.md](references/analytics-reports.md) — load when building dashboards, diagnosing deliverability trends, or writing engagement-suppression queries.

Core rule to hold inline: **lean on clicks/CTOR, not opens** — open tracking is pixel-based and unreliable since Apple Mail Privacy Protection pre-fetches pixels.

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

## Executable Workflows

### 1. Build a welcome journey (data extension → entry source → sends → verify)

1. Create a Sendable Data Extension with a Subscriber Key field and any personalization fields (FirstName, etc.). Set a Primary Key. → **gate: DE appears in Email Studio; `SELECT COUNT(*) FROM <DE>` returns rows after a test import.**
2. In Content Builder, build the welcome email with a fallback for every personalization string (e.g. `IIF(empty(@FirstName), "Friend", @FirstName)`). Test Send to a seed address. → **gate: seed receives the email; personalization renders; no blank fields.**
3. In Journey Builder → New Journey: select the DE as the Entry Source. Set Entry Schedule (when to evaluate) and re-entry mode (**No Re-entry** for a welcome series). → **gate: entry source shows record count > 0 in preview.**
4. Add Send Email activity; link to the welcome email and the appropriate Send Classification. Add a Wait step if a follow-up email is needed. → **gate: Validate the journey — no red errors.**
5. Activate the journey. → **gate: Journey History shows contacts entering; Email Tracking shows sends and at least one open/click after sending to a seed.**

### 2. Set up an Automation Studio batch pipeline (import → SQL → send)

1. Upload the source CSV to the SFTP Marketing Cloud folder. → **gate: confirm file is present in SFTP with expected row count.**
2. In Automation Studio → New Automation: add **Step 1** — Import File activity (source: SFTP file path, destination: Contacts DE, mode: Add/Update). → **gate: run Step 1 alone; query the DE — row count matches the file.**
3. Add **Step 2** (new step, not same step) — SQL Query activity. Write the SQL selecting the audience from the DE joined to any Data Views needed. Target DE = the send audience DE. → **gate: run the SQL in Query Studio first; confirm row count and no syntax errors.**
4. Add **Step 3** — Send Email activity pointing at the target DE and the correct Send Classification (Sender + Delivery Profile + suppression list wired). → **gate: test the full automation in a sandbox BU before the first production run.**
5. Schedule the automation (cron-like schedule or File Drop trigger). → **gate: Activity History after first scheduled run shows all three steps as "Complete" with no errors.**

### 3. Harden deliverability (SPF/DKIM/DMARC + IP warming + bounce handling)

1. Verify DNS records for the sending domain: SPF `include:` entry for SFMC, DKIM CNAME pointing to SFMC, DMARC `p=quarantine` (or `reject` once stable). Use a DNS-lookup tool (e.g. MXToolbox). → **gate: all three pass with no lookup errors.**
2. Confirm the Sender Authentication Package (SAP) is configured in SFMC: Setup → Account Settings → Sender Authentication Package. `[volatile — verify live]` → **gate: SAP shows the domain and DKIM signing is active.**
3. Plan the IP warming ramp: start ~50 sends/day on the new IP, doubling every few days over ~30 days, targeting highest-engagement contacts first. → **gate: no block-listing alerts (monitor via SFMC Deliverability dashboard or external tools) in the first two weeks.**
4. Apply List Detective to every new import: Admin → List Detective → run before activating any new send list. → **gate: List Detective report shows 0 known spam-trap or role-address hits in the audience.**
5. Monitor bounce handling post-send: query SFMC Bounce Summary report or SQL `SELECT * FROM _Bounce WHERE EventDate > DATEADD(day,-1,GETDATE())`. Confirm hard-bounce addresses are suppressed (status = Bounced), soft-bounce addresses show retry logic. → **gate: hard-bounce rate < 2% on warm lists; any spike triggers a list-hygiene review before the next send.**

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

**Situation:** An organization sends a recurring "membership renewal reminder" journey. Contacts who renewed last year should re-enter the journey again when their next renewal window opens.

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

Scenarios 4–5 (TSD left paused after email edit; AMPscript `Lookup()` blank return without error): [references/scenarios.md](references/scenarios.md) — load for Triggered Send and AMPscript debugging gotchas.

---

## Study resources & relevance

Study resources and recommended study plan: [references/study-resources.md](references/study-resources.md). For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-marketing-cloud-email-specialist.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-10** — Cycle-4 curation (inbox): (1) Passing score corrected 67%→65% (~39/60) with `[volatile — verify live]` tag in study-resources.md. (2) Domain weights updated to official six-domain blueprint: Best Practices 15%, Email Message Design 13%, Content Creation & Delivery 18%, Marketing Automation 19%, Subscriber & Data Management 28%, Tracking & Reporting 7% — all marked `[volatile — verify live]`; study-resources.md domain table, study-plan, and Trailhead module list all updated. (3) New §1b "Email Message Design" added (inline A/B testing rules, Approvals workflow, template vs. free-form guidance, rendering validation); pointer to existing coverage-additions.md for full rules. (4) §5 renamed from "Insights & Analytics" to "Tracking & Reporting" throughout SKILL.md, analytics-reports.md, and study-resources.md; Overview updated to list all six current exam domains. `last-reviewed` updated to 2026-06-10. Eval probes 13–14 added.
- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09. Section 5 (Insights & Analytics detail) moved to references/analytics-reports.md to keep body within word budget.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce;
all trademarks belong to their respective owners. Guidance only — verify against official documentation
and live orgs before acting. No certification outcome is implied or guaranteed.*
