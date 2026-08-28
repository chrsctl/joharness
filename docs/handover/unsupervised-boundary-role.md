---
workstream: unsupervised-boundary-role
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-boundary-role
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-28
next: Re-run the suite on the verifier fixes, then retire plan + workstream file and open the pull request.
---

## Goal

Issue #114: the unsupervised boundary names one path prefix while protocol
text now lives in two trees. `.claude/agents/verifier.md` is mandatory Loop
step 5 protocol and sits outside `.agents/harness/`, so the guard that
detects a crossing does not see an edit to it.

## Decisions

- Shape chosen by the requester 2026-08-28, offered three ways: state the
  rule by ROLE and back it with a path check. Wording alone was declined as
  unenforceable; naming both trees alone as stale on the next move. This is a
  ratified-requirement edit, which is why it was asked rather than decided —
  the issue says so in its own last paragraph.
- `.agents/env/` stays out. A layer is sandbox configuration, not protocol
  text; it does not govern a session's behavior, and sweeping it in would
  stop the mode provisioning anything.
- `.agents/docs/` stays out too, and this one is a judgement call worth
  recording: those files are the reasoning BEHIND rules rather than the rules
  a session executes. Including them is defensible and has a wider blast
  radius, so it is a separate decision rather than a silent widening.
- The list is FOUR trees, not the two the issue names: `.agents/harness`,
  `.claude/agents`, `.claude/commands`, `.claude/skills`. This followed from
  taking the role rule literally rather than from taste — a command writes
  the workstream file, a skill carries a Loop workflow, an agent is the
  reader the merge gate leans on. Each is a rule a session is judged by, so
  a boundary stated by role and then listing only two trees would have been
  the same defect again, one move later. The plan's scope said two; widening
  it is recorded here rather than done silently.
- Same-session plan: implementing here, so plan and workstream file retire in
  the same pull request as the code.

## Rejected

- Deriving the path list from `sync-to-consumer.sh:DIRS`. Tempting — the ship
  boundary and the protocol boundary overlap heavily, and this session just
  built a classifier over exactly those lists. Rejected because they answer
  different questions: DIRS ships `.agents/docs`, which stays out, and does
  NOT ship the boundary's own machinery, which has to be in. Reusing it would
  import one scope decision and miss another.
  (An earlier draft of this paragraph said `.claude/skills` was deliberately
  left out. It was not — it is in the list. The paragraph was written before
  the list widened and contradicted the Decisions section twelve lines up
  until a verifier read both.)

## Review

Round 1, `.claude/agents/verifier.md` at opus, on the full branch diff. It was
told mid-run to stop re-running the suite and report from reading; it did, and
found more by reading than the suite found by running.

- r1: REGRESSION against `origin/main`, and against the very scenario this
  work exists for. The `[ -e ]` filter dropped any protocol path absent from
  the worktree — which is exactly what DELETING one looks like. `git rm
  .claude/agents/verifier.md` went undetected here and was reported by
  `origin/main`'s guard on the same branch. Filter removed. (fixed)
- r2: that filter's stated reason was false. `git diff --name-only HEAD --
  absent/path` exits 0, not non-zero. Measured both ways. (fixed)
- r3: `protocol_paths()` lives in `joharness.sh`, which the list did not
  name — so the boundary's own definition sat outside it. The old hardcoded
  boundary lived in `.agents/harness/` and was self-protecting by accident of
  location; moving it out lost that. `joharness.sh` is now listed. (fixed)
- r4: `.claude/settings.json` wires the Stop hook that runs the guard at all.
  Delete the Stop block and nothing fires — not because the boundary passed
  but because nothing is running. Now listed. (fixed)
- r5: the fixtures iterated the list under test, so the list was unpinned —
  removing `.agents/harness` from it left the suite green, because zero loop
  bodies run silently. Contents asserted, and the loop counts what it ran.
  (fixed)
- r6: the completeness check hard-coded the `DIRS` two-space indent, so
  reindenting an unrelated file made every path `continue` and the check pass
  over everything. Indent-insensitive now. (fixed)
- r7: `## Satisfied when` still read "commits a change under
  `.agents/harness/`" — the acceptance criterion still path-shaped, still one
  tree. That line is what a session reads to conclude the rest is fair game,
  which is #114 in one sentence. (fixed)
- r8: the Constraints parenthetical restated two of the then-four paths — a
  second copy, wrong within an hour of being written, in the bullet whose own
  argument is that second copies rot. It now points at the function instead
  of repeating it. (fixed)
- r9: this file's `## Rejected` contradicted its `## Decisions` about
  `.claude/skills`. (fixed, and the contradiction recorded rather than erased)
- r10: this file said `status: in-progress` and `next: implement`, in the
  commit that implemented all of it. (fixed)
- r11: `$present` was an unquoted word-split, so a path with a space became
  two pathspecs matching nothing and a glob matched whatever was on disk —
  both silent. It is an array now, quoted. (fixed)
- r12: verified clean — only digits reach the unescaped JSON reason string.
- r13: verified clean — the old-entrypoint fallback exits 0 and does not
  claim a path it cannot resolve.
- r14: verified clean — the three constraints declined 2026-08-24 are intact.
- r15: verified clean — no environment layer named under `.agents/harness/`.
- r16 (open, wontfix here): the guard now forks `joharness.sh` twice per Stop
  and runs 4 git commands per listed path. `handover-guard.sh` is not in
  `perf_rows`, so nothing budgets it. Real, and out of this plan's scope —
  the plan's Out of scope says changing WHEN the guard fires is not this
  work. Worth its own plan; noted here so it is not lost.

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the boundary block; `grep -E
  '^\.agents/harness/'` is the entire mechanical boundary today.
- `joharness.sh:cmd_session_start` — the banner that states it to a session.
- `docs/product/unsupervised-mode.md` — Constraints, including the three the
  requester declined on 2026-08-24. Do not add those back.
