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
CATCH-UP covers a clean merge with no shared path, a scoped green does not
certify (`local-check-scoped-green`, merged #762), and STARVED counts only
outrun greens and resumes without a human (`starved-counts-green-runs`,
`starved-resumes-unasked`, merged). Two cases still
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
     first blank line. Exit 1 is no refusal; any other non-zero exit is
     (today's "does not merge clean" refusal narrows to that);
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
   default 20). `R` holds no base-only path the merge left as the base
   wrote it (a hand edit to one puts it in `R`, by step 3). A
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
  alike. Measure the base side from `merge-base(H0, base)`, replacing
  today's `cb..ref`: a recorded base the certified head never contained
  (`origin/main` is shared by every worktree and can move between the
  fetch and the pin) would otherwise hide base changes from both CATCH-UP
  and RETEST (chrsctl/gx #1499 verifier r1, the same shape in
  `tools/localcheck/scope.py`). In the harness the pin reads `tip` and
  `pin` before `behind` against the same ref, so only a hand-written or
  foreign certificate reaches that shape: the measure is the defence, case
  9 builds it by hand. The base-changed-`local-check` refusal reads the same
  `base` set. Paths git would quote (`core.quotePath=false` still quotes
  a tab, newline, `"` or `\`) refuse: full run, "a path git quotes". Output:
  the CATCH-UP line is unchanged. On RETEST:
  `  RETEST       HEAD = certified <sha9> + <n> commit(s) (<m> first-parent merge(s)) of <ref>, <k> path(s) to retest, first <path>`.
  The resolved-path refusal: `full run     certified <sha9> found, no
  catch-up: HEAD changed <path>, which neither side nor the merge did:
  something else changed`.
- Existing `checks.sh` expectations this changes, with their new text:
  `a path changed on both sides: docs-shared.txt` → `RETEST` with
  `first docs-shared.txt` (`local-check` still runs); `HEAD's tree is not
  the clean merge` → `HEAD changed docs-own.txt, which neither side`;
  `a path changed on both sides: kccr.txt` → `RETEST` with `first kccr.txt`.
- `finish`'s verdict line: a pass whose certificate names an older head
  says `carried by CATCH-UP` today; after a scoped RETEST it says
  `retested from <sha9> (RETEST)` instead (the retest file is present only
  after a RETEST).
- `joharness.sh:checks_gate`: a RETEST keeps the certificate. Today every
  run that is not CATCH-UP removes it before the suites ("A full run
  supersedes any certificate"). A RETEST is not a full run: if it removed
  `C`, a scoped retest green would leave nothing for the next retest to
  measure from. Only a full run (no CATCH-UP, no RETEST) removes it. A
  RETEST whose `local-check` ignores the variables and runs green unscoped
  writes `Hk` over it, as any full green does.
- `joharness.sh:checks_local_check`: on RETEST, write
  `<git-dir>/joharness-retest-paths` and export `JOHARNESS_RETEST_PATHS`
  and `JOHARNESS_RETEST_FROM`. On every other run, export neither
  (unset, not empty). `checks_gate` removes the file on every run before
  classifying, so a CATCH-UP, which never calls `checks_local_check`,
  leaves none either.
- `joharness.sh` knob table: rows for `JOHARNESS_RETEST_PATHS` and
  `JOHARNESS_RETEST_FROM`, `computed|session|`, in the form of
  `JOHARNESS_LOCAL_CHECK_SCOPED`'s row, and passed inline on the
  `checks_bounded` call as that variable is
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
  9. A hand-written certificate whose recorded base `cb` is not an
     ancestor of its head, where a commit in `merge-base(H0, cb)..cb`
     changes a branch path (clean merge), then the base moves past `cb`
     → that path is in `R` (today: missed, CATCH-UP). With `cb..ref`
     put back it goes red.
  10. RETEST with a scoping fixture → the certificate file still names `H0`
      afterwards (today's removal on a non-CATCH-UP run would delete it).
  Each case fails with its mechanism removed; record which removal reddened
  which case in the workstream file's `## Review`.
- `.agents/docs/consumer-repos.md` § Local checks: "The finish loop" (the
  five steps above) and the consumer contract: the two variables, the file,
  what a scoped run must still do (re-run every suite a path in `R` could
  feed), and the default when it ignores them. Rewrite the text this makes
  false: the CATCH-UP paragraph's "any other shape is the full run", and
  "Renumbering ids after a merge takes a branch out of CATCH-UP" (now:
  into RETEST).
- `joharness.sh` knob row `JOHARNESS_CATCHUP_COMMITS`: bounds RETEST too.
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
  plan reads that result. — evidence: `joharness.sh:checks_local_check`
  (`JOHARNESS_LOCAL_CHECK_SCOPED`, `CHECKS_SCOPED`), merged #762 —
  confidence: high.
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
- `./joharness.sh verify` — `0 failed`; any non-zero failed count is red.
- Each new case's assertion names start `retest: <case number>.`, so
  `bash .agents/harness/selftest.sh 2>&1 | grep -E 'retest: [0-9]+\.'`
  lists all ten, none failing (a total count has no baseline to read).
- Cases 1, 2, 7, 9 and 10 fail on `origin/main`: `git worktree add --detach
  <dir> origin/main`, copy the branch's `checks.sh` in, run
  `bash .agents/harness/selftest.sh 2>&1 | grep -E 'FAIL.*retest: (1|2|7|9|10)\.'`
  there — non-empty for each of the five. Record both outputs.
- `./joharness.sh ci` on the branch prints `finish-retest-protocol: SHIPS`
  (the plan is changed against the merge base before the retire commit).
  The consumer-side check comes after the sync, so it
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

- Never let a RETEST remove the certificate: the chain stands on `C`.
- Never measure a retest from the previous retest's head: every `R` is from
  the full green `C`, or scoped runs chain (A3).
- A path in `R` is a hint to scope, never a licence to skip: a consumer that
  cannot map a path re-runs everything that path could feed.
- Harness commands never call the GitHub API.
