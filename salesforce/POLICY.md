# Purpose & Content Policy

## What this library is

A collection of **agent skills** that upskill AI agents with specialized, operational
domain knowledge — the working competence a credentialed practitioner actually applies on
the job. Each skill (e.g. `salesforce-administrator`, under `salesforce/skills/`)
gives an agent the rules, decision criteria, real limits, and anti-patterns that an expert
in that domain uses, in the [`SKILL.md`](https://agentskills.io) open format.

**The goal:** when a task calls for a "certified Salesforce administrator" — or, soon, an
AWS solutions architect — an agent can load the matching skill and operate with that
specialized knowledge.

## What this library is NOT

- **Not test-prep, and never a "braindump."** These are not exam questions or answer keys.
  We use certification *blueprints* only as a public map of **what a competent practitioner
  must know** — a coverage checklist — never as a source of exam content.
- **Not a credential.** A skill imparts knowledge; it does **not** mean the agent or user
  *holds* the certification, passed an exam, or is endorsed by the vendor.
- **Not official, not ground truth.** These files are guidance. Live systems and official
  vendor documentation are the source of truth.
- **Certification is the scaffold and benchmark — not the product.** We use certification
  blueprints to decide *coverage* (what a competent practitioner must know) and to *benchmark*
  the skills (the evals in [EVALS.md](EVALS.md)). The product is **AI competence**. These skills
  do not replace, prepare you for, or confer any certification — the certification is simply how
  the competence is scoped and measured.

> We are upskilling agents with specialized knowledge. We are **not** teaching a test.

## The "keep it safe" rules

Every skill in this repo must follow these. They keep the library legally clean, useful,
and something the vendors whose domains we cover would have no reason to object to.

1. **100% original.** Write everything in our own words. Never copy verbatim from
   copyrighted sources — vendor exam guides, product documentation, paid courseware. Link
   to official sources; do not reproduce them.
2. **Never include real exam questions.** No leaked items, "dumps," or "real questions."
   Using actual certification questions violates vendor agreements and can void credentials.
   Original, scenario-style examples that *we* author are fine; copied questions are not.
3. **Competence, not credential.** Frame a skill as "the knowledge a certified X applies,"
   never "this agent is a certified X." Claim no credential, no passing, no endorsement.
4. **Nominative trademark use + disclaimer.** "Salesforce," "AWS," "Certified …" and the
   like are trademarks of their owners, used here only to identify the subject matter.
   Ship the disclaimer below; never use vendor logos.
5. **Guidance, not ground truth.** Every skill instructs the agent to verify against live
   systems and official docs before acting. Mark volatile facts (governor limits, blueprint
   weights, fees, exam codes) as subject to change.
6. **Current and honest.** Mark retired or renamed credentials. Fix stale numbers. Don't
   overstate coverage — note known gaps rather than imply completeness.

## Authoring practice content (decision scenarios)

The aim is to sharpen an agent's *judgment*, not to drill a human for a multiple-choice test.
So skills do **not** contain exam-style multiple-choice questions. When a skill needs practice
material, author **decision scenarios** instead.

**Sourcing** (this is rules #1–#2 applied):
- Write every scenario yourself, in your own words.
- Scaffold coverage from the **free official exam blueprint** (the domain list + weights) so the
  set is complete — blueprints describe *what* is tested, not test content.
- **Never** copy from real or leaked exam questions ("braindumps"), paid question banks, or a
  vendor's published sample questions. Link to official samples; never reproduce them.

**Format** — each scenario:

> **Situation:** a concrete, realistic case.
> **Competent move:** what an expert does, and the rule behind it.
> **Tempting-but-wrong:** the plausible mistake, and *why* it fails.
> **Verify:** how to confirm against the live system or official docs.

Keep them concrete and a handful per major domain. Put them in `SKILL.md`, or in a
`references/scenarios.md` if they grow large.

## Adding a new skill — checklist

- [ ] Folder slug is `vendor-role` (e.g. `salesforce-administrator`, `aws-solutions-architect`); the `SKILL.md` `name` field matches the folder name exactly.
- [ ] Content is original — no copied exam-guide or documentation text, **no real exam questions**.
- [ ] Any practice content is original **decision scenarios** (Situation → Competent move → Tempting-but-wrong → Verify), scaffolded from the free blueprint — never copied questions.
- [ ] Framed as competence ("what a certified X knows and does"), with explicit "verify against live systems / official docs" guidance.
- [ ] Exam/blueprint facts are cited to a **free official source** and marked subject to change.
- [ ] The disclaimer below applies (covered repo-wide by this file; add it to the skill itself if it will be distributed individually).
- [ ] Before publishing, the skill passes its eval — **≥85% skilled pass rate and positive lift** over baseline (see [EVALS.md](EVALS.md)).

## Disclaimer

> This is independent educational content for upskilling AI agents. It is **not affiliated
> with, authorized by, endorsed by, or sponsored by** Salesforce, Amazon Web Services, or
> any certification body. All product names, logos, and brands — including "Salesforce
> Certified …" and "AWS Certified …" — are the property of their respective owners and are
> used here for identification purposes only. Content is provided as-is, as guidance only;
> verify against official documentation and live systems. No certification outcome is
> implied or guaranteed.
