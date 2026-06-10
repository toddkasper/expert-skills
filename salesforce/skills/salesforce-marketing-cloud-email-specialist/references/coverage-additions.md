# Coverage Additions — Operational Rules

Extended operational rules that close blueprint coverage gaps not covered in the main SKILL.md sections.
Load this file when working on Content Builder template architecture, Automation Studio triggers,
AMPscript edge cases, Intelligence Reports, or publication/suppression list wiring.

---

## Content Builder: slot-based templates and approval workflow

- **Slot-based templates** lock brand structure (header/footer/layout) while exposing named **content
  slots** that content authors fill per-send. Use them when multiple people create emails — the template
  enforces compliance; the slot is the only editable surface. If a slot has no block assigned, the
  template's default content renders; always set a sensible default so a blank slot doesn't ship.
- **Send preview / approval:** before scheduling any send, run **Test Send** (delivers a real email to
  a test address) and **Subscriber Preview** (renders the email substituting a live subscriber record).
  These are different: Test Send catches rendering breakage; Subscriber Preview catches AMPscript errors
  on edge-case records (null fields, unexpected data types). Use both.
- **Content block sharing across business units** requires the block to be stored in a *shared* Content
  Builder folder visible to child BUs. Blocks in a parent BU's private folder are not accessible to
  children. When a child-BU send is broken by a missing block, check folder-level sharing first.

---

## Automation Studio: File Drop trigger and Run Once

- **File Drop** starts an automation when a file matching a naming pattern lands on the SFTP. Use it for
  event-driven imports where the upstream system controls the schedule (e.g. a nightly CRM extract).
  If no file arrives, the automation simply does not run — build an alerting process outside SFMC
  to catch missed drops.
- **Run Once** executes an automation immediately on demand. Useful for ad-hoc backfills or to test a
  new automation before enabling its scheduled trigger. Confirm all prior steps completed successfully
  before a Run Once in production — partial-state data in a target DE can cause downstream send errors.

---

## AMPscript: Lookup() behavior when no row is found

- `Lookup()` returns an **empty string** when the row is not found — it does not throw an error or stop
  rendering. This means a missing record in a lookup DE silently returns blank, which can produce broken
  personalization (e.g. blank links, empty tables). Always pair `Lookup()` with an `IF Empty()` guard
  and a fallback value or a graceful content block.
- For multi-row lookups (`LookupRows()` / `LookupOrderedRows()`), check `RowCount()` before iterating.
  A zero-row result with an unchecked loop renders nothing but also silently skips content — easy to
  miss in a Test Send if the test subscriber happens to have data.

---

## Intelligence Reports (Datorama)

- **Marketing Cloud Intelligence** (formerly Datorama) is SFMC's advanced analytics layer for
  cross-channel reporting, dashboard building, and data blending. It sits above the built-in Email
  Studio reports and is relevant when: you need to blend email tracking data with ad spend or CRM
  pipeline data, or when you need custom dashboards beyond the standard Email Performance reports.
- For operational work, the standard Email Studio reports + SQL against Data Views cover most use
  cases without requiring an additional Intelligence license. Know this layer exists and what it adds
  for cross-channel reporting scenarios.

---

## Publication lists vs. suppression lists

- **Publication list** = a list a subscriber is *on* (opt-in scope). A subscriber's status on a
  publication list controls whether they receive sends targeted at that list.
- **Suppression list** = a list of addresses to *exclude* from a send, regardless of opt-in status.
  Suppression lists are applied at send time as a safety net (e.g. recent purchasers, in-flight
  journey contacts, known complainers).
- They are **additive suppressors**: you can have a subscriber on a publication list (opted in) and
  still block them from a specific send via a suppression list. Neither replaces the other.
  **RED FLAG:** confusing them — applying a suppression list as the send target (instead of a
  publication list or DE) sends to nobody; applying a publication list as a suppression silently
  blocks your intended audience.

---

## Email design rules

- Mobile-first: design fluid/responsive with `@media` queries; ~half of opens are mobile. Use large tap targets, big fonts, and single-column layouts — especially for older audiences.
- Subject line + preheader are the open-rate levers. Avoid spam-trigger words, ALL CAPS, excessive `!`.
- A/B test ONE variable at a time (subject OR from-name OR send-time), define the winner metric up front (open vs. click vs. conversion), and use a large enough test cell to be significant.

---

## Profile & preference management

- **Profile Attributes** = identity fields. **Preference Attributes** = opt-in/opt-out toggles by category (e.g. "Donor appeals" vs. "Volunteer updates"). Give people granular preferences via the **Subscription Center** so they downgrade instead of fully unsubscribing.
- Capture/update subscribers with **Web Collect** (forms posting to MC) or **Smart Capture** (forms on CloudPages). For consent-sensitive lists, gate activation behind **Double Opt-In**.

---

## Marketing Cloud Connect (MCC) — the CRM bridge

- MCC is the integration layer between SFMC and Salesforce CRM. Two modes: **Synchronized Data Sources** (replicate CRM objects into MC as Synchronized DEs for segmentation) and **Salesforce Send** (send tied to a CRM Campaign, tracking flows back to the Contact/Lead activity timeline).
- MCC uses tenant-specific endpoints + an integration user with API access. **Verify the CRM objects you intend to segment on are actually synced** before building a journey on them.
- **Verify field-level security for the MCC integration user.** A field can be synced but unreadable — if FLS isn't granted to the integration user, the synced field returns blank or "Invalid field." Confirm read access for every field you intend to segment on.
- **Exposing a custom object to MC** is possible via the connected/external client app, but the app's permission assignment and consumer-key retrieval often have org-specific friction — verify the integration user can actually query the object before designing segments on it.
