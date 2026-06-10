# Feedback Inbox

The single intake queue for the continuous learning loop ([../docs/LEARNING-LOOP.md](../docs/LEARNING-LOOP.md)).
Three sources file here: **field** (harvested `.skill-feedback/*.md` from consuming projects, via
`scripts/harvest-feedback.sh`), **eval** (failed/partial Lens 3–4 scenarios), and **audit**
(Lens 1/2/5 findings). Curation validates each item against official docs, then integrates,
rejects (with reason), or defers.

Status legend: `new` · `validated` · `rejected` · `integrated`.

> **Cycle 1 (2026-06-09):** the 8 audit findings below were all validated against the standard
> and **integrated** the same day via the curation pass — 7× D9 (inlined ≥4 decision scenarios
> into the body) and 1× D10 (moved niche detail to references). See each skill's `## Changelog`
> and updated scorecard. This is the learning loop run end-to-end on its own first findings.

| Date | Skill | Source | Severity | Summary | Evidence | Status |
|---|---|---|---|---|---|---|
| 2026-06-09 | salesforce-experience-cloud-consultant | audit | high | D9=1: all 5 decision scenarios deferred to references; body has 0 inline → fails publish bar | scorecards/salesforce-experience-cloud-consultant.md | integrated (curation 2026-06-09) |
| 2026-06-09 | salesforce-business-analyst | audit | high | D10=1: body 5,086 words (>5,000) → fails publish bar; trim Quick Reference + niche prose | scorecards/salesforce-business-analyst.md | integrated (curation 2026-06-09) |
| 2026-06-09 | aws-devops-engineer-professional | audit | high | D9=1: only 1 inline scenario (5 in references) → fails publish bar | scorecards/aws-devops-engineer-professional.md | integrated (curation 2026-06-09) |
| 2026-06-09 | aws-security-specialty | audit | high | D9=1: only 1 inline scenario (5 in references) → fails publish bar | scorecards/aws-security-specialty.md | integrated (curation 2026-06-09) |
| 2026-06-09 | aws-solutions-architect-professional | audit | high | D9=1: only 1 inline scenario; D3=2 (body-only depth thinned by §4 reference moves) | scorecards/aws-solutions-architect-professional.md | integrated (curation 2026-06-09) |
| 2026-06-09 | github-actions | audit | high | D9=1: only 1 inline scenario; D1/D2=2 (no sibling slugs — structural, no GH sibling exists) | scorecards/github-actions.md | integrated (curation 2026-06-09) |
| 2026-06-09 | react | audit | high | D9=1: only 1 inline scenario (4 in references) → fails publish bar | scorecards/react.md | integrated (curation 2026-06-09) |
| 2026-06-09 | react-native | audit | high | D9=1: only 1 inline scenario (5 in references) → fails publish bar | scorecards/react-native.md | integrated (curation 2026-06-09) |
