# AI & Sales Productivity Features — Operational Rules

> Load this file when evaluating or recommending AI add-ons for a Sales Cloud implementation. Moved from SKILL.md §11 to keep body ≤ ~4,500 words.

## Rules

- **Einstein Lead/Opportunity Scoring needs history** — predictive models require a minimum volume of closed/converted records (hundreds+) `[volatile — verify live]` to train. Do not recommend it for a low-volume org with no history.
- **Distinguish predictive AI** (scoring, forecasting — needs training data) from **generative AI** (Agentforce / Agentforce for Sales, formerly Einstein Copilot, email drafting — needs grounding data and guardrails, not training history).
- **Agentforce for Sales (formerly Einstein Copilot)** — renamed in Spring '25. Functions as an autonomous AI agent within Sales Cloud: email drafting, meeting prep, deal research. Requires quality grounding data and Trusted AI guardrail configuration before deployment. The exam's Predictive and Generative AI domain `[volatile — verify live]` tests: (a) which Agentforce for Sales capabilities apply to a given scenario, (b) when *not* to use predictive AI (low volume, sparse history), and (c) Salesforce's Trusted AI Principles: Responsibility, Accountability, Transparency, Empowerment, Inclusivity.
- **Trusted AI Principles** — the Sales Cloud Consultant exam explicitly tests the ability to identify ethical challenges of AI and apply the five Trusted AI Principles to sales scenarios. Know the principles by name.
- **Sales Engagement (formerly High Velocity Sales)** = cadences/call lists for high-throughput SDR teams — overkill for a low-volume org.
- The judgment this domain tests is recognizing when *not* to recommend a heavyweight feature. A low-volume org with sparse history should not invest in Einstein Scoring; a high-volume SDR team benefits from Sales Engagement cadences.

## Decision table

| Feature | Prerequisite | Skip when |
|---|---|---|
| Einstein Lead Scoring | Hundreds of converted leads with outcome data | Low lead volume, <6 months of history |
| Einstein Opportunity Scoring | Closed Won/Lost history, consistent stage usage | Stage data is inconsistent or org is new |
| Agentforce / Agentforce for Sales (formerly Einstein Copilot; email drafting, autonomous sales tasks) | Grounding data (Contact/Account data quality); Trusted AI guardrails configured | PII/compliance concerns not yet addressed |
| Sales Engagement | High-volume SDR team, defined cadences | Low-volume account-based sales motion |

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
