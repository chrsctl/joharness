---
workstream: harness-review
status: review
branch: claude/harness-research-review-l4y9vv
pr: 6
session: https://claude.ai/code/session_01HBRP6Z9bv2vV1tf5yebWvA
agent: sonnet
updated: 2026-08-21
next: Human review + merge; then fix stale pre-split paths in the three in-flight workstream files (see Blockers)
---

## Goal

Full review of the harness (both layers), research-informed suggestions,
fixes for what the review turned up. Human clarified intent: run agents
fully mobile — each new session gets told entrypoint and model tier up
front, without spelunking.

## Decisions

- New `harness/queue-context.sh` in session-start: prints plan queue from
  origin/main (urgent first, then oldest), each with agent/effort
  frontmatter, plus entrypoint suggestion. That is the mobile flow: hook
  output = what to do + which model.
- `agent:` field added to handover TEMPLATE frontmatter; both hooks surface
  it ("wants opus"), so resuming user picks the right model too.
- New `harness/selftest.sh` wired into `joharness.sh ci` (so GitHub CI runs
  it): harness scripts had zero coverage beyond shellcheck. Git-only, scratch
  repos, 24 checks.
- Scope excludes what in-flight branches own: helm smoke coverage
  (smoke-helm-coverage), K3S_IMAGE bump (k8s-136-validation), sync script
  (harness-sync).

## Rejected

- Stop-hook enforcement of "update handover before ending turn" — blocking
  Stop hooks need stop_hook_active loop guards and JSON parsing; wrong
  cost/benefit while the discipline works. Revisit if handover files start
  arriving stale.
- Reading GitHub issues in queue-context.sh — shell hook has no `gh` in
  every consumer; queue prints "issues outrank plans" pointer instead.
- refs/claims mutual exclusion — already weighed and rejected in
  docs/handover/README.md; nothing new changes that.

## Blockers

None for this branch. Found, not fixable from here: all three in-flight
workstream files (harness-sync, k8s-136-validation, smoke-helm-coverage)
reference pre-split paths — `scripts/devenv.sh`, `scripts/smoke-test.sh`,
`docs/environment.md` are now `env/k8s/*` and `env/k8s/README.md`. Whoever
resumes those branches: merge main first, fix paths per staleness rule.

## Where to look

- `harness/selftest.sh` — fixture quirk: git drops a directory when a branch
  switch removes its last tracked file; mkdir -p before each heredoc.
- `joharness.sh:cmd_env` — spurious "not usable" fallback warning when
  JOHARNESS_ENV was unset (fixed; selftest covers it).
