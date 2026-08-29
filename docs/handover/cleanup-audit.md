---
workstream: cleanup-audit
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: cleanup-audit
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire the plan and this file, open the PR, merge it.
---

## Goal

Four findings the verifier returned against `cleanup` in PR54's replay were
never checked against today's tree. Carry them: reproduce or close each with
evidence, fix the ones that survive, and leave a regression case per fix.

`cleanup --apply` is the subcommand that deletes tracked files, and the one
whose mistake removes a live claim.

## Decisions

- Running at opus against a `sonnet` plan. Escalation is allowed and
  downgrade is not; the reason is that three of the four findings turn on
  what a command does in a state nobody normally builds (detached HEAD, a
  failed `git rm`, an unpushed live claim), and building those states
  correctly is where a wrong reading gets recorded as a verdict.
- **All four behaviours reproduce; only three were defects.** Finding 1's
  behaviour is the decided protocol, not an omission — see the Rejected entry
  and r1. The plan asked for a verdict per finding and no silence; this is
  finding 1's, and it is a closure with evidence rather than a fix.
- **The four behaviours: all REPRODUCE.** The plan required a verdict per finding
  and no silence, so each was rebuilt from scratch on `main` at `f603f87`,
  2026-08-29, one state per scratch repo — not four states in one, which is
  how a stale probe reads as a fresh measurement.
  1. A `status: in-progress` file merged to `main`, no branch carrying it:
     reported `stale`, and `cleanup --apply` staged its deletion
     (`git status` after: `D  docs/handover/live-part2.md`). `status:` was
     read nowhere in the file.
  2. A leftover with local modifications: `git rm` refused, the run warned,
     then printed `none — the ritual ran` and exited **0**, with the file
     still on disk. Every counter missed it.
  3. `git rev-parse --abbrev-ref HEAD` prints the literal `HEAD` when
     detached. On branch `main` the base-branch warning fired once; detached
     at the same commit, zero times.
  4. The plans section tested `[ -f "${ROOT}/docs/plans/${p}.md" ]` under a
     heading that says `plans on <ref>`. Deleting the plan in the working
     tree only, with it still on `origin/main`, turned `ask
     docs/plans/keepme.md` into `none`.
- **Finding 2's fix changes an exit code, and that is deliberate.** Counting
  the failure stops the `none — the ritual ran` line, but a caller reading
  `$?` would still have seen success for work that did not happen.
  `--apply` now returns 1 when a removal was refused; the report-only path
  still exits 0, because nothing was attempted there so nothing failed.
  Safe at every reachable caller, and the reason is not the one first
  recorded here. `ci` DOES reach `cleanup` — 15 invocations, 7 of them
  `--apply`, all through `selftest.sh` (measured by instrumenting
  `cmd_cleanup` and running `./joharness.sh ci`). It survives because
  `selftest.sh` runs `set -uo pipefail` with no `-e` and every call site
  captures the status in a command substitution. `.github/workflows/` has
  zero references, and no hook or slash command invokes it. See r5.
- **Finding 3's fix changes the warning's wording**, from "on the base
  branch" to "no branch to carry these deletions" — the condition is no
  longer "which branch is this" but "is there a branch at all". Two existing
  selftest assertions read that string: one would have gone red and the
  other, a `refute`, would have gone vacuously green. Both updated, and both
  renamed, because a `refute` named for the old condition is a `refute` the
  next reader trusts for the wrong reason.

## Rejected

