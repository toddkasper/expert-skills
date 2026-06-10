# Application tasks — salesforce-sales-cloud-consultant (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Lead conversion field mapping and deduplication design

**Prompt to the agent:** A B2B SaaS client is going live with Sales Cloud next month. Their ops lead has sent you this spec and asked you to produce a lead conversion mapping document and flag any configuration errors or traps before deployment.

**Spec (flawed — embedded traps):**

> - Lead field `Budget_Range__c` (picklist) maps to Opportunity field `Deal_Size__c` (text). No custom Contact field needed for budget.
> - Duplicate rule on Lead uses "Exact" match on `Email` field only. The rule is set to **Block** on create. The Account duplicate rule also uses Exact match on `Name` only.
> - When a rep converts a Lead, a new Account is always created — no "match to existing Account" step is in the conversion process.
> - The integration user's profile has "Convert Leads" unchecked in object permissions, but a permission set grants the user "Modify All Data."
> - Einstein Lead Scoring has been activated. The team has 18 reps and has closed 14 deals over the past seven months.
> - A validation rule on Opportunity fires when `CloseDate` is in the past. The rule is active on all record types, including the record type created at conversion.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Picklist-to-text field-type mismatch: `Budget_Range__c` (picklist) cannot map to `Deal_Size__c` (text) in standard lead conversion; the target field must match type or be a compatible type. Agent must flag this and prescribe the fix (change target to picklist or text-to-text remapping with a formula).
- [ ] Trap 2 — Duplicate rule set to Block with Exact-email-only match will silently allow duplicates whenever email differs by even one character (typo, alias). Agent must recommend Fuzzy/Exact on multiple fields (email + name + company) and note that "Block" alone without a merge workflow leaves latent duplicates.
- [ ] Trap 3 — "Always create new Account" at conversion without an existing-Account match step will generate Account duplicates for every re-converted or re-submitted lead from the same company. Agent must call out the "Use existing Account" option at conversion and the need for an Account duplicate rule with a merge path.
- [ ] Trap 4 — Einstein Lead Scoring requires a minimum of **50 converted leads** from the past **12 months** to train; 14 deals in 7 months is below threshold. Agent must state the model will not activate (or will show a "not enough data" state) and recommend waiting or using a scoring Flow as interim.
- [ ] Trap 5 — Validation rule on CloseDate fires at conversion (because conversion sets CloseDate), and if the default CloseDate at conversion is today or a past date, the rule will block conversion. Agent must flag that validation rules run during lead conversion and recommend scoping the rule by record type or stage to avoid blocking conversion records.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Field-type compatibility table mapping each Lead field to the correct Opportunity/Contact/Account field type, with the Budget_Range mismatch flagged and two fix options given.
- Duplicate-rule design recommendation: Exact+Fuzzy on email + last name + company, "Alert" mode with merge workflow, plus Account rule on Name + Billing City.
- Conversion process note: always surface "Match to existing Account" step; link duplicate rule to conversion.
- Einstein Lead Scoring prerequisite callout: 50+ converted leads / 12 months required; current data will not train the model.
- Validation rule scoping recommendation: add a record-type or Stage condition so it does not fire on the conversion-created Opportunity.

---

## Task 2 — Collaborative Forecasting setup review and sharing model redline

**Prompt to the agent:** A mid-market manufacturing client has sent you their Collaborative Forecasting configuration notes and a new sharing requirement. Review the spec, produce a redlined configuration guide, and flag every trap before the client's UAT next week.

**Spec (flawed — embedded traps):**

> **Forecasting setup:**
> - Forecast type: Opportunity Amount, single currency. Fiscal year starts February 1.
> - Quota object: the team plans to load quotas via a CSV import directly into the `ForecastingQuota` standard object using Data Import Wizard.
> - Manager adjustments are enabled. The VP (two levels above reps) says her adjustments should roll up to her manager's forecast automatically — no additional config needed.
> - The org uses Person Accounts. The forecast hierarchy is built from the role hierarchy. Two reps share the same role (both titled "West Region Rep") and are peers.
>
> **Sharing requirement:**
> - A new "Revenue Ops" team needs read access to every Opportunity across all territories regardless of owner. OWD on Opportunity is set to Private.
> - The admin plans to create a criteria-based sharing rule: "Share all Opportunities where `OwnerId != null` with the Revenue Ops public group, access level = Read/Write."
> - A custom `FX_Rate__c` field on Opportunity stores the exchange rate at deal close for international deals. The Revenue Ops permission set grants "Edit" on `FX_Rate__c`. The admin says FLS Edit on the permission set means Revenue Ops users can edit the field on any Opportunity they can see.
>
> **Price book config:**
> - The client has one Standard Price Book and two custom price books (EMEA, APAC). Each Opportunity is assigned a price book at creation. A rep reports she can see EMEA products in a deal she is closing in APAC. The admin says this is expected because all active products appear in the lookup.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `ForecastingQuota` cannot be loaded via Data Import Wizard; it requires the Forecasting API or direct REST/SOAP API calls (or a managed package like Salesforce Maps/Territory). Agent must flag the unsupported import path and prescribe the correct mechanism.
- [ ] Trap 2 — Manager adjustments roll up only one level at a time; a VP two levels above reps sees her own adjusted view, but her manager sees the VP's manager-adjusted number only after the VP's manager makes their own adjustment. The VP's adjustments do NOT automatically propagate two levels up. Agent must explain the per-level adjustment behavior and how each manager must save their own layer.
- [ ] Trap 3 — Criteria-based sharing rule granting "Read/Write" violates the minimum-necessary-access principle and exceeds the stated requirement ("read access"). Agent must flag the access level and correct it to Read Only. Bonus: note that sharing rules cannot grant more access than OWD, and that a criteria-based rule on `OwnerId != null` is effectively "all records," which should be documented as intentional.
- [ ] Trap 4 — FLS Edit on a permission set does NOT override OWD sharing; a Revenue Ops user who reaches a record only via a sharing rule has the access level defined in that rule (Read Only), regardless of FLS Edit on the field. FLS controls field visibility/editability within the access they already have; it does not elevate record-level access. Agent must distinguish FLS from record-level sharing.
- [ ] Trap 5 — Price book assignment to an Opportunity does not filter the product catalog visible to the rep; it only determines which price book's pricing applies. If the rep can see the Opportunity and the product is active, she can add EMEA products to an APAC deal unless a validation rule or Flow enforces price-book/region alignment. Agent must call out the gap and recommend a validation rule or Flow guard.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Quota load: prescribe the Forecasting REST API endpoint (`/services/data/vXX.X/sobjects/ForecastingQuota`) or a supported ISV tool; note Data Import Wizard does not support this object.
- Adjustment roll-up explanation: diagram showing each manager saves their own adjusted layer; VP adjustments visible to VP's manager only after that manager opens and saves their forecast view.
- Sharing rule correction: change access level from Read/Write to Read Only; document the "all records" intent explicitly.
- FLS vs. record-access distinction: table showing FLS gates field UI/API visibility within granted record access; does not grant record access itself.
- Price book enforcement: validation rule formula `AND(Pricebook2.Name = "APAC", <EMEA product condition>)` or a Flow that clears line items if price book changes; note the catalog is not auto-filtered.
