---
workstream: upstream-feedback
status: in-progress
branch: claude/orchestrator-review-child-repos-tb0z79
pr: none
plan: upstream-feedback
issue: none
session: https://claude.ai/code/session_01XAYv4zxtpBFMpabWuYvxig
agent: sonnet
updated: 2026-09-06
next: Retire this file and the plan in the last commit before the pull request
---

## Goal

The requester asked for a variable that lets the orchestrator route what a
child repo found, after a manager finishes, into defect and improvement report
pull requests on joharness — and then corrected the ask to: a feedback
mechanism, disabled by default, shape ours to choose.

## Decisions

- **The switch is `JOHARNESS_UPSTREAM_FEEDBACK`, `off` by default.** Same
  off/on shape as `JOHARNESS_REVIEW`: off means the report is available and
  nothing acts on it, on means a role acts. It fails closed on any other
  value, like every other switch in `joharness.sh`.
- **The report is a research node in canonical, not a requirement.** A
  requirement is the human's goal to set and `lint_requirement_writes` reds
  an unattended branch that adds one. A research file with a `research:` key
  is a real queue item canonical lists, claims and deletes on the merge that
  answers it — so the report enters by rules already written, with no new
  node type and no new lint.
- **`joharness.sh` reports; the command files.** `cmd_upstream` opens
  nothing and pushes nothing, which is what lets a human run it anywhere.
  The pull request is `.claude/commands/upstream-report.md`'s, and only when
  the switch is on.
- **The reporter is a session, spawned once per merged edge, and it does not
  hold a manager slot.** Dispatch counts managers from git and a reporter
  cuts no branch in the child, so it cannot be counted there. The cost is
  named where the switch is documented: on, this is one session beyond
  `JOHARNESS_MAX_MANAGERS`.
- **Canonical reports nothing.** `JOHARNESS_CANONICAL=1` and `upstream` says
  CANONICAL and stops: findings here are already in the repo that owns the
  fix.

## Rejected

- **The orchestrator writing the report itself.** It edits one file, a
  killed manager's workstream file, and reads no plan. Giving it a second
  write and a second repository is the bound this mode inherited from
  `.agents/docs/unsupervised.md`, spent for nothing a spawn does not do.
- **A GitHub issue instead of a pull request.** The requester asked for pull
  requests, and an issue in canonical enters the queue ahead of plans with
  no evidence attached and no shape the graph lints.
- **Filing the fix.** A child asserting canonical's fix is the reverse of
  § 1 of `.agents/docs/feedback.md`: the signal that you fought the harness
  is not evidence the harness is wrong. The report carries the measurement
  and canonical decides.
- **A sixth bootstrap interview question.** `.agents/docs/orchestrated.md`
  already refused that cost for its own knobs; the sync naming the key is
  the channel that reaches a child.

## Review

Round 1 — `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet. Both reproduced every finding they
report in a scratch fixture; the two agreed on nothing, which is the argument
for running both.

- r1: (verifier) `fb_fix_map` prints the CROSS-PRODUCT of a commit's finding
  ids and its paths, so one commit fixing two findings — one on a harness
  path, one on this repo's own — attributes both paths to both findings, and
  `cmd_upstream` reports the repo-private one as a harness finding. Verified
  live: `r1 joharness.sh / r1 other.txt / r2 joharness.sh / r2 other.txt` from
  a two-finding commit. Routing a consumer's own defect to canonical is the
  one outcome the filter exists to prevent. (fixed: `upstream_multi_ids` names
  the ids whose fix commit carried more than one, and those findings are
  reported with the attribution flagged rather than silently trusted —
  `feedback`'s own commit-level blind spot, made visible where it now decides
  what leaves the repository)
- r2: (code-review) `upstream_edge` tested the MERGE-COMMIT shape before the
  branch shape, so a branch whose tip is a merge — which is every branch that
  reconciled at step 7, "Conflict at finish" — resolved as `<branch>^1..^2`
  and reported main's history under the branch's own label. Reproduced:
  `edge : 1d38299 (ed20979..65a1814)`, `NOTHING TO REPORT`, and the finding
  lost for good once the orchestrator writes `reported=<stem>`. (fixed: only
  real branch refs are tried as branches, and the merge test runs after)
- r3: (code-review) a finding with NO attributable path was counted as
  "landed on this repo's own files" and dropped. That is the normal shape of
  a `wontfix` or `no change` finding — recorded in a commit that touches only
  the workstream file — so the `[wontfix]` banner two screens below, which
  the code calls the strongest single signal it has, was unreachable.
  (fixed: no paths is its own bucket, not the repo's-own one)
- r4: (code-review) that unplaceable bucket printed finding text with no
  ownership filter and ALONE flipped the verdict to REPORT, so a consumer's
  own product-code finding could be carried verbatim into a pull request on
  the canonical — the outcome the sibling branch is written to prevent.
  (fixed: an unplaceable finding is placed by the paths its own TEXT names,
  through the same predicate; one that names none is listed as unplaceable
  and never flips the verdict on its own)
- r5: (verifier) the no-argument path reads the newest MERGE and says nothing
  when newer commits sit above it, so after a squash merge it reports a stale
  edge with no sign that it is stale. Reproduced: a true merge PR99 then a
  squash on top, and bare `upstream` still printed PR99. (fixed: commits
  above the merge are counted and named, with the branch-argument form as the
  remedy)
- r6: (code-review) `upstream_canonical_repo` duplicated `cmd_upgrade`'s
  inline `CANONICAL_REPO` parse character for character — two readers of one
  address, which is the shape `conf-keys.sh` exists to stop. (fixed:
  `cmd_upgrade` calls the helper)
- r7: (verifier) "no merge on origin/main to read" says the same thing when
  there is no `origin` remote at all. (fixed: the missing ref is named
  separately)
- r8: (verifier) selftest gaps: no case put two findings in one commit
  (so r1 was invisible to the suite), and none exercised the unattributable
  bucket, the `[wontfix]` banner, `upstream_path_note`, or the
  squash-detection branch — every one could be deleted or inverted and the
  suite stayed green. (fixed: cases for each, and each one checked to fail
  against the code as it stood before this round)
- r9: (verifier) checked and clean: report-only (no write command anywhere in
  `cmd_upstream`), off fails closed on an unrecognised value, the
  `JOHARNESS_CANONICAL` stop short-circuits before any edge lookup with the
  switch on as well as off, a path containing a space survives both walks,
  `HANDOVER_BASE_BRANCH` is honoured, and no requirement or plan is written by
  the automated path. (no change needed)

Each case written for a round-1 fix was run against `joharness.sh` as it stood
before the round (`git show 17040fc:joharness.sh`): 14 red without the fixes,
0 red with, 1658 passed either way otherwise. Two cases that were green both
ways were rewritten rather than kept — the shared-commit one asserted a text
that was present before the flag existed, and the reconcile fixture put the
retire commit after the merge, so the branch tip was not a merge at all and
the shape it was written to pin never occurred.

## Blockers

None.

## Where to look

- `.agents/docs/feedback.md:When the consumer is the detector` — the five
  steps this mechanizes.
- `joharness.sh:review_mode` — the off/on shape copied here.
