# Advanced Features Reference

> Loaded on demand from the GitHub Actions skill body. Sections here are linked from the SKILL.md body with explicit load cues.

## Action Types

| Type | Runtime | Best for | Key file |
|---|---|---|---|
| JavaScript | Node.js (on runner, no container spin-up) | Fast, cross-OS, access to Actions toolkit | `action.yml` + `index.js` (or compiled dist/) |
| Docker | Container | Custom OS/tools, Python/Ruby/compiled binaries | `action.yml` + `Dockerfile` |
| Composite | YAML steps, no container | Wrapping a sequence of steps/shell commands | `action.yml` with `runs.steps` |

**Immutable actions on GitHub-hosted runners:** GitHub has been rolling out enforcement that actions pinned to a tag are resolved against an immutable copy in the GitHub Container Registry (GHCR), not the live repo at that tag. This means floating tags (`@v3`) can no longer silently pick up new commits pushed to that tag — you get the GHCR snapshot. Implication: pin to a full commit SHA for exact reproducibility; use a tag for convenience only when you trust the publisher's release process.

## Action Versioning and Publishing

- **Semantic tags + SHA pin:** tag releases (`v1`, `v1.2`, `v1.2.3`); move major version tags (`v1`) to point at the latest patch. Callers pin to `v1` for auto-updates within major, or to a full SHA for exact reproducibility.
- **Marketplace publication:** the action repo must be public; `action.yml` must be at the repo root; Marketplace listing requires a description, icon, and color. A `README.md` is expected for discoverability.
- **Private actions:** reference directly as `uses: org/private-repo/.github/actions/my-action@ref` — accessible if the calling repo has read access. No Marketplace publication needed.

## YAML Reuse within a File

YAML anchors (`&anchor`), aliases (`*anchor`), and merge keys (`<<: *anchor`) reduce repetition within a single workflow file. They are **not** cross-file; for cross-workflow reuse, use reusable workflows or composite actions.

## Artifact Attestations (SLSA Provenance)

Actions supports generating signed provenance attestations (SLSA Build L2+) via `actions/attest-build-provenance`. This creates a verifiable record linking a build artifact to the workflow run that produced it. Consumers can verify attestations before deploying using `gh attestation verify`. Use this for release artifacts and container images in security-sensitive pipelines.

**Required permission:** `attestations: write` (in addition to `id-token: write` for the signing step).

**Verify:** `gh attestation verify <artifact-path> --repo <owner>/<repo>` — returns the signing workflow run details; a failed verification means the artifact was not produced by the expected workflow.
