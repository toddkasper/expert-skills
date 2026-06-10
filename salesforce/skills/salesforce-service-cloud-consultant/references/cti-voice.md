# Service Cloud — CTI & Voice Deep Dive

> Load when designing or troubleshooting a telephony integration: Open CTI vs. Service Cloud Voice selection, screen pop configuration, supervisor features, or PBX/carrier integration blockers.

---

## CTI & Voice — operational rules

**Open CTI** is a JavaScript API that lets browser-based softphones integrate with Salesforce without a desktop app. It does not require Service Cloud Voice; any third-party CTI vendor can use it. Recognize the distinction: Open CTI = integration pattern; Service Cloud Voice = Salesforce's native voice product with three telephony model options (see below).

**Screen pop on inbound call:** the CTI adapter fires an `onCallBegin` event; Salesforce uses ANI (caller phone number) to search for a matching Contact/Account/Case and pops that record. If the number matches multiple records, Salesforce presents a disambiguation list — design for duplicates.

**Service Cloud Voice adds:** real-time transcription, Einstein next-best-action surfacing during a call, supervisor barge-in/monitor, and post-call transcript stored on the Case. These are not available with generic Open CTI.

**Service Cloud Voice supports three telephony models** `[volatile — verify live]`:
1. **Amazon Connect (Salesforce-managed)** — Salesforce provisions and manages the Amazon Connect instance; highest integration depth and easiest setup for new implementations.
2. **Partner Telephony** — a certified third-party telephony provider (e.g. Genesys, Vonage, Avaya) integrates with Service Cloud Voice via the Partner Telephony framework; the provider manages the telephony layer while Salesforce handles the CRM surface (transcription, supervisor, next-best-action).
3. **Bring Your Own Telephony (BYOT)** — the customer manages their own Amazon Connect instance (not Salesforce-managed); gives more control over Connect configuration at the cost of more self-managed infrastructure.

**Decision implication:** the prior decision rule "requires routing to Amazon Connect" applies only to Salesforce-managed Voice. Partner Telephony allows organizations with an existing CCaaS vendor to use Service Cloud Voice features without rerouting to Amazon Connect.

**Supervisor features** (Omni Supervisor, barge-in, whisper coaching) require Omni-Channel to be active — they are not available in a pure queue model.

**RED FLAG:** proposing Salesforce-managed Service Cloud Voice (Amazon Connect model) without confirming the telephony carrier can route to Amazon Connect, or assuming the customer's existing PBX will pass caller data through — PBX integration complexity is usually the blocker, not Salesforce config. If an existing CCaaS vendor relationship must be preserved, evaluate the Partner Telephony model first.

---

## Open CTI vs. Service Cloud Voice — decision table

| Factor | Open CTI (3rd-party softphone) | SCV — Amazon Connect (SF-managed) | SCV — Partner Telephony | SCV — BYOT (own Connect) |
|---|---|---|---|---|
| Telephony provider | Any CTI vendor with an Open CTI adapter | Salesforce provisions Amazon Connect | Certified 3rd-party CCaaS vendor | Customer-managed Amazon Connect |
| Real-time transcription | Vendor-dependent | Native | Native (via partner) | Native |
| Einstein AI during call | Not available | Next Best Action, article recommendations | Available | Available |
| Supervisor barge-in/whisper | Vendor-dependent | Native via Omni Supervisor | Native via Omni Supervisor | Native via Omni Supervisor |
| Carrier flexibility | High — works with existing PBX/PSTN | Requires routing to Amazon Connect | Preserved — existing CCaaS vendor retained | Requires Amazon Connect routing (self-managed) |
| Setup complexity | Lower if vendor adapter exists | Higher initial telephony integration | Moderate — partner handles telephony | Highest — customer owns Connect config |
| Cost | CTI vendor license + SF license | Service Cloud Voice SKU + Amazon Connect usage | SCV SKU + partner vendor costs | SCV SKU + Amazon Connect usage (self-billed) |

**Decision rule:** choose Service Cloud Voice when real-time transcription, native Einstein AI, or Salesforce-managed supervisor features are required. Within SCV: use the Amazon Connect (Salesforce-managed) model for net-new telephony with no existing vendor; use Partner Telephony when the organization already has a certified CCaaS vendor and cannot or will not route to Amazon Connect; use BYOT when the organization needs full control of its own Amazon Connect instance. Choose Open CTI when the organization has an existing CTI vendor with an adapter that is not a certified SCV partner, an existing PBX that cannot route to Amazon Connect, or budget constraints that make the Voice SKU impractical.

---

## Screen Pop design considerations

**ANI matching logic:** Salesforce searches Contact (Phone, MobilePhone), Account (Phone), and Case (SuppliedPhone) in a configurable order. If the org has Person Accounts, the matching surface expands. Always confirm the matching fields and their FLS before go-live — a field hidden by FLS will not match.

**Duplicate handling:** design an explicit "call center agent picks the right record" flow rather than auto-popping the wrong record. A disambiguation list with caller name/account is better than a silent wrong-pop.

**Outbound call click-to-dial:** Open CTI enables click-to-dial from phone fields on any record. The CTI adapter intercepts the click and initiates the call. Confirm the adapter supports outbound if click-to-dial is a requirement — not all adapters do.

---

## PBX and carrier integration checklist

Before recommending Service Cloud Voice, first confirm the telephony model (Amazon Connect SF-managed, Partner Telephony, or BYOT). Then:

**For Amazon Connect (Salesforce-managed) model:**
- [ ] Confirm the carrier supports PSTN pass-through to Amazon Connect (not all carriers do without additional routing config).
- [ ] Confirm the existing PBX can forward calls to Amazon Connect, or that Direct Inward Dialing (DID) numbers can be ported.
- [ ] Confirm that the geography of callers is supported (Amazon Connect has regional availability constraints).
- [ ] Identify the toll-free / local number strategy — porting numbers to Amazon Connect has a lead time of weeks.
- [ ] Identify who manages the Amazon Connect instance — Salesforce manages the SF-side config; the customer or a telephony partner manages the Connect instance and carrier routing.

**For Partner Telephony model:**
- [ ] Confirm the existing CCaaS vendor is a certified Salesforce SCV Partner Telephony provider.
- [ ] Confirm the partner's SCV connector is available in AppExchange and current.
- [ ] Confirm transcription and supervisor features are available through the partner's integration (feature parity varies by partner).

**For all SCV models:**
- [ ] Identify who owns agent headset/softphone provisioning.
- [ ] Confirm agent profiles have the Service Cloud Voice user permission and the correct SCV license.

If any of the above is uncertain, confirm telephony feasibility before committing to a Service Cloud Voice architecture.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
