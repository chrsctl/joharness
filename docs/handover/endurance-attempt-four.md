---
workstream: endurance-attempt-four
status: review
branch: claude/current-state-review-oxfb7f
pr: none
plan: unsupervised-endurance
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Retire this file and the plan in the last commit before the pull request, then open and merge it
---

## Goal

Attempt four at the requirement bullet "Started once, the fleet keeps going
for hours with no human turn" was driven from this session on 2026-09-02.
This workstream carries what the plan's Acceptance still wanted after the run
ended: the requirement bullet annotated with the result AND with what the run
did not show, and `joharness.conf` back to `supervised`.

## Decisions

- **The run went ahead without a heartbeat, and the report says one
  generation.** The plan's gate 2 is "whether a heartbeat exists for this
  run", and its own answer for the no-heartbeat case is explicit: "report the
  result as one generation and say so — do not quietly re-run the same
  experiment and call the number endurance."
- **The annotation leads with the SUPERVISED ONLY crossing, not with the
  wall-clock.** Both sessions edited protocol text on marked plans and one
  crossing reached origin. That is the run's largest finding, it contradicts
  the reading this file's first draft carried, and the plan's Scope makes a
  finding the result.
- **A's refusal is recorded as prose, not as a table row.** The plan's table
  column is *what stopped it*, and the refusal stopped nothing — A ran the
  Loop afterwards.
- **The plan is retired by this pull request.** Its Acceptance is met, every
  bullet including the revert, even though the bullet it advances stays
  unsatisfied. A done plan left on `main` is a plan the next fleet claims,
  and this one costs a paid run to claim.

## Rejected

- **Annotating the bullet as satisfied, or partly satisfied.** 60 minutes is
  the same quantity the three runs before it measured; the plan's own Trap
  says 57 minutes is not hours. Three earlier annotations on this requirement
  omitted the not-shown half and each had to be corrected later.
- **Calling either session's ending a legitimate stop.** A said "attempt four
  complete" and B said "queue clear, no pending work". An empty queue is this
  mode's trigger, not its stop, so both are findings under the plan's Scope.
- **Fixing the marking gap the run exposed.** The plan's Out of scope is
  explicit: findings become plans, this one measures. The gap — nothing makes
  a session at the generate-work edge read the marking before claiming its
  own plan — is recorded in the annotation for whoever writes that plan.

## Blockers

None here. One thing this pull request cannot resolve and hands to the human:
`origin/claude/gastown-review-owjgzg` holds a second, unmerged claim on this
same plan (`docs/handover/unsupervised-endurance.md`), and retiring the plan
leaves that file naming one that no longer exists on `main`. Its session is
IDLE and disconnected (`list_sessions`, 2026-09-02), and a session never
pushes to another session's branch.

## Review

Round one — verifier at opus on ce8024c, three passes (correctness, does-it-
reproduce, style); each finding re-checked against its source before being
accepted.

- r1: (verifier) the annotation reported PR 187's marking as a success —
  "the fleet could not carry them further" — when both sessions carried a
  marked plan further and one crossing reached origin. Re-checked and
  confirmed here: `435b29f` claims `gate-review-verifier-tag` at 19:10:22Z,
  57 seconds after `e1e9e3b` merged it at 19:09:25Z; `3448ab8` says it was
  "Caught by the handover-guard stop hook, not before starting"; `eb13f0d`
  edits `joharness.sh` and `git merge-base --is-ancestor eb13f0d
  origin/main` is true (fixed — rewritten as the run's real finding, with
  the reason: nothing makes a session at the generate-work edge read the
  marking before claiming its own plan)
- r2: (verifier) the whole table carried no producing command and no date,
  against the plan's own Trap and Acceptance; `$10.07`/`$13.69` had no
  source in the repo at all (fixed — `list_sessions` fields and session ids
  named, plus the shorter git-anchored window a reader without that list can
  re-count, plus the reconcile shas)
- r3: (session, correctness) PR 189 was cited beside PR 187 as a mechanism
  the run exercised. It was not: PR 189 is the goal-reached stop, and the
  goal stayed open by construction for the whole run. The `sources` fix that
  did run is `84d9aef`, an ancestor of `db481b2` — PR 187 (fixed — PR 189
  citation dropped)
- r4: (verifier) "against all three of its recorded caveats" — bullet
  three's annotation records four, the annotation answered two, invented a
  third and silently dropped "one cycle" (fixed — two answered, two named as
  standing)
- r5: (verifier) "verified from two sessions independently" — the cited
  record is one session making two probes (fixed, in both the annotation and
  `joharness.conf`)
- r6: (verifier) the step-7-unreachable chain dropped "and no `gh` on the
  runner", which is the link that makes it follow (fixed)
- r7: (verifier) the plan's Scope asks for session count and generations;
  neither had a number (fixed — both in the table, generations as an
  explicit zero)
- r8: (verifier) "fourteen minutes" carried no command, and the nearest
  git-anchored figure is different (fixed — the anchored figure is 15m 49s
  from session creation to `1c607b7`, and the annotation says plainly that
  the refusal itself is from a transcript and is not re-countable from the
  repository)
- r9: (verifier) the paragraph naming the missing heartbeat as what ended
  the run silently merged two questions — what ended generation one is each
  session declaring itself done (fixed — both stated, separately)
- r10: (verifier) a second, unmerged claim on this plan exists on
  `origin/claude/gastown-review-owjgzg`, and retiring the plan orphans it
  (fixed as far as a session can — recorded under Blockers and handed to the
  human in the pull request body; a session never pushes to another
  session's branch)
- r11: (verifier) this file justified overriding that claim with "its
  blockers are answered by the run", but its second blocker is the cap
  VALUE, which is money and the human's alone (fixed — that bullet is gone;
  the cap was answered by the requester's direct instruction, recorded in
  `joharness.conf`, not by the run happening)
- r12: (verifier) the run left two SUPERVISED ONLY plans on `main`, moving
  its own successor's dry-sweep stop further away, and nothing said so
  (fixed — Residue paragraph)
- r13: (verifier) no blank line between attempt two's conclusion and the new
  block, so markdown rendered attempt four's headline as the tail of attempt
  two's paragraph (fixed)
- r14: (verifier) `## Review` present and empty, which the template and
  Loop step 5 both forbid (fixed — this section)
- r15: (verifier) the requirement records attempt one and attempt two then
  jumps to attempt four; the bridge lived only in the plan this pull request
  retires (fixed — the count is restated in the annotation's first sentence)
- r16: (verifier) `joharness.conf` read as a live flip over a reverted
  value, and repeated the run's numbers a second time against "state each
  fact once" (fixed — block rewritten, numbers left to the requirement)
- r17: (verifier) no `- rN:` form violations, frontmatter complete, no
  glossary banned spellings anywhere in the diff (no change — clean)

## Where to look

- `docs/product/unsupervised-mode.md` — the `Satisfied when` bullet the
  annotation lands under, beside the three earlier runs' annotations.
- `docs/plans/unsupervised-endurance.md` — the plan, retired by this pull
  request; its `BEFORE YOU START` gates and its four-wall table are what the
  annotation answers.
- `origin/claude/gastown-review-owjgzg:docs/handover/unsupervised-endurance.md`
  — the other claim on this plan, and the connector-trap evidence (r1, r10)
  the annotation cites for why no heartbeat exists.
