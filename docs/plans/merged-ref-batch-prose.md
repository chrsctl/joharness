---
plan: merged-ref-batch-prose
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/harness/AGENTS.md, joharness.sh, .agents/docs/consumer-repos.md, docs/research/merged-ref-batch-prose-vs-code.md
---

## Goal

Same-session plan for graduating `docs/research/merged-ref-batch-prose-vs-code.md`.
That node's diff touches `joharness.sh` comments beside its graduation
target, which the research protocol says is a plan's shape; this is that
plan, on the work branch, deleted in the same pull request.

## Scope

- `.agents/harness/AGENTS.md` step 7 — drop the clause pointing a reader at
  a `joharness.conf` comment a consumer may not carry.
- `.agents/docs/consumer-repos.md` — widen the conf-comment rule's premise
  from "shorter copy" to "no copy", with the consumer case that showed it.
- `joharness.sh:perf_shape` inventory — say what the merged-ref path costs
  now.
- `joharness.sh:perf_rows` doctrine — restate the headroom as counted after
  the batch, with the regression figures that make it sufficient.
- Delete the research file.

## Out of scope

- Any budget literal in `perf_rows`. Prose only.
- The batch's code, or its selftests. The consumer verified the code.
- Line wrapping at `joharness.sh` beyond the sentences repaired.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh perf` — every row `ok`, counts unchanged from before the
  diff (prose cannot move a count).
- `grep -c 'key that sets it' .agents/harness/AGENTS.md` — `0`.
- `git ls-files docs/research/merged-ref-batch-prose-vs-code.md` — empty.
- SHIPS: `.agents/harness/AGENTS.md` and `joharness.sh` reach consumers;
  a consumer's step 7 no longer points at a conf key it may not have.

## Where to look

- `joharness.sh:perf_rows` — the doctrine paragraph and the batch note.
- `joharness.sh:perf_shape` — the inventory line.

## Traps

- Trust counted numbers, never written: re-run `perf` the day the numbers
  are written, cite the command and date beside them.
- Protocol paths: supervised mode, so committing to `joharness.sh` and
  `.agents/harness/` is allowed; say so in the workstream file.
