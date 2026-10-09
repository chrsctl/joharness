---
plan: janitor-zero-candidate-says-why
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/janitor.sh
---

## Goal

Issue #308. When `./joharness.sh janitor` finds no candidates it prints
`none — every claim pushed inside <N>h`, whatever emptied the list. Two
filters can empty it: the age gate and the `abandoned` skip. Measured
2026-10-08: the line printed while six released claims were 485h old,
past the 144h window, all skipped as `abandoned`. A session read the false
sentence and planned the wrong fix. This is #278's defect class (a reader
stating a result it never read) in the same command. Make the line say
what was counted.

## Scope

- `joharness.sh:cmd_janitor`, the candidate walk. Count the claims each
  filter drops: `n_young` for claims the age gate drops
  (`[ $((age * 60)) -ge "$stale_s" ] || continue`), and `n_released` for
  claims past the gate and dropped by `[ "$status" = abandoned ] &&
  continue`. Increment the counter just before each `continue`. The other
  `continue`s (no age, unreadable file) get no counter.
- `joharness.sh:cmd_janitor`, the `n_cand -eq 0` branch. Replace the one
  hardcoded printf with three cases:
  - `n_released` = 0: the current sentence, unchanged
    (`  none — every claim pushed inside <N>h`). It is true then. Keep the
    exact bytes: the selftest at `"a window nothing is older than empties
    the list"` pins them.
  - `n_young` = 0 and `n_released` > 0:
    `  none — <n_released> claim(s) older than <N>h, every one already released (status: abandoned)`
  - both > 0:
    `  none — <n_young> claim(s) pushed inside <N>h; <n_released> older, already released (status: abandoned)`
- `.agents/harness/selftest/janitor.sh`: a state where EVERY claim past the
  window is `abandoned`. The suite has none today. After fixture
  `"release the claim"`, `mgr-ownplan` (`in-progress`, 2026-01-02) is still
  a candidate, so `n_cand` = 1 and no `none —` line prints at all (verified
  by the review of this plan). So: add a fixture commit that also releases
  `mgr-ownplan` (`status: abandoned`), placed AFTER every existing case
  that reads it as a candidate. Then `out="$(jan)"` → `expect`
  `every one already released`, `refute` `every claim pushed inside`.
  Print the candidates block once while writing the fixture, and check it
  before writing the `expect`. Mixed case: the same state with
  `HANDOVER_STALE_SECONDS` set so one claim is young, if the fixture dates
  allow it. If they do not, skip it and say so in the workstream file.

## Out of scope

- The `holds:` lines, the pull-request lines and the footer of the
  non-empty branch. #290 fixed `holds:`. Touch nothing else in the output.
- Changing which claims are candidates. Only the sentence changes.
- `.claude/commands/janitor.md`. `janitor-rules-agree` owns that file.

## Acceptance

- `bash .agents/harness/selftest.sh` → `0 failed`, and its `janitor` lines all pass. The topic files are "Not runnable alone" — never run one by itself
- Revert only the `joharness.sh` change and rerun the suite. The new
  `expect` must FAIL. Then put the change back (`.agents/harness/AGENTS.md`
  step 5: a test that passes both ways pins nothing).
- `./joharness.sh janitor` in this repo → the `candidates` block prints one
  of the three sentences. If it is the first sentence, check by hand that no
  claim past the window is `abandoned`:
  `./joharness.sh janitor | sed -n '/^candidates/,/^$/p'`
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `joharness.sh` reaches consumers. The consumer check is
  `./joharness.sh janitor` in a consumer that has released claims.

## Where to look

- `joharness.sh:cmd_janitor` — the walk and the `n_cand -eq 0` printf.
- `joharness.sh:cmd_janitor`, the `holds:` block — a reader that names what
  it read (#278, #290). Copy that style.
- `.agents/harness/selftest/janitor.sh` — `jan`, the fixture
  `"release the claim"`, and the `expect` `"a window nothing is older than
  empties the list"`.

## Traps

- `janitor-sees-retired-sweep` and `release-reds-the-branch-it-releases`
  also edit `.agents/harness/selftest/janitor.sh`, and the first also edits
  `joharness.sh` near `cmd_janitor`. All mark these paths `shared:`. Expect
  a reconcile at step 7. Keep both sides.
- Add no git call to the walk. The counters are arithmetic only.
- A new release fixture changes what later cases in the same suite see.
  Run the whole suite, not only the new lines.
- Test written for the fix must fail without it. Revert, run, restore.
