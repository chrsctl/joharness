---
workstream: idle-analysis
status: in-progress
branch: claude/worker-idle-detection-l3v9m3
pr: none
plan: idle-analysis
issue: 266
session: https://claude.ai/code/session_01TsLnukcKvuRKLXcJ34BLhg
agent: opus
updated: 2026-09-17
next: Decide with the human whether to open the pull request; the retire commit (plan + this file) goes last, before it opens
---

## Goal

Issue #266, requester's ask: second env-gated mechanism beside
`JOHARNESS_UPSTREAM_FEEDBACK`, off by default, enabled in a child repo,
detecting and reporting WHY a manager idles or takes too long. Orchestrator
spawns an ANALYST for it. Child repo files the finding as a GitHub issue on
joharness (requester, this session).

## Decisions

- Plan first, same-session plan on this branch (`.agents/docs/plans/README.md`,
  Lifecycle). Direct human ask, so nothing builds unplanned.
- Artifact is a GitHub ISSUE on the canonical, not the reporter's research-node
  pull request. Requester said issue; and the subject is fleet behaviour at run
  time, not a finding attached to a merged diff — often no fix to assert.
- Analysed unit is the MANAGER, never the worker subagent. Requester's word is
  "worker"; the roles table spells the thing with a branch and a session
  `manager` (`.agents/docs/orchestrated.md`, Roles). Follow the table.
- No new threshold knob. Triggers are the marks `dispatch` already computes:
  `blocked`, `STALL?`, `LOOP?`. A fourth written number buys nothing.
