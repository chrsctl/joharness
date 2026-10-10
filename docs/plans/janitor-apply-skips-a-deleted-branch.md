---
plan: janitor-apply-skips-a-deleted-branch
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 397
scope: shared:joharness.sh, .agents/harness/selftest/janitor.sh, .agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md
---

## Goal

`janitor --apply` re-created a branch human had deleted on GitHub (gx,
2026-10-10, commit `4c31d894`). `janitor_apply` fetches with no `--prune`,
so `refs/remotes/origin/<branch>` survives the deletion; it then pushes
`<commit>:refs/heads/<branch>`, which creates the ref when origin has none.
Deleted branch = strongest form of released. Never push to it.

## Scope

- `joharness.sh:janitor_apply` —
  - fetch with `--prune`;
  - per branch, before writing: `git ls-remote --exit-code --heads origin
    <branch>`; absent = print `gone      : <branch> — gone on origin,
    nothing to release`, push nothing, no rc failure;
  - push with `--force-with-lease=refs/heads/<branch>:<tip>`, so a deletion
    or move between check and push is refused, not re-created.
- `joharness.sh:cmd_dispatch` — `janitor   : stale claim(s)` row: when
  `fetch_failed` is 1, append the existing stale-clone caveat (fetch failed,
  `DISPATCH_FETCH=0`, or `remote.origin.fetch` not reaching `refs/heads/*`),
  same wording as the fleet-age line.
- `.claude/commands/orchestrate.md` — step 0.1: `git fetch --prune origin`
  instead of `git fetch origin main` (still ff to `origin/main`).
- `.agents/harness/selftest/janitor.sh` — case: candidate branch deleted on
  the bare origin after local fetch; `--apply` prints `gone`, and
  `git ls-remote --heads <origin> <branch>` stays empty afterwards.
- `.agents/harness/selftest/dispatch.sh` — `DISPATCH_FETCH=0` with a janitor
  candidate: row carries the caveat.

## Out of scope

- `dispatch` fetch itself: already `git fetch -q --prune origin` in
  `cmd_dispatch` (since `72d5581`). Do not touch.
- A general `guard` subcommand: plan `guard-before-a-harness-push` (#398).
- Deleting branches. Human-only.

## Acceptance

- `bash .agents/harness/selftest.sh` — new janitor and dispatch cases pass.
- Revert `janitor_apply` change, rerun — deleted-branch case FAILS (branch
  re-created on fixture origin).
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS: consumers run `janitor --apply` from the orchestrator; selftest
  runs in their `verify`.

## Where to look

- `joharness.sh:janitor_apply` — `fetch -q origin`, `rev-parse ...
  refs/remotes/origin/${want}`, `push -q origin "${commit}:refs/heads/${want}"`.
- `joharness.sh:janitor_candidates` — reads `refs/remotes/origin/*`.
- `joharness.sh:cmd_dispatch` — `fetch_failed`, `jcands` row.
- `.agents/harness/selftest/janitor.sh` — "the banner, and --apply" block,
  bare origin `jorigin`.
- `.claude/commands/orchestrate.md` — "## 0. Start", step 1.

## Traps

- Test for fix must FAIL without it.
- Never `git push --delete`; janitor never deletes.
- Never skip, disable or quarantine a test to get green.
- No commit under `./joharness.sh protocol-paths`.
