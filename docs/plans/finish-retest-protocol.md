---
plan: finish-retest-protocol
urgency: normal
agent: opus
effort: high
needs: local-check-scoped-green, starved-counts-green-runs
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/checks.sh, shared:.agents/docs/consumer-repos.md, shared:.claude/commands/manager.md, .agents/docs/product.md
---

## Goal

Local-mode `finish` on a busy consumer has no written loop, only patches:
CATCH-UP covers a clean merge with no shared path, a scoped green is being
taught not to certify (`local-check-scoped-green`), and STARVED is being
taught what to count and when to resume without a human
(`starved-counts-green-runs`, `starved-resumes-unasked`). Two cases still
fall to a full run every time, and in chrsctl/gx they are the common ones:

1. **A path changed on both sides.** CATCH-UP refuses, the whole check
   runs again (~33 min in gx), and the base moves again. Each consumer has
   to rediscover which paths overlapped (gx #1499 wrote
   `tools/localcheck/scope.py` for it), from a certificate of its own.
2. **A merge resolved by hand**, criterion-id renumbering above all. HEAD
   is not the clean merge, so even a scoping consumer runs everything:
   gx's `reeve-fit-settings-counts-door` renumbered after two of its three
   catch-ups on 2026-11-11 (`CRM6011`→`CRM6045`→`CRM6121`), and each
   renumber forced the full run.

Make the loop one protocol the harness owns: **test a head in full once;
after each merge of the base, retest only what that merge could have
changed; merge when green and level.** `finish` computes the retest set,
whatever caused it, and hands it to `local-check`. A consumer that scopes by
it re-runs minutes, not the suite; a consumer that ignores it runs in full,
as it does today, so the default stays safe.

## The protocol (lands in `consumer-repos.md` § Local checks, "The finish loop")

1. **Test.** A head 0 behind runs `finish` in full. Green = certificate
   `C = (H0, B0)`, as today.
2. **Merge.** Behind at the end: merge `origin/main` into the branch (never
   rebase), resolving conflicts by hand if needed. The new head `Hk` is the
   merge.
3. **Retest.** `finish` on `Hk` measures from `C`, never from the previous
   retest. With `mb = merge-base(H0, base)`:
   - `branch` = paths changed in `mb..H0`; `base` = paths changed in
     `mb..base`;
   - `auto` = `git merge-tree --write-tree H0 base`. If that reports
     conflicts, `conflicted` = its conflicted paths.
   - `resolved` = paths where `Hk`'s tree differs from the `auto` tree (none
     for a clean merge). A resolved path outside `conflicted ∪ branch ∪
     base` means something besides the merge changed: full run, named.
   - **Retest set** `R = (branch ∩ base) ∪ conflicted ∪ resolved`, sorted,
     one per line.
   - `R` empty and within `JOHARNESS_CATCHUP_COMMITS`: CATCH-UP exactly as
     today (`ci` re-runs, `local-check` carries).
   - Otherwise `local-check` runs with `JOHARNESS_RETEST_PATHS` = the path
     of a file in the git dir holding `R`, and `JOHARNESS_RETEST_FROM` =
     `H0`. The consumer may scope to them. If it does, it says so through
     `local-check-scoped-green`'s marker, and the green certifies nothing.
     If it ignores them, it runs in full, and a full green certifies `Hk`
     as a new `C`.
4. **Bound.** A retest chain from one `C` is bounded by
   `JOHARNESS_RETEST_COMMITS` (default 100) base commits since `B0`. Past
   the bound, `finish` runs in full, naming the bound. The commit cap
   protects CATCH-UP's no-suites path only; with `R` handed to the suites,
   the base can move further before the chain needs a fresh full run.
5. **Merge when green and level.** Unchanged (Loop step 7). STARVED counts
   only the green runs the base outran (`starved-counts-green-runs`). With
   retests measured in minutes, it should become rare.

## Scope

- `joharness.sh:checks_catch_up`: compute `branch`, `base`, `conflicted`,
  `resolved` and `R` as above. Today's "HEAD's tree is not the clean merge"
  refusal becomes: resolved paths inside `conflicted ∪ branch ∪ base` are
  allowed and added to `R`; any other resolved path still refuses, naming
  it. Print `R`'s size and first path on the CATCH-UP / RETEST line. A new
  verdict word `RETEST` (`R` non-empty): `local-check` runs with the two
  variables; `ci` runs as always.