- Block AGE stays with `docs/plans/unowned-block-age.md` (issue #254). This
  work anchors on the commit that last restated the cause, which needs no
  `git log -S` and no threshold.

- Artifact of the analyst is a GitHub ISSUE on the canonical, not the
  reporter's research node. A merged edge carries a diff to attach a finding
  to; a stuck one carries a condition and a clock, which is the shape of the
  bug report a human files — #266 IS that artifact, written by hand after the
  fleet could not.
- `analysis` anchors on the commit that last CHANGED the claim's workstream
  file, not on the age of the block. Answers "has config moved since this
  branch stated its cause" with one `git log -1`, and steps around the `-S`
  trap `docs/plans/unowned-block-age.md` documents.
- Verdict wording is `CAUSE MAY BE LIFTED`, never `LIFTED`. The command knows
  a conf key moved; it cannot know the key answers the prose in `next:`.
  Asserting that mapping would be #266's own defect inverted.
- `joharness.sh` reads EVERY `JOHARNESS_` assignment out of each ref's conf
  rather than the list `.agents/scripts/conf-keys.sh` declares: that file is
  canonical-only and `joharness.sh` ships to every consumer, so a reader keyed
  on it would read a file that is not there.
- One awk, not `sed` into awk, for that parse: `\t` in a sed replacement is a
  GNU extension and a literal `t` on BSD sed — green on the runner, mangled on
  a macOS checkout.
- No fourth knob. The marks fired on are the ones `JOHARNESS_STALL_MINUTES`
  and `JOHARNESS_CHURN_LIMIT` already draw.

## Rejected

- `needs: unowned-block-age`. Would block this plan behind that one for a
  timestamp this work can read itself, and the two readings answer different
  questions (how long has it stood / has config moved since).

## Review

- r1: dispatch's ANALYSE? case asserted against a claim whose plan file was
  never in the queue, so the row was in no in-flight listing at all and the
  case measured an empty section. Fixture now queues `docs/plans/parked.md`
  and `working.md` (fixed)
- r2: `git revert -q` in the selftest — `-q` is not a flag revert takes, so
  the fixture printed git's usage and left the update workflow deleted for
  every case after it. Replaced with a checkout of the parent's copy plus an
  assertion that the address reads again (fixed)
- r3: the verdict line spelled `next:` in backticks inside a single-quoted
  printf; shellcheck SC2016 reds `ci` on it. Reworded to "the next: line",
  and the selftest case now pins that wording (fixed)
- r4: the conf list flooded — a branch parked for weeks printed every conf
  commit since, 16 lines for one row on this repo (2026-09-17,
  `JOHARNESS_CONF=<scratch> ANALYSIS_FETCH=0 ./joharness.sh analysis`).
  Capped at the newest three plus a count and the command that reads the
  rest (fixed)
- r5: a sweep printed a row per healthy manager. `analysis_one` now buffers
  and prints only rows carrying a condition, counting the rest; a named
  branch still prints whatever it is (fixed)

- r6: (verifier) `CAUSE STANDS` was printed after reading zero bytes of conf —
  a repo whose `joharness.conf` is untracked produced a verdict about config
  it never read. #266 one layer up: the analyst concludes the block is live
  and files nothing. Now `NOT ANALYSABLE`, with a fixture (fixed)
- r7: (verifier) the conf delta was one-directional — keyed on the base
  branch's list, so a key the BRANCH carries and the base lacks was never
  compared, and the verdict then asserted no key differs. Union of both
  sides, `(absent)` either way (fixed)
- r8: (verifier) a conf commit that changed no assignment — a comment reword,
  a base-branch merge — flipped the verdict to `CAUSE MAY BE LIFTED` with no
  key under it. Commits are now filtered by what CHANGED, each naming the key
  and both values, at most `ANALYSIS_CONF_SCAN` opened (fixed)
- r9: (verifier) measured on this repo 2026-09-17, 143 refs: 7 rows, 7 `CAUSE
  MAY BE LIFTED`, 0 otherwise — a verdict every row gets carries nothing.
  r7/r8 removed the false half; what remains is real movement on branches
  three weeks old, each now naming its key, and the analyst's gate is what
  decides (fixed)
- r10: (verifier) `NO CONDITION` appeared in no instruction file, and it is
  exactly what an analyst reads when the condition cleared between the pass
  and its spawn. Documented in the role's table and the plan (fixed)
- r11: (verifier) one branch carrying two claims emitted the same `ANALYSE?
  /analyst <branch>` twice while the ledger keys on the stem — two sessions
  beyond the cap on one prompt that cannot tell them apart. The mark and the
  command now name the CLAIM (fixed)
- r12: (verifier) the role file and the plan said "declared conf key" while
  the code reads every `JOHARNESS_` assignment on purpose — and undeclared
  keys are what the real run surfaces. Wording corrected in both (fixed)
- r13: (verifier) `analysis_on` was called twice in `cmd_analysis`, so a bad
  value warned twice, the second landing between the verdict and the tail.
  Resolved once, as dispatch already does (fixed)
- r14: (verifier) the plan's `scope:` omitted `.agents/harness/selftest.sh`,
  which the diff modifies, and the `JOHARNESS_UPSTREAM_FEEDBACK` line added to
  its unset guard was declared nowhere. Both now in the plan (fixed)
- r15: (verifier) r6, r7, r8 and r11 all stayed green with the suite as
  written, and the stall-knob case pinned the echo of the knob rather than the
  comparison. Cases added for each, and the knob case now decides an outcome
  on a branch pushed seconds ago (fixed)
- r16: (verifier) `</dev/null` was applied to some git calls in the new
  functions and not others, inside loops fed by here-strings — the class this
  repo already paid for. Applied throughout (fixed)
- r17: (verifier) the help text and two docs said the command reports "every
  unmerged branch", which the r5 sweep suppression made false. Reworded, and
  the divergence from dispatch's plan-keyed rows named (fixed)
- r18: #266's OWN shape produced neither mechanical signal: the key landed on
  the base branch 8h47m before the session existed and the branch carried it,
  so nothing differed and nothing moved. The command would have said the cause
  stands on the incident it was written for. Now the base branch's current
  answers print for every row carrying a condition (`conf now :`), and the
  no-movement verdict says in so many words that it is not "the cause is
  live" (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:upstream_mode` — the switch shape this one copies.
- `joharness.sh:cmd_dispatch` — where the `analysis :` line and the `ANALYSE?`
  mark land.
- `.claude/commands/upstream-report.md` — the spawned-role command file shape.
