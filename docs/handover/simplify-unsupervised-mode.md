---
workstream: simplify-unsupervised-mode
status: in-progress
branch: claude/joharness-simplification-43gm7n
pr: none
plan: simplify-unsupervised-mode
issue: none
session: https://claude.ai/code/session_01EoG4neinP69y2mzeumTgvk
agent: opus
updated: 2026-09-02
next: Suite and ci green on the reconciled head, then retire the plan and workstream file and open the pull request
---

## Goal

Direct ask 2026-09-02: simplify joharness, unsupervised mode first. Plan:
`docs/plans/simplify-unsupervised-mode.md`.

## Decisions

- Direct human ask = supervised work. `joharness.conf` flips to
  `supervised` in the claim commit; attempt four is over (its branch
  `claude/current-state-review-oxfb7f`, session RUNNING, reverts the same
  line and annotates the requirement — that annotation is folded into the
  runs table here, not duplicated).
- Hook REPORTS, `drain` ORDERS. One reader of the queue decides fan-out,
  generate, or stop. The hook keeps the SUPERVISED ONLY marking because
  rank is a property of the listing.
- Stop condition: goal reached, or sweep dry with the queue empty and no
  edge work in flight. The "second dry sweep" and "no open pull request"
  parts were uncountable from the harness and made the stop unreachable
  without flags a session had to assert by hand.
- Mode sources: conf and `$JOHARNESS_MODE`. The marker was a third route
  `authority` then had to distrust; PR 163's own annotation records that a
  marker-flipped run never made "the repo is set to unsupervised" true.
- `drain` never runs `sources`. That call is what closed the ci, perf,
  drain, sources cycle (42-minute runner, run 33414519009); with drain
  naming the sweep instead, the recursion guard and its root-scoped marker
  go too. The sweep stays a session's explicit command.
- The queue hook keeps exactly two mode-dependent outputs: the SUPERVISED
  ONLY marking (with the undeclared-scope and boundary-unread notes that
  belong to it) and nothing else. The identity test in
  `queue-context-edge.sh` pins that, on fixtures carrying the entrypoint
  and scoped plans, so the marking notes cannot hide a new order.
- The endurance plan file is untouched: claimed on a RUNNING session's
  branch that retires it. Its "Where to look" names two symbols this
  branch removed; `lint_anchors` checks paths only, and the file leaves
  with that branch.

## Rejected

- Removing the mode outright. Not asked for.
- Merging `claude/current-state-review-oxfb7f` first. Its session is
  RUNNING (`list_sessions` 2026-09-02) — not mine to merge (step 7).
  Reconcile at finish instead.

## Review

Opus depth: `/code-review` high, plus `.claude/agents/verifier.md` driven
over six scratch fixtures. Both ran `ci` on the head: pass, 1259 passed, 0
failed (2026-09-02).

- r1: (verifier) hook at the unsupervised edge printed the supervised tail — "top free plan above", "every plan claimed or blocked" — over a SUPERVISED ONLY plan, and the rewritten test pinned it. (fixed: unsupervised edge line names the marking and exits; the refute is back)
- r2: (verifier) hook under unsupervised with two unscoped plans said "Spawn one per plan" while drain said never, and no counter-order remained in the output a session reads first. (fixed: under unsupervised the hook's last line is always the pointer at drain, via an EXIT trap; edge test asserts it)
- r3: (verifier) drain printed "dry STOP — no edge work above" unconditionally, under edge work it had named; docs said drain "prints which stop fired" though it never runs the sweep. (fixed: dry line reads the edge; docs say drain prints GOAL REACHED and names the sweep beside the parts it read)
- r4: (verifier) the stop condition moved from the ratified two-sweeps, no-open-pull-request form without a flag to the human. (recorded: product direction, decided and written down per Decide alone; flagged in the pull request and the closing report)
- r5: (verifier, code-review) `.agents/harness/AGENTS.md` /drain paragraph still said one stop. (fixed)
- r6: (verifier, code-review) 78s/3s and "5 of 119 gaps" lost the commands that produced them. (fixed: commands restored beside the numbers)
- r7: (verifier) drain named an unscoped oldest plan as next while ordering a wave-1 spawn and forbidding unscoped plans. (fixed: under unsupervised next is wave 1's first member, taken here; the rest are spawned)
- r8: (verifier) drain ordered a spawn under edge work it had just said outranks the queue. (fixed: the order carries an edge-first line when edge work is in flight)
- r9: (verifier) `cmd_sources` comment still said "the mode's one stopping point". (fixed)
- r10: (verifier) plan Acceptance said "unknown subcommand" for `mode unsupervised`; it dies "takes no argument". (fixed: plan text)
- r11: (verifier, code-review) `selftest.sh` CLAUDE_PROJECT_DIR note still narrated the marker file. (fixed)
- r12: (verifier) the deleted case "does not tell an unattended session to ask a human" left the no-plans wording unpinned. (fixed: the pointer follows every exit, and the edge test asserts it is the last line)
- r14: (PR 195, folded at reconcile) attempt four's real finding: both generated plans were SUPERVISED ONLY and both sessions claimed and edited them without reading the marking — a session that writes a plan at the edge and claims it passes through neither hook nor drain. (fixed: drain's NOT dry line says re-run drain before claiming; recorded in the runs table. The mechanical gate the annotation asks for is a plan of its own, not this one)
- r13: (code-review) SUPERVISED ONLY prose appears in both the GOAL REACHED and NOT YOURS blocks of `cmd_drain`. (no change needed: two stops, one extractor, different sentences)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — both stops and the fan-out order live here now.
- `.agents/harness/queue-context.sh` — mode-dependent blocks reduced to the marking.
