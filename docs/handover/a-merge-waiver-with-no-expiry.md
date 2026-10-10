---
workstream: a-merge-waiver-with-no-expiry
status: review
branch: research/a-merge-waiver-with-no-expiry
pr: none
plan: a-merge-waiver-with-no-expiry
issue: none
session: https://claude.ai/code/session_013j5vBC7PvSpbqHNLW43Pxv
agent: opus
updated: 2026-10-10
next: Retire this file, open PR, finish, merge, message @parent
---

## Goal

Settle `docs/research/a-merge-waiver-with-no-expiry.md` — does any reader of
`JOHARNESS_CHECKS` consult anything but its value — graduate the answer into
`.agents/docs/orchestrated.md`, delete the node.

## Decisions

- Graduation only: no manage.md edit and no follow-up plan; the node itself declined to propose one, so the wording defects are named as leads in orchestrated.md and the PR body.
- Cite symbols (`checks_mode`, `num_knob JOHARNESS_HEALTH_MINUTES 10`), not line numbers: the node's line numbers had all drifted by 2026-10-10.

## Rejected

- Carrying the node's "manage.md is CORE ONLY": `./joharness.sh protocol-paths` lists joharness.conf, .claude/settings.json, .github only.

## Review

- r1: (verifier) "no code path reaches the network at all" false — `git fetch` in analysis and finish paths (fixed: "only network reach is git fetch, no path reads Actions")
- r2: (verifier) "both fixes refused" drops the surviving half of fix 1, never end the turn between PR and merge (fixed: one and a half refused, survivor stated)
- r3: (verifier) /manage §4 lead stale — a second condensed copy, follow-up-plan line, landed 2026-10-10 (fixed: lead names both)
- r4: (verifier) ci.yml quote ellipsis changed meaning; workflow reads the var at the lint job `if:` (fixed: cites the value-only `if:` read, quote trimmed)
- r5: (verifier) workstream file not in the graduation commit (fixed: updated in the next commit, this one carries the review)
- r6: (verifier) node's lead on the `checks_mode` comment "the same checks" dropped silently (fixed: carried as second lead)
- r7: (verifier) 10-to-20 minutes not sourced (fixed: cites `num_knob JOHARNESS_HEALTH_MINUTES 10`)
- r8: (verifier) "fires sooner" vs the recorded cloud nudge/respawn gap above (fixed: says table as written, execution gap is separate)
- r9: (verifier) "no comment for the key" understates consumer-repos.md "no line" (fixed)
- r10: (verifier) row enumeration missed blocked and throttled-FAILED rows (fixed: scoped to status review/done, throttled excepted)

## Blockers

None.

## Where to look

- `.agents/docs/orchestrated.md` — the runner-outage / #266 paragraph the answer lands beside.
