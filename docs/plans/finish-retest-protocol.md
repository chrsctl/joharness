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
   gx's `reeve-fit-settings-counts-door` renumbered its criteria twice on
   2026-11-11 after merging `origin/main` (`91cc8479c`: CRM6011→CRM6045,
   a conflicted merge; `011f69a5f`: →CRM6121, a commit after the merge), and
   each renumber took the branch out of CATCH-UP.

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
   retest. Today's CATCH-UP refusals still apply to both outcomes below:
   the certified head must be an ancestor of HEAD, its base an ancestor of
   the base, the base must have moved since (`n > 0`), the base must not
   have changed `local-check` itself, and `n` must be within
   `JOHARNESS_CATCHUP_COMMITS`. Then, with `mb = merge-base(H0, base)`:
   - `branch` = paths changed in `mb..H0`; `base` = paths changed in
     `mb..base`;
   - `auto` = the first line of `git merge-tree --write-tree --name-only
     H0 base`; on exit 1, `conflicted` = the path lines after it, up to the
     first blank line;
   - `resolved` = `git diff --name-only <auto> HEAD^{tree}` (none for a clean
     merge). A resolved path outside `conflicted ∪ branch ∪ base` means
     something besides the merge changed: full run, naming it. A resolved
     path inside that set is retested, whatever made it;
   - **retest set** `R = (branch ∩ base) ∪ conflicted ∪ resolved`, sorted,
     one per line, written to `<git-dir>/joharness-retest-paths`.
   - `R` empty: **CATCH-UP**, exactly as today (`ci` re-runs, `local-check`
     carries).
   - `R` non-empty: **RETEST**. `ci` re-runs, and `local-check` runs with
     `JOHARNESS_RETEST_PATHS` = that file's absolute path and
     `JOHARNESS_RETEST_FROM` = `H0`. The consumer may scope to them. If it
     does, it says so through `local-check-scoped-green`'s marker, and the
     green certifies nothing. If it ignores them, it runs in full, and a full
     green certifies `Hk` as a new `C`.
   - Any refusal: the full run, as today, naming why.
4. **Bound.** One bound for both, `JOHARNESS_CATCHUP_COMMITS` (unchanged,
   default 20). `R` holds only paths the branch could have changed. A
   semantic clash between a base-only path and a branch-only path reaches
   neither CATCH-UP nor RETEST (`consumer-repos.md` § Local checks, "The
   cost, named"), so the window that bounds that risk stays where it is.
   Past it, the run is full, and a full green starts a new chain.
5. **Merge when green and level.** Unchanged (Loop step 7). STARVED counts
   only the green runs the base outran (`starved-counts-green-runs`). With
   retests measured in minutes, it should become rare.

## Scope

- `joharness.sh:checks_catch_up`: compute `branch`, `base`, `conflicted`,
  `resolved` and `R` as in step 3, with `--name-only` on the existing
  `merge-tree` call. Today's "HEAD's tree is not the clean merge" refusal
  becomes the resolved-path rule. Today's "a path changed on both sides"
  refusal becomes RETEST. Every other refusal stays, for CATCH-UP and RETEST
  alike. Output: the CATCH-UP line is unchanged. A new line, `RETEST
  HEAD = certified <sha> + <n> commit(s) …, <k> path(s) to retest, first
  <path>`, prints on RETEST.
- `joharness.sh:checks_local_check`: on RETEST, write
  `<git-dir>/joharness-retest-paths` and export `JOHARNESS_RETEST_PATHS`
  and `JOHARNESS_RETEST_FROM`. On every other run, export neither and remove
  the file before `local-check` starts.
- `joharness.sh` knob table: rows for `JOHARNESS_RETEST_PATHS` and
  `JOHARNESS_RETEST_FROM`, each `||session|` and set by `finish` on RETEST,
  in the form of `JOHARNESS_SESSION_SOURCE`'s row
  (`knobs-declared.sh:kd_problems` reds any name without a row). No new
  bound knob.
- `.agents/harness/selftest/checks.sh`, CATCH-UP section. Cases, each with a
  fixture `local-check` that writes the variables it received to a file:
  1. Clean merge, one shared path → `RETEST`; the file holds that path;
     `FROM` = the certified head.
  2. Conflicted merge, the conflict resolved by hand in the conflicted file
     only (a renumber's shape) → `RETEST`; the file holds it.
  3. Conflicted merge, plus an edit to a path neither side changed → full
     run, naming that path.
  4. Clean disjoint merge → `CATCH-UP` as today; neither variable exported,
     no file.
  5. Base past `JOHARNESS_CATCHUP_COMMITS` with `R` non-empty → full run,
     naming the bound.
  6. A fixture `local-check` that ignores the variables and exits 0 on a
     RETEST → certificate rewritten to the new head (a full green).
  7. Two RETESTs in a row, with a fixture `local-check` that writes
     `local-check-scoped-green`'s marker each time → the second still
     measures from `H0`, and its `R` is the union of both merges' sets.
  8. A commit after certification, base unmoved (`n = 0`) → full run, "has
     not moved since", never RETEST.
  Each case fails with its mechanism removed; record which removal reddened
  which case in the workstream file's `## Review`.
- `.agents/docs/consumer-repos.md` § Local checks: "The finish loop" (the
  five steps above) and the consumer contract: the two variables, the file,
  what a scoped run must still do (re-run every suite a path in `R` could
  feed), and the default when it ignores them.
- `.claude/commands/manager.md` §4: one line pointing at "The finish loop"
  in place of the bare "merge `origin/main` in, `finish` again".
- `.agents/docs/product.md` "Conflict at finish": a hand resolution no
  longer means a full run; point at the loop.

## Assumptions

- A1: `git merge-tree --write-tree --name-only` prints the tree id on its
  first line, then one conflicted path per line, a blank line and the
  messages; it exits 1 on conflict. Without `--name-only` it prints
  `<mode> <oid> <stage>\t<path>`, one line per stage (git 2.43.0, gx
  `git merge-tree --write-tree 8138a292c 429d03932`). The harness already
  calls it, without the flag. — evidence: `joharness.sh:checks_catch_up`,
  `git merge-tree --help` — confidence: high.
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
- A second bound or a change to `JOHARNESS_CATCHUP_COMMITS`: base-only
  paths are what that bound protects, and `R` never holds one (step 4).

## Acceptance

- `./joharness.sh ci` — last line `ci: pass`; any `FAIL` stage is red.
- `./joharness.sh verify` — `0 failed`, with the eight new `checks.sh` cases
  in its count; any non-zero failed count is red. (`checks.sh` runs only under
  the selftest runner, never alone.)
- Cases 1, 2 and 7 fail on `origin/main` (CATCH-UP refuses, so a full run
  with no variables) and pass on the branch. Record both outputs.
- Plan `ci` calls SHIPS. The consumer-side check comes after the sync, so it
  is not part of this pull request. The PR body names it as the sync's
  acceptance: in a consumer, a branch whose full green is certified merges
  `origin/main` with a hand-resolved conflict in its own ledger file, and
  `finish` prints `RETEST` naming that file, not `full run`.

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
