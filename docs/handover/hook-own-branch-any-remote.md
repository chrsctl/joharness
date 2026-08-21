---
workstream: hook-own-branch-any-remote
status: review
branch: claude/hook-own-branch-any-remote-k2p9wz
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
updated: 2026-08-21
next: Deleted in the next commit; PR body links to this blob. Expect a conflict with claude/harness-research-review-l4y9vv in the same loop
---

## Goal

Running `harness/handover-context.sh` on a fork-based branch printed my own
push back at me as another session's work, with a false `TOUCHES THE SAME
FILES AS THIS BRANCH`. The hook excludes `origin/$branch`; a second remote's
copy of the same branch is a different ref name, so it survives the filter.
Anyone without push access to this repo works from a fork, so the first
outside contributor meets this immediately — and the warning it produces is
the one the protocol tells them to act on.

## Decisions

- Match on the branch name with the remote prefix stripped (`${short#*/}`),
  not on a hardcoded `origin/`. A same-named branch on any remote is the same
  workstream: that is what the naming convention means.
- Same treatment for the base branch in the no-workstream-file path, where
  `origin/$BASE_BRANCH` was likewise the only spelling excluded.

## Rejected

- Reading the configured upstream (`git rev-parse --abbrev-ref @{u}`) and
  excluding that. Excludes exactly one remote, so a checkout with both a fork
  and `origin` still reports whichever one is not the upstream.
- Filtering `refs/remotes` down to a single remote. The cross-branch read is
  the feature; a contributor genuinely wants to see `origin`'s other branches
  while pushing to a fork.

- Second defect found while verifying the first: a fork mirrors every branch,
  so each workstream was listed twice. Where `origin` carries the name, that
  is the entry shown. Same principle as the self-exclusion, so it belongs in
  the same change rather than a second PR.

## Measured

On this checkout, `origin` plus one fork, six real branches in flight:

- Before: 11 entries listed, 3 of them the session's own branch, 4 branch
  names duplicated. `MAX_ENTRIES` is 12 — one more fork branch and real work
  falls off the end silently.
- After: 6 entries, one per branch, no self-entry.
- `shellcheck -x harness/handover-context.sh` — zero findings.

## Blockers

None.

## Overlap — read before resuming

`claude/harness-research-review-l4y9vv` (status `review`, session
`01HBRP6Z9bv2vV1tf5yebWvA`) edits the same loop in the same file, adding an
`agent:` frontmatter field and replacing the second `files_at "$ref"` call
with `<<<"$ws_files"`. Checked its diff before writing: it does not touch
remote-name handling, so the changes are complementary, but they land within
a few lines of each other and the second merge will conflict. It also edits
`joharness.sh:cmd_ci` and `docs/handover/README.md`, both of which
`claude/handover-rot-enforcement-8chuvt` edits too.

`/who` was not run: this session has no Claude Code Remote tool. Liveness of
that branch is therefore unknown, not idle — treat it as possibly live.

## Where to look

- `harness/handover-context.sh` — the `while IFS= read -r ref` loop; two
  `continue` guards near the top, one more inside the no-workstream-file case.
