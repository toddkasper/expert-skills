# Node.js — Study Resources

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the OpenJS Node.js certifications or deepening Node.js operational knowledge.

## Certification Status (as of June 2026)

**Both JSNAD and JSNSD were retired September 30, 2025** by the Linux Foundation / OpenJS Foundation. As of June 2026, no official successor certification has been announced. The Linux Foundation's OpenJS candidate resources page still lists the two exams but links to inactive pages. Check https://training.linuxfoundation.org/openjs/ for any new programs.

Despite retirement, the domain curriculum remains an excellent competence map for Node.js practitioners — the topics tested are exactly what production Node.js engineers must master.

## Official Documentation (Primary References)

- [Node.js Official Docs](https://nodejs.org/en/docs/) — authoritative API reference; organized by module (`fs`, `stream`, `events`, `child_process`, `worker_threads`, etc.)
- [Node.js Guides / Learn](https://nodejs.org/en/learn) — narrative how-tos including event loop, streams, backpressure, debugging, diagnostics
- [Backpressuring in Streams](https://nodejs.org/learn/modules/backpressuring-in-streams) — canonical explanation of `highWaterMark`, `drain`, and `pipeline()`
- [Node.js ECMAScript Modules docs](https://nodejs.org/api/esm.html) — `"type":"module"`, named exports, `createRequire`, conditional exports
- [Node.js Diagnostics / Debugging](https://nodejs.org/en/docs/guides/debugging-getting-started) — `--inspect`, `--inspect-brk`, Chrome DevTools integration
- [npm Documentation](https://docs.npmjs.com/) — `package.json` fields, semver, `npm ci`, `npm audit`, workspaces

## OpenJS Certification Resources (Archived)

- [JSNAD Candidate Handbook (Linux Foundation)](https://training.linuxfoundation.org/openjs/) — candidate resources hub; Handbook PDF contains the definitive domain list
- [OpenJS FAQ (archived)](https://docs.linuxfoundation.org/tc-docs/certification/faq-openjs) — passing score (68%), retake policy, allowed resources during exam
- [nodecertification.com — Hey Node study guide](https://www.nodecertification.com/) — community-maintained domain breakdown with exercises; still accurate as a learning guide even post-retirement
- [JSNAD: My Experience and Advice — Komelin](https://komelin.com/blog/nodejs-certification-my-experience-advice) — first-hand exam experience including format details
- [JSNSD exam review — abba.dev](https://abba.dev/blog/jsnsd-exam/) — JSNSD-specific walkthrough; covers allowed resources (Node.js docs allowed; StackOverflow blocked)

## Courses and Interactive Learning

- [Node.js Application Development (LFW211)](https://training.linuxfoundation.org/training/nodejs-application-development-lfw211/) — Linux Foundation course aligned to JSNAD domains; now available independently
- [Node.js Services Development (LFW212)](https://training.linuxfoundation.org/training/node-js-services-development-lfw212/) — Linux Foundation course aligned to JSNSD; REST, Fastify, security
- [The Node.js Book — thenodebook.com](https://www.thenodebook.com/) — deep dives on streams, readable modes, buffers, backpressure internals

## Security References

- [OWASP Node.js Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Nodejs_Security_Cheat_Sheet.html) — canonical input validation, injection prevention, and security header guidance
- [Express.js Production Security Best Practices](https://expressjs.com/en/advanced/best-practice-security/) — Helmet, CORS, rate-limiting, TLS guidance with code examples
- [Better Stack — Securing Node.js Applications](https://betterstack.com/community/guides/scaling-nodejs/securing-nodejs-applications/) — practical guide covering auth, rate limiting, secrets management

## GitHub Study Repositories

- [openjs-nodejs-application-developer-study-guide](https://github.com/Node-Study-Guide/openjs-nodejs-application-developer-study-guide) — community notes and exercises mapped to JSNAD domains
- [JoseJPR/nodejs-certification](https://github.com/JoseJPR/nodejs-certification) — code examples organized by domain; useful for hands-on practice

## Complementary Skills in This Library

- `typescript` — TypeScript with Node.js; type-safe modules, declaration files, `ts-node`
- `react` — React server-side rendering patterns that run on Node.js; use the `react` skill for React specifics
- `nextjs` (sibling skill) — Next.js API routes and server components run on Node.js; defer Node.js fundamentals here
- `react-native` — mobile runtime; not Node.js server-side; defer to that skill
