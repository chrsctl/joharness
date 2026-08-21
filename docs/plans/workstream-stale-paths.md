---
plan: workstream-stale-paths
urgency: normal
agent: haiku
effort: medium
needs: none
---

## Goal

Three in-flight workstream files predate the harness/env split and cite
paths that no longer exist. Next session resuming any of them follows dead
anchors. Fix the files where they live.

## Scope

- Branches `claude/harness-sync`, `claude/k8s-136-validation`,
  `claude/smoke-helm-coverage`: merge `origin/main` in, then in that
  branch's `docs/handover/*.md` replace pre-split paths —
  `scripts/devenv.sh` and `scripts/smoke-test.sh` are now under `env/k8s/`,
  `docs/environment.md` is now `env/k8s/README.md`.
- Push each branch. Merge commits, no rebase — not your branches.

## Out of scope

- The work those files describe (sync script, v1.36 validation, helm
  coverage). Fix paths only.
- Any file outside `docs/handover/` on those branches.

## Acceptance

- Per branch: `git show origin/<branch>:docs/handover/<file>.md | grep -cE 'scripts/(devenv|smoke-test)\.sh|docs/environment\.md'` = `0`.
- `./joharness.sh ci` = `ci: pass`.

## Where to look

- `docs/handover/README.md` § Staleness — the rule this plan executes.

## Traps

- `/who` first: a `RUNNING` session on one of these branches = skip that
  branch, it fixes its own file.
- Never rewrite history on these branches — merge, commit, push only.
