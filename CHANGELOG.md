# Changelog

Repo-level history. Per-skill changes live in each `SKILL.md`'s `## Changelog`; per-plugin
versions live in `marketplace.json` / `.claude-plugin/plugin.json` (semver convention in
[CONTRIBUTING.md](CONTRIBUTING.md)).

## 2026-06-10 — Legal/IP hardening + project polish + Cycle-2 curation
_Versions: `salesforce-skills` 0.3.0; `aws-skills` / `github-skills` / `web-skills` 0.2.0._

- **Cycle-2 curation (learning loop):** integrated 23 Lens 3–5 findings — salesforce-administrator
  (External ID 7→25, group tasks 200→100, web-to-lead/case overflow = pending queue, WFR/PB
  "retired"→end-of-support, Lightning App Builder coverage, Flow fault paths, Recycle Bin 30-day
  Extended Retention, Agentforce 360 naming), react (useTransition→useDeferredValue for controlled
  inputs **+ the matching answer-key #6 defect**, useEffectEvent/Activity/use()/ref-as-prop for
  React 19.2, React Foundation trademark), aws-security-specialty (Security Hub CSPM split, RCP
  Nov-2024 + service scoping, Domain-1 logging, GuardDuty ETD, Firewall Manager→Config, S3 BPA
  rationale). Six held-out eval scenarios added per skill (situations 12→18). run-eval.md
  hardened: 3-judge panel, per-scenario blinded A/B grading, solver fence excluding
  scorecards/RESULTS.
- **Plugin rename (breaking):** plugin identifiers → `salesforce-skills` / `aws-skills` /
  `github-skills` / `web-skills`; displayNames retitled to the "…(unofficial)" pattern;
  non-affiliation framing added throughout. Install commands and skill namespaces change
  accordingly (e.g. `/salesforce-skills:salesforce-administrator`).
- **Self-contained plugins:** `POLICY.md` + `LICENSE` copied into each plugin dir; the
  non-affiliation disclaimer inlined into every plugin README.
- **Disclaimer coverage:** held-out header on all 88 eval files; disclaimer footer on all
  `references/*.md` (validator-enforced); standardized "no certification outcome" line.
- **Metadata:** `credential:` → `anchor-credential:` across all skills + TEMPLATE.
- **Docs/validator coherence:** TEMPLATE gains the four standard sections + single-line
  `description` example; description ceiling unified at 750; validator adds reference-disclaimer
  and orphaned-eval/scorecard reverse checks; CONTRIBUTING.md added; CI hardened (jq +
  shellcheck, push/PR dedupe); skill-feedback issue form added.

## 2026-06-09 — Project-grade upgrade + self-improving standard (PR #1)
- Retargeted all 22 descriptions; evicted exam logistics to `references/study-resources.md`;
  made verify steps tool-agnostic; de-org-ified the generic Salesforce skills; standardized the
  anatomy (`TEMPLATE.md`) and right-sized large bodies; brought every skill to ≥ 4 scenarios.
- Added the standard/assessment/learning-loop docs, the eval harness (`run-eval.md`,
  `RESULTS.md`, scorecards, `triggers.md`/`tasks.md`), `scripts/validate.sh` + CI, and
  `scripts/harvest-feedback.sh`.
- Ran the first assessment cycle (Lens 1 + 2) and cured the 8 rubric findings it surfaced.

## 2026-06-07 — Initial public release
- 22 expert skills (salesforce ×13, aws ×3, github ×1, web ×5) with held-out evals and the
  POLICY/EVALS governing docs.
