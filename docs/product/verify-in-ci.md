---
requirement: verify-in-ci
priority: normal
---

## Goal

Step 7 makes every harness-code merge wait on `./joharness.sh verify` —
and therefore on a human with a sandbox, because "CI cannot run it". That
exclusion (ci.yml: "Docker-in-Docker, the egress proxy, the cgroup v1
kernel") describes the k8s layer, not verify itself. The docker layer
needs none of it: its setup is a no-op wherever dockerd already runs, and
ubuntu-latest runs dockerd. A CI job running verify for the docker layer
gives that layer continuous coverage in canonical — today its smoke test
runs only when someone happens to sit in a docker sandbox — and in a
consumer that selects `JOHARNESS_ENV=docker` it makes step 7's verify
condition machine-checkable for the first time: the one merge condition
that still rests on a session's word. Same motivation line PR #76 already
ratified: a rule that cannot be satisfied teaches the override.

## Satisfied when

- A CI job in canonical runs `./joharness.sh verify` for the docker layer
  on pull requests and pushes to main, green on current main.
- The job claims exactly what it checked. Canonical selects k8s, so here
  the job is layer coverage, never a step-7 substitute; the docs say so
  in as many words.
- Every place stating "CI cannot run verify" (the ci.yml comment,
  joharness.sh, both AGENTS.md files, consumer-repos.md) moves with the
  code, rescoped to the layers where it still holds.
- A consumer on the docker layer can satisfy step 7's verify condition
  from CI. Consumers on other layers inherit no red and no meaningless
  job — ci.yml is seeded verbatim into every new consumer.

## Constraints

- No claim past the check: a green docker-layer job never stands in for
  the selected layer's verify where the selected layer is not docker.
- The layer rule holds ("Nothing outside the layer may name it") — how
  the job learns which layers to run (matrix over layers shipping
  smoke-test.sh, read from joharness.conf, ...) is the decomposing
  session's call, made without hardcoding a layer name into harness
  prose.
- Docker Hub rate limits on shared runner IPs and secret-less fork pull
  requests are real; a flaky red gate is worse than no gate.
