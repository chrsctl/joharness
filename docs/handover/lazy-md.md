---
workstream: lazy-md
status: review
branch: claude/joharness-review-1nb29t
pr: none
plan: none
session: https://claude.ai/code/session_01KJKDHSDB5YrjCqUMHthgbV
agent: sonnet
updated: 2026-08-21
next: Open PR to main (edge review done, findings fixed)
---

## Goal

Human asked (mid repo review): lazy loading of md files. Session start
injected the whole selected layer's AGENTS.md into every session's context,
paid whether the session touched the environment or not. Same waste lazy
setup already fixes for provisioning.

## Decisions

- New knob `JOHARNESS_ENV_MD` (conf + env var, like the other two). `lazy`
  = session start prints a read-before-touching pointer instead of the
  file. Mirrors `JOHARNESS_ENV_SETUP` naming so the contract stays one
  pattern.
- Default stays `eager`: consumers sync harness code but not joharness.conf,
  so a lazy default would silently drop rules from their sessions. This repo
  opts in via conf.
- Scope is the env layer's AGENTS.md only. CLAUDE.md @-imports are Claude
  Code's own mechanism, not the hook's; harness/AGENTS.md is the working
  protocol and must stay eager.

## Rejected

- Lazy default in code — consumers would lose trip-wire injection without
  ever having chosen to.
- Size threshold (inject small files, point at big ones) — two behaviors
  from one knob, unpredictable from the conf alone.
- Neutralizing exported knobs inside selftest's jo() via `${VAR-}`
  pass-through — bash cannot tell a caller's export from a per-call prefix
  assignment there; global `unset` at script top is the working isolation.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_session_start` — the lazy branch; pointer text is the
  whole safety story, keep it imperative.
- `harness/selftest.sh` — RULE-SENTINEL fixture proves eager injects, lazy
  withholds and points.
