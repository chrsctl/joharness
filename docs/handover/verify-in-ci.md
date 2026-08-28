---
workstream: verify-in-ci
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: verify-in-ci
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Build the marker + CI job, rescope the prose, verify, review, finish
---

## Goal

Requirement `docs/product/verify-in-ci.md` arrived unplanned (landed mid-session
from PR 82) and planning outranks the plan queue. Decomposed into
`docs/plans/verify-in-ci.md`, executed here. Requirement's only plan, so the
PR retires the requirement file too.

## Decisions

- Discovery by per-layer MARKER FILE, not a layer name in the workflow. The
  requirement left the mechanism to this session. Decisive argument:
  `ci.yml` is seeded verbatim into every consumer, so a layer name there
  becomes a job every consumer on another layer runs meaninglessly. A marker
  in the layer's own directory also keeps the contract's "nothing outside the
  layer may name it" intact — no carve-out needed.
- Registry unreachable or rate-limited = warn and pass, not red. Straight
  from the requirement's constraint ("a flaky red gate is worse than no
  gate"). A real check failure stays red; only the precondition is soft.
- No Docker Hub login: fork pull requests get no secrets, so a login-based
  gate would be exactly the sometimes-red gate the requirement rejects.

## Rejected

- Hardcoding the layer in `ci.yml` (simplest): breaks every consumer that
  selects another layer, and puts a layer name in a file the layer rule
  exists to keep clean.
- Marking `python-rust` too: its setup downloads a toolchain rather than
  starting an already-present daemon, so it is a different claim needing its
  own measurement. The marker design lets it opt in later.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/env/README.md:Contract` — the layer file contract the marker joins.
- `joharness.sh:cmd_verify` — `JOHARNESS_ENV` overrides the selected layer.
