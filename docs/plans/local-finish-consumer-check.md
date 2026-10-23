---
plan: local-finish-consumer-check
urgency: urgent
agent: opus
effort: high
needs: none
requirement: defect-to-fix-loop
issue: none
scope: shared:joharness.sh, .agents/docs/consumer-repos.md, shared:.agents/harness/AGENTS.md, .agents/scripts/sync-to-consumer.sh, .agents/harness/selftest/checks.sh
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 1: prevention. Under
`JOHARNESS_CHECKS=local`, `finish` is the merge gate, and it runs only the
harness's `ci` (+ `verify`). A consumer's own required checks gate by prose
alone. In gx, #785 merged under `finish: pass` with the consumer's audit
red. The red came from the branch's own last commit, after the session had
run the audit once. Main stayed red for seven days. This plan lets a
consumer put ONE command behind the `pass` verdict. The consumer bears and
scopes its cost: gx's `scripts/web-checks.sh` takes 0 s on a branch with
no `platform/web/` change. It answers the question research
`local-checks-consumer-command` (canonical #557) asks.

## Scope

- **The declaration**: one file, `local-check`, at the consumer's
  repository root. That path is outside `.agents/` and `.claude/`, so
  neither `upstream_harness_path` nor the synced `.gitattributes` claims it.
  Confirm both, and confirm it is absent from `sync-to-consumer.sh`'s path
  list. Absent file = today's behaviour.
- **`checks_gate`** (local mode only), after `ci`/`verify`:
  - runs the HEAD's `local-check` with `bash`, from the repository root, so
    its mode bit does not matter. The head's copy because a pull request
    repairing a check broken on the base branch must be able to pass. The
    guarantee is the one `ci` already has: the head tree under test.
  - a branch that changes `local-check` against the merge base prints
    `CHECK CHANGED on this branch` with the diff stat. Edge review reads
    it: the gate's strength is review, not immutability.
  - bounded by `JOHARNESS_LOCAL_CHECK_MINUTES` (new knob, default 30,
    knob-table row). A timeout is red and says so, never a skip.
  - prints its elapsed time and last line, and is red on non-zero exit.
  - when no file is declared, `Not covered here` says
    `no consumer check declared (local-check)`.
- **`.agents/harness/AGENTS.md` step 7**: the local-mode clause names the
  declared check beside `ci` + `verify`.
- **consumer-repos.md § Local checks**: the status-quo bullets change to
  say what the declared check covers and what it does not. Jobs only
  Actions runs still count for nothing.
- **Research `local-checks-consumer-command`** (canonical #557): if its
  file is on the base branch when this merges, this plan's pull request
  deletes it as its graduation.
- **Selftest** (`.agents/harness/selftest/checks.sh`), each failing
  without the change:
  - `local-check` = `exit 1` → `finish` red;
  - `exit 0` → green, last line shown;
  - a non-executable file still runs;
  - a branch changing the file prints `CHECK CHANGED`;
  - a check over the bound → red with `timeout`;
  - no file → the "no consumer check declared" line.

## Out of scope

- Running the consumer's GitHub workflow jobs (#513 rejected that).
- Writing gx's file. That is gx's own pull request after the sync:
  `bash run-all.sh && scripts/web-checks.sh`.
- `github` mode: GitHub's checks stay the gate there.

## Acceptance

- `./joharness.sh ci`: `ci: pass`, the selftests listed.
- `./joharness.sh verify`: `0 failed`.
- `JOHARNESS_CHECKS=local ./joharness.sh finish` in a fixture consumer:
  red on a failing `local-check`, naming its last line.
- Consumer side, after the sync reaches chrsctl/gx: the sync writes no
  `local-check`, and gx's `finish` output says no consumer check is
  declared until gx adds one.

## Where to look

- `joharness.sh:checks_gate`, `checks_verify_needed`, `cmd_finish`.
- `.agents/docs/consumer-repos.md` § Local checks.
- `.agents/scripts/sync-to-consumer.sh` (the path list).

## Traps

- Do not claim more than the head tree gives: a branch can edit the
  scripts its check calls, as it can edit what `ci` runs. `CHECK CHANGED`
  and review are the guard.
- A path under `.agents/` would be reported upstream as canonical's.
