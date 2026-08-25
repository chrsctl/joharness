---
workstream: finish-gate-enforced
status: review
branch: claude/start-loop-b148yi
pr: none
plan: finish-gate-enforced
session: https://claude.ai/code/session_018e9SZFRciB3FXwrwUzLQJs
agent: opus
updated: 2026-08-25
next: Delete this file and docs/plans/finish-gate-enforced.md as the last commit before the pull request opens, then merge per Loop step 7
---

## Goal

`docs/plans/finish-gate-enforced.md`, urgent: `./joharness.sh finish` is a
correct gate nobody has to run, so step 7's delete-your-own-workstream-file
ritual keeps not happening — 22 merges passed over one finished file. Stage 4
of `.agents/docs/feedback.md` (Prevent) is what was missing: `cmd_ci` never
called `cmd_finish`.

## Decisions

- **The edge is read from the branch's diff, not its tree.** The plan said to
  copy the review gate's condition; copied literally it asks "is any workstream
  file in the tree at the edge", and every branch cut from a base branch
  carrying one stale file inherits a frontmatter saying `status: review`. See
  r1 — this is the whole shape of the change.
- **Two signals, both the branch's own work.** A workstream file this merge
  would ADD that is at the edge, or a workstream file this branch created and
  already retired. The second exists so the gate still speaks after you obey
  it (r2).
- **HEAD, not the working tree**, unlike the review gate. `ci` here has to
  predict GitHub's verdict on the pushed commit (AGENTS.md step 5); reading the
  working tree would red locally where CI goes green (r3).
- **`cmd_finish` called whole, not reimplemented.** The defect was two places
  disagreeing about whether the ritual happened; a second copy of the gate
  would be the same defect with more code.
- **No knob.** `JOHARNESS_REVIEW` is off by default because a review record is
  a judgment about depth. Deleting your own workstream file is not a judgment,
  and step 7 does not offer it as an option.
- **Silent below the edge, and silent on the base branch.** Mid-build ci output
  is byte-identical to `origin/main` — diffed, not asserted (see Acceptance).

## Rejected

- **The tree reading the plan asked for.** Rejected by running it: it reded
  this branch's own mid-build claim commit. r1.
- **`pr:` alone as the edge.** Narrower and quieter — a well-behaved session
  deletes the file before opening the pull request, so `pr:` with the file
  still present is only ever a mistake. Rejected because a session that never
  fills the field would slip through, and `status: review`/`done` catches it.
  The measured file had both set. Cost of keeping both is r10.
- **Dying inside `ci` when there is no base ref.** `cmd_finish` dies, and that
  is right for a command asked the question directly. Inside `ci` it would red
  every consumer whose CI checkout fetched only the pull request head. r9.
- **Fixing `cmd_graph`'s tree-vs-diff label (PR54 r13) while here.** Still
  out of this diff for the reason recorded there. Its class is now four edges
  deep, so it got a plan instead: `docs/plans/tree-vs-diff-rule.md`.

## Review

Opus tier, adversarial, three lenses (correctness / portability / does-it-
reproduce). Every new selftest case was proven red by mutating the
implementation, not by reading it — mutations listed under Acceptance.

- r1: correctness — the plan's own instruction ("copy that edge condition
  rather than inventing a second one") produces a gate that reads the TREE, and
  a branch inherits every file its base branch carries. This repo's `main`
  carries one stale file at `status: review`, so the first run of the wired
  gate reded this branch mid-build for a file it had merely inherited, naming
  its own live claim as the offence. Found by running it. Fourth appearance of
  the same tree-vs-diff class: PR54 r13 (`graph`), PR58 r8 (`upgrade`), PR60
  (`cleanup` deleted a live claim, `finish` passed on one). (fixed: the edge is
  computed from the branch's diff against the base; `feedback` says the class
  itself needs a rule, so `docs/plans/tree-vs-diff-rule.md` was seeded.)