- **Reading `status:` off the ref to protect a live file — written, then
  reverted in full.** It is the obvious fix for finding 1 and it is wrong,
  for a reason this repo had already written down three times:
  `.agents/docs/handover/README.md` ("Original carve-out: ... check only
  flagged `status: done`. This protocol's own file then merged carrying
  `status: review` — finished work, wrong label, guard silent"), the finish
  gate in `joharness.sh` ("**No frontmatter is read, deliberately.**") and
  `handover-context.sh` ("This deliberately does not look at `status`").
  The plan's own `## Where to look` points at the first of those. I opened
  it for the status-values table and did not read eleven lines further, which
  is the Loop step 4 rule — open the anchors, every claim a hypothesis until
  checked — failing on the one anchor the plan named.
  Counted, 2026-08-29: of the **13** workstream files ever retired from
  `origin/main`, 8 carried `in-progress` and 5 carried `review`. **Zero
  carried `done`.** The carve-out would have made `--apply` a no-op on every
  leftover the command has ever existed to remove, with no override and no
  summary line to say so.
  What covers the case instead is where the protocol already puts it: push
  the branch and `cl_inflight` sees it. Loop step 3 — no push, no claim.
- **Widening `cl_inflight` to notice the unpushed part-2 session.** The other
  shape that suggests itself, and the plan names it as a Trap: `853f551` paid
  for that filter. Not attempted.

## Review

Round 1, opus, `.claude/agents/verifier.md` (verifier) — 13 findings, two of
them blockers against fix 1. Recorded before their fixes and in the same
commit.

- r1: (verifier) **Fix 1 made `cleanup --apply` a no-op on every leftover
  this repo has ever had.** Of the 13 workstream files ever retired from
  `origin/main`, 8 said `in-progress` and 5 said `review`; none said `done`.
  Replayed on the real historical state, `main` at the parent of the merge
  that removed `upkeep-off-session.md` — the case `cleanup.sh` names as the
  measured one the command exists for — `f603f87` stages two removals and the
  branch staged none. No `--force`, no override. (fixed — fix 1 reverted in
  full; re-counted the 13/8/5/0 independently before acting)
- r2: (verifier) **Fix 1 reinstated a rule recorded three times as tried and
  rejected**, one of them in the file the plan's own `## Where to look`
  names. (fixed — reverted; the closure and all three citations are in
  Rejected and in the topic file, so the next reader finds them where the
  carve-out would go)
- r3: (verifier) Fix 1 put `cleanup` in direct contradiction with
  `handover-context.sh` and with the command `finish` sends the reader to:
  same file, one says "your pull request deletes your workstream file", the
  other refused it. (fixed — reverted)
- r4: (verifier) **Fix 1 turned four existing regression tests green over
  nothing.** `beta.md` in the fixture carries `status: review`, so the new
  `live` branch produced the same `keep` line the `kept` branch used to:
  sabotaging `cl_inflight` gave `931 passed, 0 failed` on this branch against
  `914 passed, 4 failed` on `main`. The protection `853f551` paid for was
  unpinned. (fixed — reverted, and re-checked: the sabotage now fails those
  four again, `922 passed, 4 failed`)
- r5: (verifier) "Checked before changing it: nothing in `ci` calls
  `cleanup`" does not reproduce. Instrumented, `ci` reaches `cmd_cleanup` 15
  times, 7 of them `--apply`. The conclusion holds; the stated reason was
  false. (fixed — Decisions carries the real reason: no `set -e` in
  `selftest.sh`, and every call site captures the status)
- r6: (verifier) Fix 1 silently did not apply to a CRLF workstream file —
  `gr_fields` exits on line 1 when it is `---\r`, so the status read empty
  and the live file was removed. Unsafe direction. (moot — fix 1 reverted)
- r7: (verifier) `set -o pipefail` coupled fix 1's guard to a SIGPIPE from
  `git show`, so a large enough file flipped `keep` to `stale`. Measured at a
  300KB/400KB boundary. (moot — fix 1 reverted)
- r8: (verifier) Fix 1 read the status off the ref and the existence off the
  working tree, so a session resuming an inherited workstream was unprotected
  by the very branch meant to protect it. (moot — fix 1 reverted)
- r9: (verifier) Fix 1 had no escape hatch, no summary line when every file
  was kept, and `status: Done` kept a file forever. (moot — fix 1 reverted)
- r10: (verifier) The recorded revert count for fix 3 does not say which
  revert it means. Measured both: **1** reverting the condition and keeping
  the wording, **3** reverting the hunk as it stands. (fixed — both stated,
  here and in the commit)
- r11: (verifier) One new assertion used the same needle in the same state as
  an existing one, and a `refute` kept a name describing the old condition.
  (fixed — the duplicate is named as the fixture's baseline for the detached
  comparison, and the `refute` is renamed for what it now guards)
- r12: (verifier) Fix 3's rationale said the detached case is "exactly the
  checkout CI produces"; per r5's own measurement CI reaches `cleanup` only
  through `selftest.sh`, never detached. (fixed — the comment names the
  reachable case and says what the sharper-sounding claim got wrong)
- r13: (verifier) `cleanup --apply` returning 1 staled a comment calling it
  report-only, and the usage header documented no exit code. (fixed — both)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_cleanup` — all four live here or in what it calls.
- `joharness.sh:cl_inflight`, `decide_ref` — the two helpers the already-fixed
  findings landed in. `853f551` paid for `cl_inflight`'s filter; do not widen
  it (plan Traps).
- `.agents/docs/handover/README.md` — the `status:` values finding 1 turns on.
