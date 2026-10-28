---
research: conduct-c2-design
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/conduct.md
---

## Question

Can conduct check, per sampled branch, that the selftest case the branch
added for a fix fails on the code before the fix, without false FINE or
false CONCERN, inside a bound one conduct run can afford?

## Echo

Loop step 5 says "Test for a fix must FAIL without it". Nothing checks it
after merge. Conduct could, as question C2, if it can run the changed case
alone on the pre-fix parent and read that case's own verdict. A plan is
built on this only if the answer is yes. Known traps from review:

- A whole-topic red gives a false FINE. Causes: another case changed, a
  runner fatal, a chained topic (`SELFTEST_CHAINS`), a helper missing on the
  parent.
- Several things give a false CONCERN:
  - the stem merged in two pull requests, so the parent already holds the fix;
  - a case reaches `skip()`;
  - a refactor, or a characterization test that is not a fix's test;
  - a new topic file the parent's runner does not list.
- There is no single-topic selector in `.agents/harness/selftest.sh`.
- The full suite measured 493 s (verifier, 2026-10-25, `time bash
  .agents/harness/selftest.sh`, this container).

## Sweep

goal-directed: complete when each trap above has a design that defeats it,
or is shown not to, and C2's cost per branch is measured.

## What would settle it

YES: a runner design that reports the changed case's own PASS or FAIL on
the parent. It gets the right verdict on fixtures for every trap above, and
one branch costs a measured time small enough for 3 per run.
NO: any trap with no design, or a cost per branch too high for 3 per run.
Either answer is a finding; NO graduates as "C2 is not checkable after
merge; keep the rule at the verifier".

## Method

Prototype and fixtures: `docs/research/conduct-c2-design-prototype/`
(`c2-run.sh`, `fixtures.sh`, commit 04974b1f; deleted at retire, read with
`git show 04974b1f:<path>`). Container: 4 CPUs (`nproc`), 2026-10-28.

- `bash c2-run.sh <stem>` from the checkout, per real stem below.
- `bash fixtures.sh <dir>` builds a clone of origin/main plus one merged
  stem per trap (`fx-*`), then `cd <dir>; bash c2-run.sh fx-<s> main`, and
  the same with `C2_NAIVE=1` (the design the traps were found against:
  the parent's own tree and runner, the touched topic files copied in, the
  run's exit as verdict).
- `C2_LAST_PAIR_ONLY=1 bash c2-run.sh fast-lane` for the two-pull-request
  trap on a real stem.

Design under test:
- Own commits: per claim/retire pair of `docs/handover/<stem>.md`
  (`--full-history`, adds and deletes), `git rev-list --no-merges
  --first-parent <add>^..<delete>`, unioned over pairs.
- T_fix = the last delete. T_nofix = code from P, the main commit the last
  branch last merged (`merge-base(<main merge holding the delete>^1,
  <delete>)`), earlier pairs' own non-test diffs reverse-applied on top,
  plus the selftest runner and every topic file from T_fix.
- Only the units holding a topic the own commits touched run: the two
  lists rewritten, other topic files `git rm`ed, committed in the scratch
  worktree. A third run at `<first add>^` marks labels new or old.
- Each label matched by occurrence; a FAIL line may carry `L (...)`.

## Findings

Real stems (`c2-run.sh <stem>`, run-c, 2026-10-28):

| stem | pairs | flips (PASS with, FAIL without) | wall |
|---|---|---|---|
| requirement-partly-served | 1 | 20 | 86 s |
| fast-lane | 2 | 28 | 14 s |
| guard-one-shot-self-kill | 1 | 16 | 5 s |
| needs-cycle-lint (chain ci-graph-lint clerk) | 1 | 4 | 47 s |
| conduct-recent-sample | 1 | 17 | 87 s |
| hold-requirement (handover-context chain, 9 topics) | 1 | 14 | 76 s |
| curate-subsystem-split | 1 | 2 | 69 s |
| issue-pr-link-comment | 1 | N/A: no code | 0 s |
| heartbeat-check-each-pass | 1 | N/A: no code | 1 s |

Every real run: `PASS->MISSING: 0`, `PASS->SKIP: 0` — labels were
deterministic across the three runs of a stem (GROUNDED, 7 stems). The
last conduct sample (curate-subsystem-split, issue-pr-link-comment,
heartbeat-check-each-pass) cost 70 s in all; the worst unit measured is
87 s. Three branches a run fit easily against the 493 s full suite
(GROUNDED).

Traps, fixture verdicts (design / naive):

| trap | fixture | design | naive |
|---|---|---|---|
| true fix (control) | fx-fix | FINE | FINE |
| whole-topic red: runner fatal | fx-newtopicchar (new topic, no fix) | CONCERN | FINE (parent runner: "tracked topic file nobody sources") |
| whole-topic red: unit dies | fx-death (`exit` after the case) | NO EVIDENCE (MISSING) | FINE |
| whole-topic red: helper missing on parent | fx-helperchar (helper added to selftest.sh, no fix) | CONCERN | FINE |
| whole-topic red: another case changed | fx-other (wording case flips, fix-B case passes either way) | FINE + table row `fix B PASS PASS new` | FINE |
| chained topic | needs-cycle-lint, hold-requirement (real) | FINE | not run |
| two pull requests | fast-lane (real); fx-twopr | FINE (28 flips); FINE | last pair alone: N/A, own commits touch no code |
| case reaches skip() | fx-skip | NO EVIDENCE (SKIP SKIP) | CONCERN |
| refactor / characterization | fx-char | CONCERN, row `PASS PASS new` | CONCERN |
| new topic file parent does not list | fx-newtopic | FINE | FINE, but by the runner fatal |
| test-only branch | fx-testonly | N/A | N/A |
| nondeterministic label | fx-random | NO EVIDENCE (MISSING) | FINE |

Two traps are not beaten by the runner alone (GROUNDED, fixtures fx-other
and fx-char): a branch whose fix case passes either way while another of
its cases flips reads FINE mechanically, and a refactor's characterization
case reads CONCERN mechanically. Both are beaten by reading the per-case
table against the Goal and `## Review` — the reviewer already reads those
for C1. So C2's verdict is per case, the reviewer's, with the runner's line
as evidence; FINE never rests on a run's exit.

Rejected on the way (handover `## Rejected`): `git revert` of own commits
(conflicts in test files it discards); `git apply -R --3way` onto T_fix
(conflicts where main merged into the branch moved the same lines,
requirement-partly-served 970de5c1 on joharness.sh — the code-from-P route
gives it 20 flips).

Limits (WEAK): the branch is the unit, not each `(fixed)` row; a stem
with an earlier pull request whose reverse no longer applies on P reads
NO EVIDENCE; 7 code-touching real stems, all FINE, so no real CONCERN was
observed.

## Consequence for the queue

YES. New plan `docs/plans/conduct-c2.md` (`needs: retro-audit-and-trace`):
the script, the ledger column, the per-case verdict in retro-audit.md.

## Verification

Pending: the verifier re-runs `c2-run.sh` on one real stem and one fixture.

## Graduates to

`.claude/commands/conduct.md`: C2 would be conduct's question, or the
reason it is not.
