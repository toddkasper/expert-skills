# The Continuous Learning Loop

Three feedback sources feed one curation pipeline. Design principle: **capture at the point of
use, integrate at the point of truth.** Skills travel into projects that have no write access to
this repo, so capture must be project-local and harvesting must be explicit.

```
        FIELD USE                EVALS (Lenses 3–4)         AUDITS (Lenses 1,2,5)
  agent hits a gap/error      failed/partial scenarios        findings lists
            │                         │                            │
            ▼                         ▼                            ▼
  .skill-feedback/<skill>.md   evals/RESULTS.md gaps      feedback/INBOX.md
            │                         │                            │
            └──────────── harvest ────┴────────────────────────────┘
                                      │
                              CURATION PASS (per skill)
                 validate vs official docs → accept/reject each item
                                      │
            ┌─────────────────────────┼──────────────────────────┐
            ▼                         ▼                          ▼
   integrate into SKILL.md   author NEW held-out eval     changelog entry +
   (rule/scar/red flag/      scenario probing the         last-reviewed bump
    workflow gate)           lesson (keep held-out!)
                                      │
                                      ▼
                        re-run Lens 2 + 3 (+4 if content moved)
                        scoreboard updated → publish
```

---

## C1 — Field feedback capture (the skill instructs its own correction)

Every `SKILL.md` carries a **Feedback Protocol** footer (above the disclaimer). It tells the
using agent to append, *in the moment*, an entry to `.skill-feedback/<skill-name>.md` at the
**project root** (created if absent) when it finds a claim contradicted by reality, a missing
rule that cost a wrong attempt, or a decision the skill gave no criteria for. Format:

```
date | skill last-reviewed | claim or gap | what was observed instead | evidence (error/doc URL/query output) | suggested fix
```

This needs zero infrastructure in the consuming project — it works in Claude Code, Cowork, and
CI agents alike. **Optional upgrade (for your own projects, not required of the skill):** a
Claude Code `Stop` hook or a `/skill-retro` command that prompts the agent to review the session
and write the entries. Skills must never *depend* on that hook.

## C2 — Harvest & inbox

[`../feedback/INBOX.md`](../feedback/INBOX.md) is the single repo-level intake queue (one table:
date, skill, source [field/eval/audit], summary, evidence link, status). `scripts/harvest-feedback.sh`
collects `.skill-feedback/*.md` entries from one or more project paths into the inbox with
dedupe. **Eval failures (Lens 3–4) and audit findings (Lens 5) are filed into the same inbox** —
exactly one queue.

## C3 — Curation pass (the only way content changes)

This is an agent-executable protocol. For one skill:

1. **Validate.** Take all inbox items for the skill. Check each against official docs / a live
   system — field reports can be wrong, project-specific, or already fixed upstream. **Reject
   with a reason or accept.** Mark the inbox row.
2. **Integrate.** For each accepted item, choose the integration type: corrected fact, new scar
   (trigger + mechanism + fix + detection), new red flag, new decision-table row, new workflow
   gate, or new `[volatile]` marking. Place it at the right point in the body, respecting the
   D10 token budget — something may move to `references/` to make room. **Never delete an
   existing rule to make room; relocate it.**
3. **Close the loop into measurement.** Author **one new held-out eval scenario** probing the
   lesson, into `evals/<skill>/situations.md` + `answer-key.md`, so the fix is regression-tested
   forever. Never copy the teaching text into the eval or vice versa (POLICY + EVALS held-out rule).
4. **Record.** Add a Changelog entry citing the inbox item; bump `last-reviewed`; set the inbox
   row to `integrated`.
5. **Re-measure.** Re-run Lens 2 (triggers) and Lens 3 (+4 if the change was substantial);
   update the scorecard and [`../evals/RESULTS.md`](../evals/RESULTS.md).

**Cadence:** event-driven per skill when its inbox has **≥3 items or any severity-high item**;
otherwise a quarterly sweep aligned with the Lens 5 audit. Most quarters, most skills need
nothing — that keeps the loop cheap.

## C4 — Scoreboard & trend

[`../evals/RESULTS.md`](../evals/RESULTS.md) keeps **one row per assessment run** (history
preserved): knowledge baseline/skilled/lift, application baseline/skilled/lift, rubric total,
trigger pass rate, status. A skill whose lift trends toward zero is restating what models now
know natively — the signal to **deepen (new scars) or retire content**, not to celebrate.

---

## Worked micro-example (loop dry-run)

> A field agent, using `aws-security-specialty`, writes to `.skill-feedback/aws-security-specialty.md`:
> `2026-06-20 | 2026-06-09 | "GuardDuty publishes findings every 6 hours" | console showed near-real-time | screenshot | soften to "frequency varies; verify in console"`.
> Harvest pulls it to INBOX. Curation validates against AWS docs → finding-frequency is not a
> fixed SLA → accept, mark the claim `[volatile — verify live]`, add a Changelog line citing the
> entry, bump `last-reviewed`, author one new held-out eval probe ("an agent assumes a fixed
> GuardDuty cadence — what should it do?"), re-run Lens 2+3. Inbox row → `integrated`.

If walking a real report through these steps reveals a step the doc didn't cover, that gap is
itself an inbox item against this document.
