---
workstream: upkeep-off-session
status: in-progress
branch: claude/upkeep-off-session
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-25
next: Open PR for the upkeep rule and its enforcement
---

## Goal

Requester ratified a rule: joharness management tasks must never dilute an
actual session. Came out of asking whether `./joharness.sh upgrade` could
run in a subagent to keep the main session's context clean — the mechanism
already existed (`update.yml` in every consumer, cron plus
`workflow_dispatch`), but nothing said to prefer it, so the expensive route
was as reachable as the free one.

## Decisions

- The rule binds CONSUMERS only, and both files say so in as many words.
  In canonical the harness IS the product: a session working on the harness
  here is doing the work, not diluting it, and `upgrade` refuses to run
  anyway. Left implicit, a literal reader in this repo would read "harness
  upkeep does not belong in a session" and stop working entirely.
- Preference order goes in the route table itself, not in prose beside it.
  The table is what a session reads; a rule stated only above it is a rule
  half the readers skip.
- Reviewing the update pull request stays with the session. Reading a sync
  diff is the cost being avoided; judging whether the sync is right is the
  part that does not delegate, and it is cheap by comparison.
- Recorded the missing-CI-token trap where the route is chosen rather than
  only in `update.yml`'s own comment. A route that silently yields
  unchecked pull requests is worse than a slower one.

## Rejected

- A subagent for the upgrade. It shares this container and this repo's
  tree, and an upgrade runs in a consumer — wrong checkout. Worktree
  isolation isolates a copy of joharness, not of the consumer.
- Enforcing the rule in `ci`. Whether a session is "holding product work"
  is not a git fact, so any check would guess. Stated as a rule where the
  route is chosen instead.
- Widening it to all harness protocol work (handover, review, the finishing
  ritual). Those ARE the Loop, not upkeep of the tool, and a rule that
  swept them in would read as licence to skip them.

## Review

- r5: the rule as first written was a preference, and the preference sat
  above a doc that still spelled the in-conversation ritual out as the
  normal route — branch, dry-run, upgrade, ci, commit, push. In practice a
  child updates in conversation, so a preference changes nothing: the
  convenient path is the one taken. `upgrade` now REFUSES when the branch
  carries a workstream file, which is the same fact the handover guard and
  the queue already read as "this session holds claimed work". It fires
  exactly when there is work to dilute and never on a sync branch, which
  carries no workstream file by protocol. (fixed)
- r6: a refusal with no escape turns a genuine mid-plan sync into a dead
  end. `JOHARNESS_UPGRADE_IN_SESSION=1` overrides, deliberate and visible,
  the same shape as the churn ceiling's `JOHARNESS_CHURN_LIMIT=0`. Silence
  is what the rule prevents, not the act. (fixed)
- r7: the check sits BEFORE the canonical clone, so the selftest proves the
  refusal with no network. `TEMPLATE.md` and `README.md` are asserted not
  to count as claims — a fixture that only planted a real workstream file
  would have passed with a sloppier `find`. (fixed)

- r1: first draft put the rule only in `consumer-repos.md`, which a session
  reads when it already decided to sync. Moved the binding line into
  `.agents/harness/AGENTS.md`, which loads every session, and left the
  reasoning in the doc. (fixed)
- r2: the canonical exemption was one clause at the end of a paragraph. A
  literal reader in canonical could act on the first sentence and stop.
  Given its own paragraph in both files, naming the conf line that decides
  which repo it is reading. (fixed)
- r3: docs-only diff, so `verify` is out of scope (step 7 scopes it to
  non-`*.md` files under four paths). `ci` covers the graph lint. (no
  change needed)
- r4: checked every branch on the remote for edits to
  `.agents/harness/AGENTS.md` or `consumer-repos.md` before touching them —
  `AGENTS.md` carries 5 feedback edges and is the hottest file in the repo.
  None in flight. (no change needed)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md`, "Harness upkeep" — the binding rule.
- `.agents/docs/consumer-repos.md`, "Pick route" — the reasoning, the
  preference order, and the missing-token trap.
- `.github/workflows/update.yml` — the mechanism the rule routes to, and
  the comment that documents the suppressed CI runs.
