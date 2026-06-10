# AI & Sales Productivity Features — Operational Rules

> Load this file when evaluating or recommending AI add-ons for a Sales Cloud implementation. Moved from SKILL.md §11 to keep body ≤ ~4,500 words.

## Rules

- **Einstein Lead/Opportunity Scoring needs history** — predictive models require a minimum volume of closed/converted records (hundreds+) `[volatile — verify live]` to train. Do not recommend it for a low-volume org with no history.
- **Distinguish predictive AI** (scoring, forecasting — needs training data) from **generative AI** (Einstein Copilot, email drafting — needs grounding data and guardrails, not training history).
- **Sales Engagement (formerly High Velocity Sales)** = cadences/call lists for high-throughput SDR teams — overkill for a low-volume org.
- The judgment this domain tests is recognizing when *not* to recommend a heavyweight feature. A low-volume org with sparse history should not invest in Einstein Scoring; a high-volume SDR team benefits from Sales Engagement cadences.

## Decision table

| Feature | Prerequisite | Skip when |
|---|---|---|
| Einstein Lead Scoring | Hundreds of converted leads with outcome data | Low lead volume, <6 months of history |
| Einstein Opportunity Scoring | Closed Won/Lost history, consistent stage usage | Stage data is inconsistent or org is new |
| Einstein Copilot (email drafting) | Grounding data (Contact/Account data quality) | PII/compliance concerns not yet addressed |
| Sales Engagement | High-volume SDR team, defined cadences | Low-volume account-based sales motion |
