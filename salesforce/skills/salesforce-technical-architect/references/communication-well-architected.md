# CTA Communication & Well-Architected — Deep Dive

> Load when preparing architectural defense presentations, stakeholder communication plans, or when you need extended Well-Architected trade-off framing.

---

## Communication — operational rules

**Frame every decision as "we chose X over Y because Z, accepting risk R."** Don't cite "Salesforce best practice" as the reason — name the trade-off. Example: "Single application object with a type discriminator over several objects, because it keeps the Apex mapper and schema-sync simple; accepting a wide object."

**Translate to the audience.** For a non-technical executive or board, express decisions in cost, risk, and time-saved terms — not governor limits. Keep the FLS/limits depth for technical readers. The same decision needs two framings:

| Audience | Frame |
|---|---|
| Executive / board | Cost, risk, delivery speed, business outcome |
| Technical architect / dev | Governor limits, deployment risk, maintainability trade-off |
| Operations / support | Who owns it, how it's monitored, failure mode |

**Surface blockers early with a proposed mitigation, never just "blocked."** Licensing gaps, approaching limits, an ECA Consumer Key that's UI-only and behind email verification (no scriptable path) — flag these the moment they appear, with the workaround.

**Record decisions so they aren't relitigated.** A "decisions worth not relitigating" log plus a session log is a lightweight ADR mechanism — when you settle a trade-off, write it down with: decision made, alternatives considered, rationale, date, and who approved.

**Anti-patterns / red flags:**
- "Best practice" with no stated trade-off.
- Same technical depth for the board and for engineers.
- Reporting a blocker with no proposed path forward.
- A decision log that exists but is never consulted when the same question re-surfaces.

---

## Well-Architected Extended — framing for architectural defense

The Salesforce Well-Architected framework (Trusted / Easy / Adaptable) is not just a checklist — it is the scoring rubric CTA review boards apply. Every design choice needs to be evaluated, not just described.

**Trusted axis** — What does the design protect?
- Data residency and compliance (where does data live, who can see it, what's the breach surface?)
- Availability and reliability (what is the failure mode? is there graceful degradation?)
- Security (access model, encryption at rest/in transit, audit trail, PII handling)

**Easy axis** — Who maintains this, and at what cost?
- Declarative vs. code (how much Salesforce-certified admin effort vs. developer effort?)
- Supportability (can a solo admin diagnose an issue at 11pm without the original developer?)
- Time-to-value (how fast can the team ship changes as requirements evolve?)

**Adaptable axis** — What breaks when the business changes?
- Scalability (will this hold at 10× current volume? what's the ceiling?)
- Extensibility (can you add a new record type / channel / integration without rearchitecting?)
- Future-proof (are you using platform-native capabilities or building against them?)

**How to use this in a review:**
1. State the choice clearly.
2. Name the axis where it excels.
3. Name the axis where it incurs cost or risk.
4. Name the mitigating design decision that limits that risk.

Example: "We chose a single `Application__c` object with a `Type__c` discriminator over one-object-per-type. This wins on Easy (single schema to maintain, single set of Flows, one Apex mapper) and Adaptable (adding a new application type is a picklist value + record type, not a new object + all its automation). It accepts a somewhat wide object (Trusted cost: marginally harder to lock down field visibility per type). Mitigation: Record Types carry per-type page layouts that hide irrelevant fields at the UI layer, and FLS is set per-type permset where needed."

---

## Multi-Cloud architecture trade-off examples

**MuleSoft vs. direct Named Credentials:**
- MuleSoft wins on Adaptable (central API mesh, reuse across systems) and Trusted (centralized auth enforcement, SLA monitoring).
- MuleSoft loses on Easy (another platform to license, deploy, and monitor) for simple integrations.
- Decision rule: MuleSoft is warranted when ≥3 external systems share a common API contract, or when enterprise security policy mandates a centralized API gateway.

**Data Cloud vs. custom ETL for Unified Profile:**
- Data Cloud wins on Trusted (out-of-box Identity Resolution with no hand-rolled dedup), Adaptable (connectors for all major SF clouds), and Easy (no ETL pipeline to own).
- Data Cloud loses on Easy for orgs without a Data Cloud SKU or without a team familiar with Data Streams.
- Decision rule: always check licensing first; if Data Cloud is in the contract, it is architecturally superior to custom ETL for 360-profile requirements every time.

**Single org vs. multi-org:**
- Single org wins on Easy (one security model, one deployment pipeline, shared reporting) and Trusted (no cross-org sync surface to secure or audit).
- Multi-org wins on Trusted in specific scenarios: strict legal data-residency, M&A isolation, business units that are contractually separate.
- Decision rule: the burden of proof is on multi-org. Every "let's add an org" proposal must name the specific legal, contractual, or M&A constraint that makes separation mandatory.
