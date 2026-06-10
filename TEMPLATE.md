# Skill Anatomy Template

The canonical shape every `SKILL.md` in this repo follows. It exists so skills are
predictable to load, easy to review, and uniformly useful when a project pulls one in. The
quality bar is [`salesforce/skills/salesforce-administrator/SKILL.md`](salesforce/skills/salesforce-administrator/SKILL.md) —
when in doubt about depth, tone, or structure, match it.

> This is a structural template, not a content source. Read [POLICY.md](POLICY.md) (content
> rules, disclaimer, competence-not-credential framing) and [EVALS.md](EVALS.md) (how the
> skill is measured) before authoring.

---

## 1. Frontmatter (YAML)

```yaml
---
name: vendor-role                      # MUST equal the folder name exactly — never rename
# description: ONE physical line (do NOT use YAML folded ">" — the tooling reads a single line).
# The only always-loaded text. ≤ ~750 chars. Three beats: (1) capability in task vocabulary —
# the words an agent doing the real work has in context (mine the section headings); (2) "Use
# when <writing/reviewing/debugging X, configuring Y, designing Z>"; (3) scope boundary naming
# the sibling skill that owns adjacent work ("Not <X> (see <sibling>)"). Cert framing appears
# ONLY as the final clause: "Scoped and benchmarked by the <cert> blueprint."
description: <capability in task vocabulary>. Use when <explicit triggers>. Not <out-of-scope> (see <sibling>). Scoped and benchmarked by the <cert> blueprint.
metadata:
  anchor-credential: <Credential the skill is scaffolded/benchmarked against, or "None — competence skill (no first-party cert)">  # the skill imparts competence; it does NOT confer this credential
  exam-code: <CODE>                    # omit if none; use exam-codes: A, B for multi-cert
  domain: <salesforce | aws | github | web>
  type: <certification-playbook | competence-playbook>
  status: <current | operational | active>      # REQUIRED
  last-reviewed: YYYY-MM-DD                       # REQUIRED — bump on every substantive edit
  blueprint-verified: YYYY-MM-DD                  # REQUIRED where a cert applies; omit for pure competence skills
---
```

**Rules**
- The `description` leads with task keywords, not the cert name. No exam code appears before
  the final clause. For the overlapping Salesforce skills, the scope boundary must
  *disambiguate* — a task should match exactly one obvious skill.
- All volatile facts (limits, versions, fees, exam codes, weights) are marked subject to
  change per POLICY §5. Logistics live in `references/study-resources.md`, not the body.

---

## 2. Body sections, in order

### H1 title
`# <Vendor Role> — Skills Reference`

### Overview (≤ 2 paragraphs)
What the role/credential covers, and one sentence stating this is an **operational playbook,
not an exam outline**. Optionally a "read first" note for a rename/retirement.

### Scope block (required)
A short block immediately after Overview, in this shape:

> **Load this skill when…** <2–4 concrete task triggers in the reader's words>.
> **Not this skill:** <adjacent task> → see `<sibling-skill>`; <another> → see `<sibling>`.

This is the disambiguation layer in the body (the description carries it for triggering; this
carries it for a reader who has already loaded the skill).

### Tooling-convention line (required)
One blockquote, near the top:

> **Verify steps assume nothing about your tooling** — use your project's MCP connection, the
> vendor CLI, or the vendor UI, in that order of preference.

### Credential-logistics pointer (cert skills)
One line: `Credential logistics and study path: see references/study-resources.md.`

