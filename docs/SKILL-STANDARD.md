# The Skill Standard — 12 Dimensions of a Publish-Grade Expert Skill

Every skill in this repo is scored against these 12 dimensions. They define the *ceiling*;
[`salesforce/skills/salesforce-administrator/SKILL.md`](../salesforce/skills/salesforce-administrator/SKILL.md)
is the *floor* for depth and tone. The structural shape that satisfies them is in
[`TEMPLATE.md`](../TEMPLATE.md); how a skill is exercised against them is in
[`ASSESSMENT.md`](ASSESSMENT.md); how findings flow back is in [`LEARNING-LOOP.md`](LEARNING-LOOP.md).

## Scoring

Each dimension scores **0–3**: `0` absent · `1` present but weak · `2` solid · `3` exemplary.

> **Publish bar: no dimension below 2, and total ≥ 28/36.**

A static audit (Lens 1 in [ASSESSMENT.md](ASSESSMENT.md)) records a score **plus one line of
evidence** per dimension in the skill's scorecard (`evals/scorecards/<skill>.md`).

---

## D1 — Trigger precision
The `description` frontmatter is the only always-loaded text. It leads with **task vocabulary**
(the words an agent doing the real work has in context — "LWC wire adapter," not "JavaScript
Developer I"), states explicit use-when conditions, and ends with a scope boundary naming
sibling skills. ≤ ~600 chars. Cert framing lives in `metadata:` only.
**3:** a realistic task phrase matches exactly one skill across the whole marketplace, and it's the right one.

## D2 — Scope contract
A **Scope** block near the top: *load-when* / *not-this-skill* (with sibling pointers) /
*assumed context* (what the project must provide — credentials, org access, runtime). The 13
Salesforce skills tile without gaps or double-claims.
**3:** an agent can decide load/skip/route from the Scope block alone, without reading the body.

## D3 — Operational depth
Rules carry the **mechanism**, not just the imperative — why it fails, the exact limit/number,
the error message it produces. Textbook facts the base model already knows don't earn tokens;
only the non-obvious operational layer does (the admin skill's SFDX-FLS and QA-cache scars are the bar).
**3:** a domain expert reads it and says "yes, including the part most practitioners learn the hard way."

## D4 — Decision support
Every genuine fork has a decision table or explicit criteria (tool A vs B, pattern X vs Y) with
the constraint that drives the choice — never "it depends" without naming the dimensions it depends on.
**3:** for any realistic in-scope choice, the skill produces a defensible pick plus the reason.

## D5 — Failure-mode coverage
Per section: **Red flags** (what wrong looks like in review) and named anti-patterns with the
plausible-but-wrong reasoning that produces them. Scars include trigger + mechanism + fix + **how
to detect it already happened**.
**3:** covers not just "don't do X" but "here's how X sneaks in anyway and how you catch it."

## D6 — Verification discipline
Every section ends with portable verify steps: concrete queries/commands in tool-agnostic form
with fallbacks (project MCP → vendor CLI → vendor UI). Never "verify carefully."
**3:** every verify step is copy-runnable in an arbitrary project with standard vendor tooling.

## D7 — Uncertainty & escalation behavior
The skill tells the agent what to do at the edge of its knowledge:
- **Always re-verify live:** which classes of fact (limits, prices, API/runtime versions,
  anything marked volatile).
- **Live wins:** when the skill and the live system disagree, the live system is authoritative —
  then flag the skill as stale via the Feedback Protocol ([LEARNING-LOOP.md](LEARNING-LOOP.md)).
- **Escalate to a human:** irreversible/destructive ops, security-boundary changes, anything
  with compliance or spend implications — surface, don't silently decide.
- **Confidence taxonomy:** each fact is implicitly *stable* unless marked `[volatile — verify
  live]` or `[opinion — house style]`.
**3:** the agent degrades gracefully — it knows when it doesn't know, and never silently overrides live reality with skill text.

## D8 — Executable workflows
For the 2–4 highest-frequency multi-step operations in the domain, a numbered end-to-end
checklist with **verify gates between steps** (e.g. Salesforce "add a field end-to-end:
create → FLS → layout → permset deploy → cache-bust → verify query"). These convert knowledge
into procedure — the thing a certified professional has that a well-read generalist doesn't.
**3:** an agent executes the workflow start-to-finish without leaving the checklist, and each gate catches the common failure at that step.

## D9 — Teaching scenarios
≥4 original decision scenarios in POLICY format (Situation → Competent move → Tempting-but-wrong
→ Verify), targeting the forks where a smart generalist takes the wrong branch. **Zero overlap**
with the held-out eval set.
**3:** each scenario probes a different section's hardest judgment call.

## D10 — Context economy
Body ≤ ~3,500 words; every loaded token serves on-the-job competence. No exam logistics in the
body. Deep detail lives in `references/` with explicit load cues. Quick Reference carries
one-line imperatives only — explanations live in their section once.
**3:** nothing in a body-only load is noise for a project task, and nothing essential requires a reference load.

## D11 — Freshness & provenance
Frontmatter has `last-reviewed: YYYY-MM-DD` (and `blueprint-verified:` where a cert applies).
Volatile facts marked inline per D7. A **Changelog** section (or `references/changelog.md`)
records what changed and why — field-feedback-driven changes cite the feedback entry.
**3:** a reader can tell exactly how stale any claim might be and where each scar came from.

## D12 — Measurability
The held-out eval (`evals/<name>/`) has ≥12 scenarios whose coverage maps to the skill's
sections (each major section ≥1 probe); recorded results exist in the scoreboard; the eval
probes the skill's newest content so lift is measured on what was added, not what the base model
already knew.
**3:** eval results localize a content gap to a specific section.

---

## Total

`/36`. Publish-ready = **min dimension ≥ 2 AND total ≥ 28**. Below that, the lowest dimensions
become inbox items ([LEARNING-LOOP.md](LEARNING-LOOP.md)) prioritized for the next content pass.
