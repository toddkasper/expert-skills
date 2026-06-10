# Service Cloud — CTI & Voice Deep Dive

> Load when designing or troubleshooting a telephony integration: Open CTI vs. Service Cloud Voice selection, screen pop configuration, supervisor features, or PBX/carrier integration blockers.

---

## CTI & Voice — operational rules

**Open CTI** is a JavaScript API that lets browser-based softphones integrate with Salesforce without a desktop app. It does not require Service Cloud Voice; any third-party CTI vendor can use it. Recognize the distinction: Open CTI = integration pattern; Service Cloud Voice = Salesforce's native voice product (currently powered by Amazon Connect).

**Screen pop on inbound call:** the CTI adapter fires an `onCallBegin` event; Salesforce uses ANI (caller phone number) to search for a matching Contact/Account/Case and pops that record. If the number matches multiple records, Salesforce presents a disambiguation list — design for duplicates.

**Service Cloud Voice adds:** real-time transcription, Einstein next-best-action surfacing during a call, supervisor barge-in/monitor, and post-call transcript stored on the Case. These are not available with generic Open CTI.

**Supervisor features** (Omni Supervisor, barge-in, whisper coaching) require Omni-Channel to be active — they are not available in a pure queue model.

**RED FLAG:** proposing Service Cloud Voice without confirming the telephony carrier can route to Amazon Connect, or assuming the customer's existing PBX will pass caller data through — PBX integration complexity is usually the blocker, not Salesforce config.

---

## Open CTI vs. Service Cloud Voice — decision table

| Factor | Open CTI (3rd-party softphone) | Service Cloud Voice |
|---|---|---|
| Telephony provider | Any CTI vendor with an Open CTI adapter | Amazon Connect (Salesforce-managed) |
| Real-time transcription | Vendor-dependent | Native |
| Einstein AI during call | Not available | Next Best Action, article recommendations |
| Supervisor barge-in/whisper | Vendor-dependent | Native via Omni Supervisor |
| Carrier flexibility | High — works with existing PBX/PSTN | Requires routing to Amazon Connect |
| Setup complexity | Lower if vendor adapter exists | Higher initial telephony integration |
| Cost | CTI vendor license + SF license | Service Cloud Voice SKU + Amazon Connect usage |

**Decision rule:** choose Service Cloud Voice when real-time transcription, native Einstein AI, or Salesforce-managed supervisor features are required AND the organization can route telephony to Amazon Connect. Choose Open CTI when the organization has an existing CTI vendor with an adapter, an existing PBX that cannot easily route to Amazon Connect, or budget constraints that make the Voice SKU impractical.

---

## Screen Pop design considerations

**ANI matching logic:** Salesforce searches Contact (Phone, MobilePhone), Account (Phone), and Case (SuppliedPhone) in a configurable order. If the org has Person Accounts, the matching surface expands. Always confirm the matching fields and their FLS before go-live — a field hidden by FLS will not match.

**Duplicate handling:** design an explicit "call center agent picks the right record" flow rather than auto-popping the wrong record. A disambiguation list with caller name/account is better than a silent wrong-pop.

**Outbound call click-to-dial:** Open CTI enables click-to-dial from phone fields on any record. The CTI adapter intercepts the click and initiates the call. Confirm the adapter supports outbound if click-to-dial is a requirement — not all adapters do.

---

## PBX and carrier integration checklist

Before recommending Service Cloud Voice:
- [ ] Confirm the carrier supports PSTN pass-through to Amazon Connect (not all carriers do without additional routing config).
- [ ] Confirm the existing PBX can forward calls to Amazon Connect, or that Direct Inward Dialing (DID) numbers can be ported.
- [ ] Identify who manages the Amazon Connect instance — Salesforce manages the SF-side config; the customer or a telephony partner manages the Connect instance and carrier routing.
- [ ] Confirm that the geography of callers is supported (Amazon Connect has regional availability constraints).
- [ ] Identify the toll-free / local number strategy — porting numbers to Amazon Connect has a lead time of weeks.

If any of the above is uncertain, the correct recommendation is to confirm telephony feasibility before committing to a Service Cloud Voice architecture.
