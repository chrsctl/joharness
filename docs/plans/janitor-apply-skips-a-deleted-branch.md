---
plan: janitor-apply-skips-a-deleted-branch
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 397
scope: shared:joharness.sh, shared:.agents/harness/selftest/janitor.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md
---

## Goal

`janitor --apply` re-created a branch human had deleted on GitHub (gx,
2026-10-10, commit `4c31d894`). `janitor_apply` trusts
`refs/remotes/origin/<branch>`, then pushes `<commit>:refs/heads/<branch>`,
which creates the ref when origin has none. With the default refspec
(`+refs/heads/*:refs/remotes/origin/*`) that ref does not survive: dispatch
runs first and fetches `--prune` (already so at `298b9ac`), so the deleted
branch has no ref and `janitor_apply` takes its existing `skip … no such
branch on origin` path. The ref survives only under a narrow refspec (e.g.
`remote.origin.fetch=+refs/heads/main:refs/remotes/origin/main`): `--prune`
prunes only refs its refspec maps, so a stale `refs/remotes/origin/<branch>`
outlives the deletion. That is the gx case — a ref surviving a pruning
dispatch means its refspec did not reach the branch. Fix: ask origin itself
(`ls-remote`), not the local ref. `--prune` on janitor's own fetch is
secondary: covers the default refspec when `--apply` runs without a
dispatch first. Deleted branch = strongest form of released. Never push to
it.

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
- `.agents/harness/selftest/janitor.sh` — case: candidate branch fetched,
  then `git config remote.origin.fetch +refs/heads/main:refs/remotes/origin/main`
  in the work clone, then branch deleted on the bare origin; `--apply`
  prints `gone`, and `git ls-remote --heads <origin> <branch>` stays empty
  afterwards. Second case, default refspec, same deletion: `--apply` prints
  `skip … no such branch on origin` (the prune path; must not regress).
- `.agents/harness/selftest/dispatch.sh` — `DISPATCH_FETCH=0` with a janitor
  candidate: row carries the caveat.

## Out of scope

- `dispatch` fetch itself: already `git fetch -q --prune origin` in
  `cmd_dispatch` (since `72d5581`). Do not touch.
- A general `guard` subcommand: plan `guard-before-a-harness-push` (#398).
- Deleting branches. Human-only.

## Acceptance

- `bash .agents/harness/selftest.sh` — new janitor and dispatch cases pass.
- Revert `janitor_apply` change, rerun — narrow-refspec case FAILS (branch
  re-created on fixture origin). A fixture on the default refspec would pass
  unreverted: the prune already hides the ref.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS. No consumer command reaches the `gone` path without a real
  deleted branch under a narrow refspec, and the selftest does not ship
  (`sync-to-consumer.sh` `CANONICAL_ONLY` lists `.agents/harness/selftest.sh`,
  `CANONICAL_ONLY_DIRS` lists `.agents/harness/selftest`). Consumer check is
  the synced text: in a consumer after sync, `grep -c 'gone on origin'
  joharness.sh` — non-zero; `./joharness.sh janitor --apply no-such-branch`
  — `skip`, nothing pushed.

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
