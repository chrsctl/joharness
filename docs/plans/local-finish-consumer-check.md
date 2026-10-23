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

- **The declaration**: one executable file at a consumer-owned path the
  sync never writes. Proposed: `.agents/local-check`. Confirm it is absent
  from `sync-to-consumer.sh`'s path list, and add it to that script's
  never-synced note. Absent file = today's behaviour.
- **`checks_gate`** (local mode only), after `ci`/`verify`:
  - runs the BASE branch's copy (`git show <base>:.agents/local-check` into
    a temp file), so a branch cannot loosen its own gate. A branch that
    adds or edits the file is gated by the base's copy, or by nothing when
    the base has none.
  - shows its last line, and is red on non-zero exit.
  - when no file is declared, `Not covered here` says so.
- **`.agents/harness/AGENTS.md` step 7**: the local-mode clause names the
  declared check beside `ci` + `verify`.
- **consumer-repos.md § Local checks**: the status-quo bullets change to
  say what the declared check covers and what it does not. Jobs only
  Actions runs still count for nothing.
- **Selftest** (`.agents/harness/selftest/checks.sh`, or the existing home
  of `checks_gate` tests), each failing without the change:
  - a fixture whose base declares `exit 1` → `finish` red;
  - `exit 0` → green, last line shown;
  - a branch editing the file to `exit 0` while the base says `exit 1` →
    still red;
  - no file → today's output plus the "no consumer check declared" line.

## Out of scope

- Running the consumer's GitHub workflow jobs (#513 rejected that).
- Writing gx's file. That is gx's own pull request after the sync:
  `bash run-all.sh && scripts/web-checks.sh`.
- `github` mode: GitHub's checks stay the gate there.

## Acceptance

- `./joharness.sh ci`: `ci: pass`, the selftests listed.
- `./joharness.sh verify`: `0 failed`.
- `JOHARNESS_CHECKS=local ./joharness.sh finish` in a fixture consumer:
  red on a failing declared check, naming its last line.
- Consumer side, after the sync reaches chrsctl/gx: the sync writes no
  `.agents/local-check`, and gx's `finish` output says no consumer check is
  declared until gx adds one.

## Where to look

- `joharness.sh:checks_gate`, `checks_verify_needed`, `cmd_finish`.
- `.agents/docs/consumer-repos.md` § Local checks.
- `.agents/scripts/sync-to-consumer.sh` (the path list).

## Traps

- Never run the head's copy. A gate the branch under test can edit is no
  gate.
- The declared command can be slow. `finish` prints its time, and never
  bounds it silently: a timeout is red, never a skip.
