---
plan: frontmatter-forge
urgency: normal
agent: opus
effort: medium
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

A workstream file on another branch is repo-controlled input. Two readers in
`joharness.sh` build tab-separated records out of its frontmatter and pass
every field through unvalidated:

- `dispatch_curate_branches` — `cmd_dispatch` prints its record through
  `printf '%b'`, so `workstream: curate-2026-09-01\n            origin/main
  INJECTED  none` forges a whole row in the output an orchestrator reads to
  decide spawns. Found by the janitor branch's verifier, in code that branch
  did not touch, and reported rather than fixed there.
- `dispatch_rescope_branches` — worse, and nobody has named it yet: a TAB in
  `workstream:` shifts every later field, so `rescope-<key><TAB>done` lands
  `done` in `rstat`, which sets `rescope_settled=1` and stops the surveyor
  being spawned for that key.

The queue hook already carries this exact lesson — `status: blocked<TAB>on the
human` split its record and `$3` read exactly `blocked` — and says a field
that decides something must be validated, never passed through.

## Scope

- `joharness.sh` — one helper beside the other frontmatter readers:

  `fm_clean <field>` — replaces tab, backslash, CR and LF with a space and
  keeps every other character. Structure dies, prose lives. Bash substitution,
  no fork: these readers already run per candidate branch in `drain`.

- `joharness.sh:dispatch_curate_branches` — `fm_clean` every field it prints,
  and validate `status` against the graph's vocabulary (`in-progress |
  blocked | review | done | abandoned`, anything else `unreadable`) as
  `cmd_dispatch` does for the same field one screen down.

- `joharness.sh:dispatch_rescope_branches` — the same two changes.

- `joharness.sh:janitor_branches` — replace its narrower `tr -cd` with the
  shared helper, so the family has one rule and not two.

- `joharness.sh:cmd_janitor` — `fm_clean` the branch names in the merged list
  it prints through `%b`; a ref name is git-controlled rather than
  frontmatter-controlled, and the helper costs nothing.

- `.agents/harness/selftest/dispatch.sh` — a case per forge, on the fixture
  that already exists there:
  - a curate branch whose `workstream:` carries `\n` plus a row-shaped
    string: no forged row in `dispatch`, and the real row still reads.
  - a rescope branch whose `workstream:` carries a TAB plus `done`:
    `rescope_settled` does not flip, so the surveyor is still spawned.
  - a curate claim whose `status:` is outside the vocabulary: printed as
    `unreadable`, never as itself.

## Out of scope

- The printers. `printf '%b'` and the `\n` in the accumulated strings stay:
  the escape is the printer's own, and the field is what must not carry one.
- Every other reader of a workstream file. `cmd_dispatch`'s in-flight loop and
  the queue hook already validate what they branch on; this plan closes the
  two that do not, and adds no rule they do not already state.
- The janitor's own sanitiser behaviour. Narrowing a stamp to a charset is
  right for a stamp; this only makes it call the shared helper for the fields
  that are prose.
- `handover-context.sh`. It prints with `%s` and splits nothing on tabs.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- With the forged curate fixture in place, `JOHARNESS_MODE=orchestrated
  ./joharness.sh dispatch` prints no row containing `INJECTED` in a
  branch-row shape, and still prints the real `curate :` row.
- With the forged rescope fixture, the `OVERLAP-BOUND` verdict still spawns a
  surveyor — `rescope_settled` unflipped.
- Each new case fails with its fix reverted (mutation-checked, not assumed).
- SHIPS: the consumer-side check is `./joharness.sh dispatch` there, since a
  consumer carries no selftest.

## Where to look

- `joharness.sh:dispatch_curate_branches` — `printf '%s\t%s\t%s\t%s\t%s\n'`.
- `joharness.sh:dispatch_rescope_branches` — the same line, and the
  `case "$rstat" in done | blocked)` it feeds.
- `joharness.sh:janitor_branches` — the narrower sanitiser to replace.
- `.agents/harness/queue-context.sh` — the TAB incident, written out where it
  was paid for.
- `.agents/harness/selftest/dispatch.sh` — the curate and rescope fixtures.

## Traps

- Protocol text: `joharness.sh` and `.agents/harness/` are under
  `./joharness.sh protocol-paths`. Supervised work only.
- A test written for a fix must FAIL without it: revert, run, put it back.
- Step 5 review at this branch's tier plus `.claude/agents/verifier.md`,
  findings tagged `(verifier)`, `- r<N>:` form.
- Step 7: this plan and the workstream file are deleted in the last commit
  before the pull request opens.
