# Scorecard — salesforce-experience-cloud-consultant

- **Skill:** `salesforce-experience-cloud-consultant`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocabulary (communities, partner/customer portals, LWR/Aura, sharing sets, share groups, guest-user hardening, SSO, self-registration, JIT, audiences), explicit use-when, names three sibling skills; ≤600 chars. |
| D2 | Scope contract | 3 | "Load this skill when…" / "Not this skill:" block names `salesforce-advanced-administrator`, `salesforce-service-cloud-consultant`, `salesforce-sales-cloud-consultant`; assumed tooling noted. Agent can route from Scope block alone. |
| D3 | Operational depth | 3 | §2 has the full CRUD→FLS→OWD→sharing-set→record failure-trace sequence with exact SOQL (`UserRecordAccess`); §4 template immutability with LWR vs Aura component-availability caveat; §5 ARO must-enable-before-first-portal-user rule; §8 ARO retroactive-enablement data-issue warning; §5 self-reg managed-package automation blast-radius. These are genuine practitioner scars. |
| D4 | Decision support | 3 | Decision tables in §1 (user model → license → why), §2 (sharing set vs. share group vs. sharing rule vs. role hierarchy), §4 (template by runtime, Aura vs. LWR criteria), §5 (provisioning method by volume/scenario). Every fork names the constraint. |
| D5 | Failure-mode coverage | 3 | RED FLAGs with mechanism + fix + detection: sharing set ≠ CRUD/FLS (§2), guest profile broad-Read blast-radius (§2), template migration unsupported (§4), self-reg managed-package automation (§5), CSP violation for third-party scripts (§7), CDN stale assets (§8), ARO retroactive data issue (§8), site not Published causing member login failure (§9). |
| D6 | Verification discipline | 3 | Workflow 3 (debug access failure) is a sequenced diagnostic with SOQL gates at each layer; all 3 workflows have explicit verify gates; verify note at top names MCP → `sf` CLI → UI; Workflow 2 step 3 specifies debug-log check for managed-package mutations. |
| D7 | Uncertainty & escalation | 3 | Dedicated section: re-verify-live list (license names/pricing, LWR component availability, ARO at scale), live-wins, escalate-to-human list (guest-profile CRUD/FLS changes in prod, OWD widening for external users, public self-registration on prod, ARO enablement on live portal), confidence taxonomy. |
| D8 | Executable workflows | 3 | Three numbered workflows (portal stand-up; SSO/self-reg/JIT provisioning; access-failure debug) with verify gates at each step; Workflow 3 is an end-to-end 5-step diagnostic that converts knowledge into a reproducible procedure. |
| D9 | Teaching scenarios | 1 | Body contains only a scenario table of titles (5 rows) with the note "Full scenarios… are in references/scenarios.md." Zero POLICY-format scenarios are body-resident — this is a complete deferral, not a partial one. D9 = 1 (present but weak). |
| D10 | Context economy | 2 | Snapshot: 4,875 words (4,300–5,000 band). Body is dense — 10 numbered sections + 3 workflows + 21-rule QR + "Coverage Notes & Known Gaps" section. References used for study resources and scenarios only. Trim flag: §10 "Coverage Notes" (explicit gap catalog) is useful but unusual for a playbook body; §9 "Basics" section could be compressed. Could move ~500 words to reduce below 4,300. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog dated entry; `[volatile — verify live]` on license names/pricing tiers, LWR component availability, ARO behavior at scale, Spring '21 hardening changes. |
| D12 | Measurability | 2 | Eval infra present (triggers.md, situations.md, tasks.md, answer-key.md); no recorded run in RESULTS.md. Eval infra not model-run → 2. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: needs content pass** (D9 = 1, which fails the "no dimension below 2" gate).

Sub-2 dimensions filed as inbox items: **D9 (score 1)** — zero POLICY scenarios body-resident; all deferred to references/scenarios.md. Must bring ≥2 scenarios inline to reach the publish bar.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-experience-cloud-consultant/triggers.md`. Test against descriptions only (snapshot `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "We are launching a customer portal where external users log in to view their own cases and submit new ones. Help us pick the right license and configure the sharing model." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "partner/customer portals … external license selection … configuring external-user access" | Y |
| "External users in our partner portal can see each other's Opportunities even though OWD is Private. Walk me through where the over-sharing is coming from." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "debugging external-user CRUD/FLS/OWD/sharing failures" | Y |
| "Set up SAML SSO for our Experience Cloud site so partners are logged in automatically from their company's IdP." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "user provisioning and authentication (SSO, self-registration, JIT)" | Y |
| "We need self-registration on our LWR site: visitors fill out a form, a Contact and Community User are created automatically." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "LWR and Aura templates … user provisioning and authentication … self-registration" | Y |
| "Our guest-user profile has Read access on the Account object and now a security reviewer says any unauthenticated visitor can query any Account via the API." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "guest-user hardening … configuring external-user access" | Y |
| "Configure role hierarchy and criteria-based sharing rules so the internal regional sales team can see all Accounts in their territory." | salesforce-advanced-administrator | salesforce-advanced-administrator — "full sharing/security model (role hierarchy, owner/criteria sharing rules)" — internal-org only | Y (near-miss correctly routes away) |
| "Design the Service Console layout and case assignment rules so our internal support team handles cases faster." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "Lightning Service Console … cases, assignment/escalation rules" | Y (near-miss correctly routes away) |
| "Build a public job-application form using a Screen Flow and embed it on a Salesforce site so applicants can submit without logging in." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "communities … guest-user hardening … Use when scoping a portal to the right license/user model, configuring external-user access" (unauthenticated site with guest-user model is Experience Cloud scope) | Y (this is a true-positive sanity-check) |

**Trigger pass rate:** 8/8.

Notes: Near-miss 3 is the most instructive — the phrasing explicitly calls out "Screen Flow embedded on a Salesforce site" for unauthenticated access. The experience-cloud-consultant description's "guest-user hardening … configuring external-user access" is the correct route over salesforce-administrator's generic "Flow automation." Routing holds.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-experience-cloud-consultant/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Strong on operational depth (D3=3) and failure-mode coverage (D5=3) — the CRUD→FLS→OWD→sharing-set diagnostic ladder and the ARO retroactive-enablement warning are genuine practitioner scars. **Blocked from publish-ready by D9=1**: all five decision scenarios are deferred to references/scenarios.md; the body contains only a title table, which does not satisfy the ≥4 inline POLICY-format scenarios requirement. Minimum fix: pull at least 2 scenarios inline from references/scenarios.md. Secondary item: body at 4,875 words (D10=2, trim flag active). D12 upgrades to 3 once a model run is recorded.
