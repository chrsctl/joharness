---
plan: shallow-clone-reaches-authority
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 439
scope: shared:joharness.sh, .agents/harness/handover-context.sh, .agents/harness/selftest/authority.sh, .claude/commands/manage.md, .claude/commands/curate.md, .claude/commands/orchestrate.md
---

## Goal

A fresh cloud session clones 50 commits deep. The session-start hook
unshallows under a 15-second bound; on a long history (consumer gx, ~4000
commits) the fetch does not finish, `git merge-base HEAD origin/main` finds
nothing, and `./joharness.sh authority` reads UNVERIFIED with a cause that
names "a shallow clone or an unrelated branch" without saying which. The
role commands then stop, and the curator reported the same failure as a
"checkout differs" product problem (issue #439: 2 of 2 sonnet spawns on gx;
respawned with `clone_depth: 5000`, VERIFIABLE and merged in 12 minutes).
A session must not exit over a fetch it can run itself, and an
orchestrator must not spawn into the race.

Decided by the clerk (issue #439's four proposals): all four, in this shape —
a longer bound in the hook, a verdict that names the shallow cause and its
command, one unshallow-and-re-run in each role's authority step, and a
large `clone_depth` at spawn.

## Scope

- `.agents/harness/handover-context.sh` — the shallow fetch block: the `--unshallow` bound rises from 15 s to 60 s; the later NOTE text that says "did not finish in 15s" says the new bound.
- `joharness.sh` — `cmd_authority`: when `merge-base` is empty AND `git rev-parse --is-shallow-repository` is `true`, the UNVERIFIED verdict says `shallow clone` (not "or an unrelated branch") and prints the line `run: git fetch --unshallow origin, then authority again`; on a complete history it says the branch shares no ancestor and that unshallowing cannot help. `cmd_dispatch`'s own `timeout 15 … --unshallow` gets the same 60 s bound.
- `.agents/harness/selftest/authority.sh` — a case: shallow clone whose boundary hides the merge base → verdict text names the shallow cause and the `run:` line; a case: unrelated history, complete → no `run:` line.
- `.claude/commands/manage.md` step 1, `.claude/commands/curate.md` step 1 — UNVERIFIED that names a shallow clone: run `git fetch --unshallow origin` once (bounded, Bash `timeout`), re-run `authority`; still not VERIFIABLE = stop and quote `authority`'s verdict text verbatim, never a paraphrase.
- `.claude/commands/orchestrate.md` — the manager spawn rule (`create_session` line naming `source_url`, `model`, `title`) and every other `create_session` rule in the file: pass `clone_depth: 5000`.

## Out of scope

- A conf knob for the bound or the depth: `joharness.conf` is a core path.
- Removing the timeout entirely: a background command must be able to finish (Loop step 5).
- `clerk.md`, `scout.md`, `conduct.md` authority steps — not named by the issue; a later issue widens it if they hit it.
- Any change to the NOT VERIFIABLE (drift) branch of `cmd_authority`.

## Acceptance

- `bash .agents/harness/selftest/authority.sh` — passes; with the `cmd_authority` change reverted, the new shallow case FAILS.
- `grep -n 'timeout 15' .agents/harness/handover-context.sh joharness.sh | grep -c unshallow` — `0`.
- `grep -c 'clone_depth' .claude/commands/orchestrate.md` — at least `1` per `create_session` spawn rule in the file.
- `grep -n 'fetch --unshallow' .claude/commands/manage.md .claude/commands/curate.md` — one hit in each.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships (handover-context.sh, joharness.sh, role commands sync): consumer check = a consumer's `./joharness.sh authority` on a `git clone --depth 50` copy prints the `run:` line.

## Where to look

- `joharness.sh:cmd_authority` — the two UNVERIFIED branches.
- `joharness.sh:cmd_dispatch` — the second `timeout 15 … --unshallow`.
- `.agents/harness/handover-context.sh` — the `is-shallow-repository` fetch block near the top, and the `OWNED_UNVERIFIED` note that already distinguishes shallow from unrelated.
- `.agents/harness/selftest/authority.sh` — existing verdict cases to copy.
- `.agents/harness/selftest/handover-context-owns.sh` — how a selftest builds a shallow clone.
- `.claude/commands/orchestrate.md` — "Manager: `create_session` with `source_url` …".

## Traps

- Test for the fix must FAIL without it.
- Background or bounded commands only: every fetch keeps a `timeout`.
- Never edit `joharness.conf`, `.claude/settings.json`, `.github` (core paths).
- `joharness.sh` is `shared:`: merge `origin/main` in before the pull request.
