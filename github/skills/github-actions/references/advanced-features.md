# Advanced Features Reference

> Loaded on demand from the GitHub Actions skill body.

## YAML Reuse within a File

YAML anchors (`&anchor`), aliases (`*anchor`), and merge keys (`<<: *anchor`) reduce repetition within a single workflow file. They are **not** cross-file; for cross-workflow reuse, use reusable workflows or composite actions.

## Artifact Attestations (SLSA Provenance)

Actions supports generating signed provenance attestations (SLSA Build L2+) via `actions/attest-build-provenance`. This creates a verifiable record linking a build artifact to the workflow run that produced it. Consumers can verify attestations before deploying using `gh attestation verify`. Use this for release artifacts and container images in security-sensitive pipelines.

**Required permission:** `attestations: write` (in addition to `id-token: write` for the signing step).

**Verify:** `gh attestation verify <artifact-path> --repo <owner>/<repo>` — returns the signing workflow run details; a failed verification means the artifact was not produced by the expected workflow.
