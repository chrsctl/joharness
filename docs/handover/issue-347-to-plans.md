---
workstream: issue-347-to-plans
status: in-progress
branch: claude/issue-347-to-plans
pr: none
plan: none
issue: 347
session: https://claude.ai/code/session_01CCJwzDzgwtqXeQuhNQH1RW
agent: opus
updated: 2026-10-10
next: Retire this file, open PR, merge
---

## Goal

Human ask: "Issues to plans". 21 open issues, 2026-10-10. Each number was
checked against `docs/plans/`, `docs/research/` and `main`'s log. Only #347
(orchestrate.md names the wrong messaging route) has no plan, no research
file and no fix. Break it into plans.

## Decisions

- Covered by a queued plan: #339, #311, #308, #307, #304, #303, #300, #298,
  #297, #292, #283, #258.
- Covered by a research file or a merged first cut: #305 (consumer-repos
  red-base section merged in #349; `where-a-red-base-reading-goes` open).
- Already fixed on `main`, the issue just left open: #293 (`janitor.md`
  Never line now says "spawn anything but the step 5 reader"), #291 (no
  case count left in `janitor.md`), #284 (throttled FAILED row), #279
  (#341, #344), #254 (holds count on the row, janitor release,
  unowned-block-age #324), #249 (janitor cadence,
  scheduler-outside-the-fleet #316).
- #279: defects 1-3 and the curate-cycle reader fixed (#341, #344). Defect 4
  (a release push resets the STALE age) is still in the code. The issue
  calls it "may be acceptable as designed", so it is left as designed, not
  planned. The human decides whether to close.
- #251: `.agents/docs/orchestrated.md` leaves the sampling conduct reviewer
  to the human. That is a HUMAN verdict, so no plan. It is flagged in the PR
  body.
- #347 splits in two. The messaging route is in `orchestrate.md`,
  `manage.md` and `orchestrated.md`. The secondary ask (GitHub lost after
  the retire commit) is in `manage.md` step 4 only. The issue itself says
  the secondary "may be its own plan".

## Rejected

- Reverting the retire commit when GitHub is lost after it (first draft of
  `retire-survives-lost-github`). Once a PR is open, the revert puts the
  workstream file and the done plan back on a head a human may merge.
  `dispatch_retired_edges` already covers a branch past its retire.

## Review

Verifier at opus, 2026-10-10, on 95384c0.

- r1 (verifier) retire plan: revert reaches a mergeable PR head → revert dropped; rely on the existing retired-edge path.
- r2 (verifier) retire plan: Goal misread dispatch as IDLE; `dispatch_retired_edges` not anchored → Goal rewritten, anchor added.
- r3 (verifier) retire plan: `status blocked` anchor missing its backticks → fixed.
- r4 (verifier) retire plan: retry counts disagreed → one failure is the answer in both rules.
- r5 (verifier) retire plan: effort medium below default → high.
- r6 (verifier) messaging plan: SHIPS named the selftest, which is canonical-only → consumer `ci` + grep.
- r7 (verifier) messaging plan: `send_message` grep already passes → pinned verbatim sentences, before/after counts.
- r8 (verifier) messaging plan: absence check beaten by reflow; `expect` for absence → folded-text `refute`.
- r9 (verifier) messaging plan: orchestrated.md "never in the server" clause left standing → rewrite ordered and checked.
- r10 (verifier) messaging plan: merge-line gate contradicts the Trap → tool-presence gate accepted there, reason stated.
- r11 (verifier) messaging plan: own-id via `get_session` unmeasured → measure in build, env fallback, record.
- r12 (verifier) Traps missed overlapping plans → added `orchestrated-only`, `orchestrated-only-docs`, `manager-ceiling-row` and others.
- r13 (verifier) workstream: #279 overstated as fixed → defect 4 recorded as left by design.
- r14 (verifier) messaging plan: "wording exactly as now" vs new address; restart case → placeholder may change; id from control plane by title.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — Tools paragraph, degradation table, NUDGE row, spawn merge line.
- `.claude/commands/manage.md` — `## 4. Finish`.