- `joharness.sh:checks_local_check`: export `JOHARNESS_RETEST_PATHS` and
  `JOHARNESS_RETEST_FROM` on a RETEST, never otherwise. On a full run, unset
  them and remove the retest file.
- `joharness.sh` knob table: `JOHARNESS_RETEST_COMMITS|100|session|...`.
  `0` = no retest chain: every non-CATCH-UP run is full, as today.
- `.agents/harness/selftest/checks.sh`, CATCH-UP section. Cases, each with a
  fixture `local-check` that writes the variables it received to a file:
  1. Clean merge, one shared path → `RETEST`, `R` = that path, `FROM` = the
     certified head.
  2. Conflicted merge resolved by hand in the conflicted file only →
     `RETEST`, `R` holds it.
  3. Conflicted merge plus an edit to an unrelated, untouched path → full
     run, naming that path.
  4. Clean disjoint merge → `CATCH-UP` as today; no variables exported.
  5. Base past `JOHARNESS_RETEST_COMMITS` → full, naming the bound.
  6. A fixture `local-check` that ignores the variables and exits 0 on a
     RETEST → certificate rewritten to the new head (a full green).
  7. Two retests in a row: the second still measures from `H0`, and `R`
     grows to the union.
- `.agents/docs/consumer-repos.md` § Local checks: "The finish loop" (the
  five steps above) and the consumer contract: the two variables, what a
  scoped run must still do (re-run every suite a path in `R` feeds), and
  the default when it ignores them.
- `.claude/commands/manager.md` §4: one line pointing at "The finish loop"
  in place of the bare "merge `origin/main` in, `finish` again".
- `.agents/docs/product.md` "Conflict at finish": a hand resolution no
  longer means a full run; point at the loop.

## Assumptions

- A1: `git merge-tree --write-tree` prints the tree, then the conflicted
  paths, and exits 1 on conflict; the harness already depends on it. —
  evidence: `joharness.sh:checks_catch_up`, `git merge-tree --help` —
  confidence: high.
- A2: `local-check-scoped-green` lands a marker by which `local-check` says
  "green, do not certify", and its OUTRUN rule accepts a scoped green. This
  plan reads that result. — evidence: `docs/plans/local-check-scoped-green.md`
  § Scope — confidence: high.
- A3: The certificate stays rooted at a full green (`C`), so a chain of
  retests never stands on a scoped run. — evidence: `consumer-repos.md` §
  Local checks, "A catch-up never re-certifies" — confidence: high.
- A4: A renumber is a resolution inside `conflicted ∪ branch`: the branch
  added the ids and the base added the colliding ones in the same ledger
  files. — evidence: gx `91cc8479c`, `011f69a5f` (renumber commits touching
  only the branch's own criteria files and specs) — confidence: medium. A
  renumber that also edits a file neither side changed falls to the full
  run, by design.

## Out of scope

- A consumer's path→suite map. The harness hands over paths; which suites
  they feed is the consumer's (gx: `tools/localcheck/scope.py`). A shared
  map format is a later plan, once a second consumer scopes.
- A merge queue or serialising finishers across managers. Throughput is
  dispatch's; this plan only shortens each lap.
- STARVED's count and resume (the two plans named in `needs:` and
  `starved-resumes-unasked`).
- Changing `JOHARNESS_CATCHUP_COMMITS` or the CATCH-UP no-suites path beyond
  admitting resolved paths into `R`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `bash .agents/harness/selftest/checks.sh` — the seven cases above, each
  named in the output; each fails when its mechanism is removed (record which
  removal reddened which case in `## Review`).
- Plan `ci` calls SHIPS. Consumer-side check, in chrsctl/gx after the sync:
  a branch certified green, then `origin/main` merged with a criterion-id
  renumber resolved by hand, runs `JOHARNESS_CHECKS=local ./joharness.sh
  finish` and prints `RETEST` with the renumbered files in `R`, not a full
  run. Recorded with its output in the pull request body.

## Where to look

- `joharness.sh:checks_catch_up` — today's CATCH-UP conditions; the clean-merge
  test this plan widens.
- `joharness.sh:checks_local_check` — where `local-check` is run and what it
  is handed.
- `joharness.sh:checks_gate` — the certificate write.
- `.agents/docs/consumer-repos.md` — § Local checks, the contract text.

## Traps

- Never measure a retest from the previous retest's head: every `R` is from
  the full green `C`, or scoped runs chain (A3).
- A path in `R` is a hint to scope, never a licence to skip: a consumer that
  cannot map a path re-runs everything that path could feed.
- Harness commands never call the GitHub API.
