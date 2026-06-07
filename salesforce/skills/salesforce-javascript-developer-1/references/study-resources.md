# JavaScript Developer I — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the JavaScript Developer I exam or mapping the operational rules to a nonprofit (NPSP) org.

## Study Resources

### Official Salesforce / Trailhead

- [Study for the Salesforce JavaScript Developer I Exam (Trail)](https://trailhead.salesforce.com/content/learn/trails/study-for-the-salesforce-javascript-developer-i-exam) — Official 3-module trail with interactive flashcards and scenario questions; covers all 7 domains (~40 min, 800 points). Start here.
- [Prepare for your Salesforce JavaScript Developer I Credential (Trailmix)](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-javascript-developer-i-credential) — Salesforce's official curated trailmix (~32 hours of content)
- [JavaScript Skills for Salesforce Developers (Module)](https://trailhead.salesforce.com/content/learn/modules/javascript-essentials-salesforce-developers) — Salesforce-contextualized JS fundamentals
- [Lightning Web Components Specialist (Superbadge)](https://trailhead.salesforce.com/content/learn/superbadges/superbadge_lwc_specialist) — Required second component of the credential; 16 hands-on coding challenges (~14–30 hours)
- [Salesforce Certified JavaScript Developer — Credential Page](https://trailhead.salesforce.com/credentials/javascriptdeveloperi) — Official credential overview and exam registration link

### Community Study Guides & Practice Exams

- [Focus on Force — JavaScript Developer 1 Study Guide](https://focusonforce.com/salesforce-javascript-developer-1-study-guide/) — Paid study guide covering all 7 exam domains with videos, diagrams, and code examples; considered one of the most thorough third-party options
- [Focus on Force — JavaScript Developer 1 Practice Exams](https://focusonforce.com/salesforce-javascript-developer-1-certification-practice-exams/) — 150+ practice questions with explanations; mirrors the real exam's code-reading question style
- [Salesforce Ben — JavaScript Developer I Certification Guide & Tips](https://www.salesforceben.com/javascript-developer-i-certification-guide-tips/) — Free overview article with study strategy, resource links, and exam tips from a certified community expert
- [Salesforce JavaScript Developer I: 300+ Questions (Udemy)](https://www.udemy.com/course/salesforce-javascript-developer-1/) — Popular paid practice exam set with 6 full-length mock exams; highly rated

### Core JavaScript References (used by official Trailhead modules)

- [MDN Web Docs — JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript) — The authoritative browser-side JavaScript reference; covers every built-in, DOM API, and event system detail tested on the exam
- [JavaScript.info](https://javascript.info/) — Free, structured tutorial covering all exam domains with clear code examples; the official Trailhead prep modules link directly to specific javascript.info pages
- [You Don't Know JS (GitHub)](https://github.com/getify/You-Dont-Know-JS) — Free book series by Kyle Simpson; deep-dives on scope, closures, `this`, and async — the concepts most frequently tested
- [Jest — Getting Started](https://jestjs.io/docs/en/getting-started) — Official Jest docs; focus on matchers, mocking, and async testing patterns for the Testing topic

## Relevance to NPSP & Nonprofit Cloud

The JavaScript Developer I certification is directly applicable to NPSP / Nonprofit Cloud
development. The JS surface on many nonprofit projects is a mix of React/front-end, Node
Lambda/back-end, and SFDX scripts in addition to LWC, but the rules above are identical
across all of them.

### LWC Components for Nonprofit Staff Workflows

NPSP and Nonprofit Cloud provide standard objects and flows, but nonprofit orgs routinely
need custom UI — donor portals, volunteer check-in, grant dashboards, or application intake.
The **Objects, Functions, Classes** and **Browser and Events** rules map directly to LWC
authoring: `@api`/`@track`/`@wire` are the same decorators used in every LWC; child→parent
custom-event bubbling is the same pattern used by multi-step form steps emitting events upward.

### Asynchronous Apex Integration

`@wire` adapters and imperative Apex calls both return Promises. Correct `async/await` with
`try/catch` and `Promise.all` fan-out for independent SOQL is the difference between a
component that fails silently and one that shows useful error states — and the difference
between N×latency and 1×latency.

### Testing LWC Components with Jest

`@salesforce/sfdx-lwc-jest` runs LWC unit tests in Node with no live org. The exam's emphasis
on `jest.fn()` and `jest.mock()` maps to mocking `@salesforce/apex` imports and wire adapters —
the same discipline applied to boundary-case unit suites elsewhere in a project.

### Node.js for Build Tooling and Automation

The **Server-Side JavaScript** rules cover npm, `package.json`, and core modules — the exact
toolchain behind SFDX CI/CD scripts, schema-sync utilities, smoke tests, and the test runner.

### Debugging Integration Issues

The **Debugging and Error Handling** rules apply the moment a Salesforce REST call returns an
unexpected status, a JWT auth fails, or a validation error propagates wrong through the
back-end chain — read the stack trace, log structured (PII-free), and `try/catch` around
`await`.

### Specific NPSP Topic Mapping

| Cert Topic | NPSP/Nonprofit Cloud Application |
|---|---|
| Objects, Functions, Classes | LWC components for donor, volunteer, and constituent-facing UIs |
| Browser and Events | Custom event patterns between LWC child/parent components |
| Asynchronous Programming | `@wire` + imperative Apex; `Promise.all()` for parallel SOQL |
| Testing | `@salesforce/sfdx-lwc-jest` unit tests for custom NPSP components |
| Server-Side JavaScript | npm/Node toolchain for SFDX CI/CD scripts and schema sync |
| Debugging and Error Handling | Salesforce API error handling in Lambda and LWC error boundaries |
| Variables, Types, Collections | JSON parsing of NPSP API responses; array manipulation for list views |