- r2: a diff-based edge goes silent the moment the ritual is obeyed — the
  session that did it right gets no confirmation, and the base branch's own rot
  goes unnamed, which acceptance case 3 asks for. (fixed: second signal, "this
  branch created a workstream file and already retired it".)
- r3: the edge test reads HEAD while the review gate reads the working tree,
  and my first comment claimed the two gates agree by design. They do not, and
  the split is deliberate: `ci` must predict GitHub's verdict on the pushed
  commit, and an uncommitted frontmatter edit merges nothing. (no code change;
  the comment now states the split and its reason instead of the opposite.)
- r4: both gates fire on the same edge, so the existing review fixtures started
  reding for the finish gate and their `ci` exit codes stopped isolating the
  gate under test — "recorded review keeps ci green" failed for the other
  gate's reason. (fixed: the review fixture seeds its workstream file on the
  base branch so it is outside the merge's add-set; the two-workstream case
  asserts the standalone `review` exit code, which no other gate can satisfy.)
- r5: the base-branch guard was green for the wrong reason — mutating
  `on_base_branch` to `false` broke nothing, because a base branch in sync with
  its remote has an empty diff against itself and the edge test declines
  anyway. A guard whose test cannot fail is not tested. (fixed: the fixture now
  commits and retires a workstream file on `main` WITHOUT pushing, the only
  state where the guard is load-bearing; the mutation reds it.)
- r6: portability — SC2016, backticks inside a single-quoted `printf` format.
  The repo's bar is zero shellcheck findings. (fixed: `cmd_finish`'s own
  `'$0 finish'` quoting style.)
- r7: pre-existing, found while proving mid-build output unchanged — the suite
  does not unset `CLAUDE_PROJECT_DIR`, and every real session has it set. Under
  it, cases invoking the entrypoint without a per-call value resolve against the
  REAL repository: measured on `origin/main`, 7 cases fail and `mode
  unsupervised` lands in the developer's own `.git/joharness-mode`, flipping
  that checkout's autonomy for every later session. Invisible in the bare shell
  the suite is written and read in. Fixed here rather than recorded because
  `selftest.sh` is in this plan's scope and a suite that edits the tree it
  tests cannot be trusted about this plan's own acceptance. (fixed: unset it,
  plus `JOHARNESS_MODE`/`JOHARNESS_MODE_FILE`; a `suite isolation` case asserts
  the invariant, proven red by dropping the name from the list.)
- r8: cost — the new step ran `ci` twice per fixture state, once for output and
  once for the exit code. (fixed: one run, `jf_ci`.) Counted after, this
  machine: selftest 30.5s against `origin/main`'s 22.9s for 21 added cases over
  9 `ci` runs. The 15.2s in the previous workstream file is a different
  machine — counted, not read.
- r9: `cmd_finish` dies when no base ref resolves, and `ci` calling it would
  inherit that. (fixed: `ci` reports and passes, the doctrine churn and review
  already follow; `finish` invoked directly still dies. Both paths have cases.)
- r10: `ci` is red from `status: review` until the workstream file is deleted,
  so a session records its review findings under a red run. Considered and
  kept: the plan names both conditions, the red says exactly what to do next
  ("delete them as the last commit before the merge"), and the sequence still
  terminates green — findings are recorded while the file exists, the deletion
  is last. (no change needed.)
- r11: read what this diff already cost other branches, as the review step
  asks (`./joharness.sh feedback .agents/harness/selftest.sh`). PR58 r8 fires
  against this diff and is r1 above, arriving from a different command. PR54 r5
  (the fixture shellcheck stub) still holds: the new step reads no shellcheck
  output and no exit code shellcheck owns. (no change needed.)

## Blockers

None.

## Where to look

- `joharness.sh:finish_at_edge` — the two signals, and the comment on why the
  tree reading is wrong here. Get this wrong and the gate reds every branch for
  the base branch's rot.
- `joharness.sh:cmd_ci` — the call site: base branch, then ref, then edge. The
  no-ref arm is deliberately not a red.
- `.agents/harness/selftest.sh` — `step "joharness.sh ci: the finish gate"`,
  21 cases. The mid-build pair is the r1 regression; the unpushed-`main` pair
  is r5's, and it fails for nothing else.
- `.agents/harness/selftest.sh` — the `unset` block at the top, r7. The suite
  writes into the real repo without it.