### Uncertainty & Escalation (required)
A short `## Uncertainty & Escalation` section near the top (after the logistics pointer, before
section 1) with four beats: **Always re-verify live** (the domain's volatile fact classes);
**Live wins** (trust the live system over this file when they disagree → then log via the
feedback protocol); **Escalate to a human** (the domain's irreversible/destructive/security/spend
operations to surface, not execute); **Confidence taxonomy** (facts are stable unless tagged
`[volatile — verify live]` or `[opinion — house style]`). Apply a few inline `[volatile]` marks
to the most drift-prone facts in the body.

### Numbered domain sections
Mirror the blueprint domains (so the section list doubles as a coverage map). Each section
uses the **four-part rhythm**:

1. **Rules with mechanisms** — state the rule *and why it's true* (the mechanism), not just
   what. A rule without its mechanism doesn't transfer to a novel case.
2. **Decision table** — wherever a choice exists (tool A vs B, this limit vs that), a compact
   table with a decision column.
3. **Red flags** — the plausible-looking mistakes to catch in review.
4. **Verify** — how to confirm against the live system, tool-agnostic (MCP → CLI → UI), with
   the actual query/command preserved.

### Executable Workflows (required)
A `## Executable Workflows` section with 2–4 numbered end-to-end checklists for the domain's
highest-frequency multi-step operations, each fail-prone step carrying a verify **gate**
(`→ gate: <how you confirm before proceeding>`). These convert knowledge into procedure.

### Decision Scenarios (≥ 4)
Original scenarios in POLICY format — **Situation → Competent move → Tempting-but-wrong →
Verify**. They target the skill's highest-lift judgment calls (where a smart generalist takes
the wrong fork). They MUST NOT duplicate or mirror the held-out `evals/<skill>/situations.md`.
**Keep ≥ 4 in the body** (overflow may go to `references/scenarios.md` with a pointer, but a
body-only load must surface at least 4 — the rubric's D9 scores in-body scenarios).

### Operational Rules Quick Reference
A DO/DON'T imperative list. **Dedupe:** each rule's *explanation* lives in its section once;
the Quick Reference carries only the one-line imperative. A body-only load must still surface
the full DO/DON'T substance.

### References pointer
One line pointing at `references/` and what's there.

### Feedback protocol (required)
A `## Feedback protocol` section (above the disclaimer) telling the using agent to log
contradictions/gaps, in the moment, to a project-local `.skill-feedback/<skill-name>.md` in the
pipe-delimited format (`date | last-reviewed | claim/gap | observed | evidence | suggested fix`),
and that the live system wins over this file. This is the field-capture half of the learning loop.

### Changelog (required)
A `## Changelog` section recording dated, one-line entries of what changed and why —
field-feedback-driven changes cite the inbox item.

### Disclaimer
The POLICY disclaimer, naming the vendor marks used, ending with "No certification outcome is
implied or guaranteed." (cert skills).

---

## 3. Right-sizing

- **Target body: ~2,000–3,500 words.**
- Keep **every** operational rule, limit, scar, red flag, and verify step in the body.
- Move long worked explanations, extended tables, and niche sub-domain detail into
  `references/<topic>.md`, with an explicit **load cue** in the body:
  `Deep dive with worked examples: references/<topic>.md — load when <condition>.`
- **Never hollow a body out to a table of contents.** The DO/DON'T substance must survive a
  body-only load. If a rule only exists in a reference file, it was cut too deep.

---

## 4. References folder

- `references/study-resources.md` — credential logistics + study path + official links.
- `references/scenarios.md` — overflow decision scenarios (when the body is at budget).
- `references/<topic>.md` — deep dives extracted during right-sizing.
- **Every** `references/*.md` file must be linked from the `SKILL.md` (the validator enforces this).

---

## 5. Pre-publish checklist

- [ ] `name` == folder name; single-line `description` ≤ 750 chars, leads with task vocab, disambiguates.
- [ ] `anchor-credential`, `status`, `last-reviewed`, and (cert skills) `blueprint-verified` present.
- [ ] Overview + Scope block + tooling-convention line present.
- [ ] **Uncertainty & Escalation** section present (with inline `[volatile]` marks).
- [ ] Numbered sections follow rules→table→red-flags→verify; verify steps tool-agnostic.
- [ ] **Executable Workflows** section present (2–4 checklists with verify gates).
- [ ] ≥ 4 Decision Scenarios **in the body**, zero overlap with `evals/<skill>/situations.md`.
- [ ] Quick Reference deduped; body within budget; no operational rule lost.
- [ ] **Feedback protocol** + **Changelog** sections present; every `references/*.md` linked and carrying a disclaimer; disclaimer present.
- [ ] `scripts/validate.sh` exits 0; scorecard written; passes its eval (≥85% skilled, positive lift) per EVALS.md before publish.
