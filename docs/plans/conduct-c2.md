---
plan: conduct-c2
urgency: normal
agent: opus
effort: high
needs: retro-audit-and-trace
requirement: none
issue: none
scope: .agents/scripts/c2-run.sh, .claude/commands/retro-audit.md, docs/conduct-log.md, .agents/harness/selftest/c2-run.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/reading-budget.sh
---

## Goal

Loop step 5 says "Test for a fix must FAIL without it", and nothing checks
it after merge. Research conduct-c2-design (pull request that deleted
`docs/research/conduct-c2-design.md`) settled that the audit mode can: run
the selftest cases a sampled branch touched once with its change and once
without, and read each case's own word. Add that as audit question C2,
beside C1, at a measured 0 to 87 s per branch (research run, 4 CPUs).

## Scope

- `.agents/scripts/c2-run.sh` — new. `c2-run.sh <stem> [base]` prints the
  per-case table and one runner line. The design, fixed here:
  - **Pairs.** Every add and delete of `docs/handover/<stem>.md` on `base`
    (`--full-history`), oldest first. Adds and deletes unequal = `NO
    EVIDENCE: pairs`.
  - **Own commits.** Per pair `git rev-list --no-merges --first-parent
    <add>^..<delete>`, unioned. A stem merged in several pull requests
    counts all of them (fast-lane: the last pair alone touches no code).
  - **T_fix** = the last delete's tree.
  - **T_nofix code** = P, the main commit the last branch last saw:
    `merge-base(<main merge of the last delete>^1, <last delete>)`. Own
    commits of EARLIER pairs that are ancestors of P are reverse-applied on
    top (`git apply -R --3way`, non-test paths only); a conflict = `NO
    EVIDENCE: conflict <sha>`.
  - **T_nofix tests** = `.agents/harness/selftest.sh` and
    `.agents/harness/selftest/` from T_fix, whole. Never the parent's runner.
  - **Gate.** Own commits touch nothing outside the selftest files and
    `docs/handover/`, `docs/plans/`, `docs/research/` = N/A, no change. A
    command or doc `.md` is product: a case may grep it
    (issue-pr-link-comment's `orchestrated.sh` cases read manage.md). Touch
    no selftest file = `NO TEST`.
  - **Selection.** In each tree, rewrite `SELFTEST_TOPICS` and
    `SELFTEST_CHAINS` to the units holding a touched topic (a chain whole),
    `git rm` every other topic file, commit in the scratch worktree so
    `ls-files` agrees. A tree whose lists do not parse = `NO EVIDENCE:
    lists`.
  - **Pre.** A third run at `<first add>^` with its own runner, same
    selection, only to mark each label new or old.
  - **Matching.** The k-th T_fix line of label L matches the k-th line of
    the other run that is L or starts with `L (` (FAIL lines carry a
    diagnostic). No match = `MISSING`.
  - Table rows: `<label> <with> <without> <new|old>`, every new label and
    every label whose word differs. Runner line, one of: `FLIP <n>` (n
    labels PASS with, FAIL without), `NO FLIP`, `NO FLIP, <n> unread` (SKIP
    or MISSING or FAIL-with present).
  - Worktrees under a `mktemp -d`, removed on exit; runs in parallel, each
    under `timeout 1800`.
- No `joharness.sh` change: the reviewer runs the script per sampled stem.
  `.agents/scripts/` and the selftest are canonical-only
  (`.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS`), so the script
  never ships; retro-audit.md does, and says C2 is `-` where
  `.agents/scripts/c2-run.sh` is absent.
- `.claude/commands/retro-audit.md` — §3 gains C2 (wording below); §4 ledger
  gains a `C2` column after `C1`; read list gains the script's output.
- `docs/conduct-log.md` — header gains `C2`. Earlier rows read as `-`.
- `.agents/harness/selftest/c2-run.sh` — new topic; fixtures below.
- `.agents/harness/selftest.sh` — list the topic.
- `.agents/harness/selftest/reading-budget.sh` — retro-audit.md's bound, if
  the added text exceeds it.

**C2 wording (retro-audit.md §3):** run `c2-run.sh <stem>` (Bash `timeout`
1800). Verdict:
- **N/A** — runner says N/A, or the Goal states no behaviour change (a
  refactor: PASS/PASS cases are characterization).
- `FINE` — every new case whose label names what the Goal or a `(fixed)`
  `## Review` row says was fixed reads PASS/FAIL, and the runner says FLIP.
- `CONCERN` — such a case reads PASS/PASS; or the Goal claims a behaviour
  change and the runner says `NO FLIP` with nothing unread. Note cites the
  row verbatim.
- `NO EVIDENCE` — runner `NO EVIDENCE`/`NO TEST`, `NO FLIP, <n> unread`,
  or no label can be tied to the Goal. Never a guessed FINE.

## Assumptions

- A1: a unit's labels are deterministic across runs of one tree — evidence:
  research conduct-c2-design, the same stem run twice gave identical tables
  (needs-cycle-lint, guard-one-shot-self-kill) — confidence: medium (two
  stems).
- A2: `SELFTEST_TOPICS=(` … `)` and `SELFTEST_CHAINS=(` … `)` keep their
  one-name-per-line, one-chain-per-line shape — evidence:
  `.agents/harness/selftest.sh:SELFTEST_TOPICS` — confidence: high.
- A3: retro-audit-and-trace merged `.claude/commands/retro-audit.md` with
  conduct.md's text — evidence: `docs/plans/retro-audit-and-trace.md`
  Commands table — confidence: high.

## Out of scope

- A `JOHARNESS_SELFTEST_TOPICS` selector inside selftest.sh: T_fix trees
  older than it would still need the rewrite, so it adds a second mechanism.
- Per-review-fix granularity (the commit before each `(fixed)` row): the
  unit is the branch.
- Acting on a C2 CONCERN; changing the sample.
- Core paths.

## Acceptance

```bash
bash .agents/scripts/c2-run.sh needs-cycle-lint | tail -1        # FLIP 4
bash .agents/scripts/c2-run.sh guard-one-shot-self-kill | tail -1  # FLIP 16
bash .agents/scripts/c2-run.sh fast-lane | tail -1               # FLIP 28
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- Consumer-side: `.agents/scripts/sync-to-consumer.sh --dry-run <dir>`
  lists `.claude/commands/retro-audit.md` and not `c2-run.sh`; a consumer's
  audit writes `-` in the C2 column (retro-audit.md's own sentence).

- Selftest cases on fixture stems, each failing on origin/main:
  - fix with a new case: FLIP;
  - refactor plus a characterization case: NO FLIP;
  - new case reaching `skip`: NO FLIP, 1 unread;
  - a case after which the topic `exit`s: NO FLIP, 1 unread (MISSING);
  - characterization case through a helper the branch adds to
    selftest.sh: NO FLIP (the parent's runner would print FAIL);
  - fix tested in a new topic file the parent does not list: FLIP;
  - test-only branch: N/A, no change;
  - a case reading a variable its chain's earlier topic sets: FLIP (the
    unit runs whole);
  - another case of the branch flips while the fix's own case passes
    either way: FLIP, and the table row reads `PASS PASS new` (fx-other);
  - a new topic file and no fix: NO FLIP (the parent's runner would die
    on the unlisted file);
  - label carrying `$RANDOM`: NO FLIP, 1 unread;
  - stem merged in two pull requests, fix in the first: FLIP.

## Where to look

- `git show c10cee3c:docs/research/conduct-c2-design-prototype/c2-run.sh` —
  the measured prototype (prints `C2 FINE` where this plan says `FLIP`);
  `fixtures.sh` beside it builds every trap's fixture stem.

- `.agents/harness/selftest.sh:selftest_units` — chain = one unit.
- `.agents/harness/selftest.sh:selftest_unit` — a unit that dies leaves
  labels printed so far, no counts.
- `.claude/commands/conduct.md` — C1, the ledger header, and the
  paragraph "C2 is not asked yet" (the research's answer).

## Traps

- NEVER skip, disable or quarantine a test to get green.
- The table is evidence; FINE never rests on a topic's or the run's exit.
- The reviewer reads no diff body; the script applies diffs, it prints none.
