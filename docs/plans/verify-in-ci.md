---
plan: verify-in-ci
urgency: normal
agent: opus
effort: high
needs: none
requirement: verify-in-ci
scope: .github/workflows/ci.yml, .agents/env/README.md, .agents/env/docker/ci-verify, AGENTS.md, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

<!-- Same-session plan: decomposes docs/product/verify-in-ci.md, executed on
the same branch. This is the requirement's only plan, so the PR deletes the
requirement file too (plans README, Lifecycle). -->

## Goal

Step 7 makes every harness-code merge wait on `./joharness.sh verify`, and
therefore on a human with a sandbox, because "CI cannot run it". That
exclusion describes the k8s layer's needs, not verify's. A layer whose setup
is a no-op wherever dockerd already runs needs none of it. Give such layers
continuous CI coverage in canonical, and make step 7's verify condition
machine-checkable for a consumer that selects one.

## Design decision (the requirement left this open)

The job does NOT name a layer. Each layer declares its own CI-runnability
with a marker file in its own directory; the workflow globs for it. This is
the only option that survives `ci.yml` being seeded verbatim into every
consumer: a consumer whose layer carries no marker gets a job that says so
and passes, never a job trying to run a layer it does not have. It also
keeps the layer contract's rule intact — nothing outside the layer names it,
so no layer name enters harness prose or the workflow.

## Scope

- `.agents/env/docker/ci-verify` — new marker. Content = why this layer
  qualifies (setup is a no-op where dockerd already runs). Presence is the
  declaration; content is for humans.
- `.agents/env/README.md` — contract table gains the marker row; say what
  declaring it promises and what CI does with it.
- `.github/workflows/ci.yml` — new job: discover layers carrying the marker
  AND an executable `smoke-test.sh`, run `JOHARNESS_ENV=<layer>
  ./joharness.sh verify` for each. No layer named in the file. Zero
  discovered = say so and pass. Registry unreachable or rate-limited = warn
  and pass, never a red gate (requirement's constraint: a flaky red gate is
  worse than no gate); a real check failure is still red.
- Rescope every "CI cannot run verify" claim to the layers where it still
  holds, without naming a layer in harness prose: the `ci.yml` comment,
  root `AGENTS.md`, `.agents/harness/AGENTS.md` step 7,
  `.agents/docs/consumer-repos.md`.

## Out of scope

- Marking any layer other than docker. Others may opt in later by adding
  the marker; proving them on a runner is separate work.
- Changing what any smoke test checks, or the k8s layer at all.
- Making the CI job a step-7 substitute for the SELECTED layer. Canonical
  selects k8s: here the job is layer coverage only, and the docs say so.
- A Docker Hub login / secrets. Fork pull requests get no secrets, and a
  gate that only works for non-forks is the flaky gate the requirement
  rejects.

## Acceptance

- `./joharness.sh ci` — pass.
- `JOHARNESS_ENV=docker ./joharness.sh verify` — green in this sandbox
  (proves the layer the marker claims for).
- Marker discovery proven both ways: a tree with the marker lists the
  layer, a tree without lists nothing and the job passes.
- `grep -rn "CI cannot" AGENTS.md .agents/` — every surviving claim is
  scoped to layers that do not declare the marker.
- `.agents/harness/` still names no layer (selftest's layer rule stays
  green).

## Where to look

- `.github/workflows/ci.yml:lint` — the comment that states the exclusion.
- `.agents/env/README.md:Contract` — the table the marker row joins.
- `joharness.sh:cmd_verify` — resolves the layer, tolerates a layer with no
  smoke test; `JOHARNESS_ENV` overrides selection for one run.
- `.agents/harness/selftest.sh:LAYER_CARVE_OUT_FILE` — the layer-name rule
  this design must not need a carve-out from.

## Traps

- `ci.yml` is seeded verbatim into every consumer: anything layer-specific
  in it becomes every consumer's problem.
- Never let the new job claim more than it checked — a green docker-layer
  job is not the selected layer's verify.
- Trust counted numbers, never written numbers.
