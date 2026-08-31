---
plan: ci-billed-minutes
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .github/workflows/ci.yml
---

## Goal

The human's words, 2026-08-31: *"Issue is it uses up all build minutes on
gh."*

The premise is false **for this repo** and the check is one API field:
`chrsctl/joharness` is `"visibility": "public"`, and GitHub bills nothing for
standard runners on a public repository. `ci.yml` runs `ubuntu-latest` and
`windows-latest` — both standard. This repo's 404 runs have cost zero.

It is not false for a **consumer**. `bootstrap-consumer.sh` seeds this exact
file into every consumer it creates (`seed .github/workflows/ci.yml`), and a
private consumer pays list price for every run of it. So the workflow's
per-run bill is a real number that this repo cannot feel and every private
consumer does.

## What the bill actually is

Measured on run 33422323923 (PR 174, `list_workflow_jobs`, 2026-08-31):

| job | worked | billed |
| --- | --- | --- |
| `lint` | 99s | 2 min |
| `verify-declared-layers` | **8s** | **1 min** |
| `windows` | skipped | 0 |

Actions bills per job, rounded up to the minute. So a third of every healthy
run's bill buys eight seconds of work, and the round-up is the entire cost —
there is nothing to make faster.

Across the 28 `ci` runs of 2026-08-31 (`list_workflow_runs`, run numbers
377–404) that is **28 billed minutes** in a repo that merged 13 pull
requests.

## Scope

Fold `verify-declared-layers` into `lint` as a second step, `if: always()`
so a red lint still produces the layer verdict.

The job boundary is buying nothing that a step boundary does not. Its own
header justifies why the check EXISTS and why its logic lives in
`.agents/scripts/ci-verify-layers.sh` rather than inline YAML — neither is an
argument for a separate runner. (The `windows` job's header does argue
separateness, on the ground that it asks a different question of a different
platform. That job stays as it is, and is skipped anyway.)

`lint` already checks out at `fetch-depth: 0`; the verify script wants no
less, so the fold gives it a fuller checkout than it had.

## Out of scope

- **The `main` push run.** Every merge runs `ci` twice — once on the pull
  request, once on the merge commit — and when the branch merged 0 behind
  (step 7 requires it) the second run verifies a tree the first already
  passed. At 13 merges that is the single largest remaining line. It is
  deliberate: `ci.yml`'s own header records that the per-sha concurrency
  group exists so those runs cannot evict each other, because they are what
  catches cross-pull-request collisions no per-PR gate can see. Removing it
  is product direction on a gate, not a cost tidy. **Left for the human.**
- **The recursion.** PR 174 already fixed the 44-minute run
  (33414519009). Its guard is in `joharness.sh`, which IS synced to
  consumers, so it reaches them; this file is not synced after seeding, so
  this plan's change reaches new consumers only.
- Making `lint` itself faster. 99s is 1133 selftest cases plus shellcheck;
  the bar does not move to save a minute.

## Acceptance

- `ci.yml` has two jobs, `lint` and `windows`.
- A run of it reports the layer verdict, and reports it even when the
  shellcheck/selftest step is red.
- Billed minutes per healthy run: 3 -> 2.
