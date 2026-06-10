# SFMC Insights & Analytics — Operational Detail

> Load this file when building dashboards, diagnosing deliverability trends, or writing engagement-suppression queries. Moved from SKILL.md §5 to keep body ≤ ~4,500 words.

## Metric definitions

- **Delivered** = Sent − Hard Bounces
- **Open Rate** = Unique Opens / Delivered
- **Click-to-Open Rate (CTOR)** = Unique Clicks / Unique Opens (the truest engagement signal)
- **Click Rate** = Unique Clicks / Delivered
- **Bounce Rate** = Total Bounces / Sent
- **Unsubscribe Rate** = Unsubscribes / Delivered
- **Spam Complaint Rate** = Complaints / Delivered (keep < 0.1%) `[volatile — verify live]`
- **Measures** are numeric/aggregated (total unsubs/30d); **Dimensions** are categorical (domain, date, region). Reports cross a Measure with a Dimension.
- **Open tracking is pixel-based** → inflated/unreliable since Apple Mail Privacy Protection pre-fetches pixels. **Lean on clicks/CTOR, not opens**, for true engagement and re-engagement suppression decisions.

## Reports — which one answers which question

| Question | Report |
|---|---|
| How did all sends perform this month? | Account Send Summary |
| How did one campaign do? | Campaign Email Tracking |
| Is Gmail throttling us vs. Yahoo? | Email Performance by Domain |
| Are we trending up or down? | Email Performance Over Time |
| What did this one person do? | Subscriber Engagement |
| Why are bounces up? | Bounce Summary |
| Are we getting spam complaints? | Spam Complaint Report |

## Raw event-level analysis

For raw event-level analysis, use **Tracking Extracts** (Automation Studio → SFTP) or **SQL Query** against Data Views into a DE. To re-engage, query `_Click` for no activity in N days → suppression DE:

```sql
SELECT SubscriberKey
FROM _Subscriber s
WHERE s.Status = 'Active'
  AND s.SubscriberKey NOT IN (
    SELECT SubscriberKey FROM _Click
    WHERE EventDate > DATEADD(day, -90, GETDATE())
  )
```

Data Views retain ~6 months of data by default `[volatile — verify live]` — for longer history, extract to a DE on a schedule via Automation Studio.
