---
workstream: advance-feedback-baseline
status: in-progress
branch: claude/advance-feedback-baseline
pr: none
plan: advance-feedback-baseline
issue: none
session: https://claude.ai/code/session_015z264uvdFedQU5bSeo8cgH
agent: sonnet
updated: 2026-09-02
next: Confirm the FB_SINCE bump clears the unmarked count to 0, run ci, open the PR
---

## Goal

`./joharness.sh sources` reported the sweep NOT dry: 4 unmarked findings
since the `FB_SINCE` baseline PR #161 set. Same-session plan
(`docs/plans/advance-feedback-baseline.md`) generated from that sweep,
executed on this branch per Lifecycle.

## Decisions

- Traced all 4 by hand: sourced `joharness.sh`'s own `fb_workstream`/
  `fb_findings`/`fb_marker` (minus the trailing `main "$@"` call) rather than
  re-implementing the parser, so the finding text is read exactly the way
  `cmd_sources` reads it. All 4 (`PR161 r6`, `PR172 r5`, `PR173 r2`,
  `PR174 r2`) merged before PR #181 closed the retire-commit loophole, and
  none can be edited in place (delete-on-merge already removed their
  workstream files from every tree). Same shape PR #161 baselined 155
  findings for; this moves the same literal past a second, later class of
  structurally-undispositionable debt.
- New baseline is `847f64e3`, PR #181's own merge commit — the point the
  gate went live, not an arbitrary later commit.

## Rejected

- Waiting for the retire-commit gate to somehow close these 4 itself. It
  can't: the gate only stops NEW undispositioned findings from merging: it
  has no mechanism to revisit history, and these four are already merged.

## Review

- r1: (session) checked the new baseline doesn't just move the goalposts
  arbitrarily — verified all 4 unmarked findings under the current baseline
  predate 847f64e3 by walking the actual merge list
  (`git log --first-parent --merges bcebb325e92f..origin/main`) and
  matching each PR number to its merge date against PR #181's. (fixed —
  reasoning recorded in the plan's Traps section)

## Blockers

None.

## Where to look

- `joharness.sh:FB_SINCE` — the literal this branch moves.
- `docs/plans/advance-feedback-baseline.md` — full Goal/Scope/Acceptance.
