---
plan: shallow-clone-reaches-authority
urgency: normal
agent: opus
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
a longer bound in the hook that stays under the SessionStart hook timeout, a verdict that names the shallow cause and its
command, one unshallow-and-re-run in each role's authority step, and a
large `clone_depth` at spawn.

## Scope

- `.agents/harness/handover-context.sh` — the shallow fetch block: the `--unshallow` bound rises from 15 s to 40 s, and the fallback plain fetch runs only when the unshallow FAILED fast, not after it timed out (exit 124), so the block's worst case stays near 40 s. Before choosing, read Claude Code's documented default SessionStart hook timeout (`.claude/settings.json` sets none and is a core path): the whole hook must finish under it; a lower bound than 40 s is right if the documented timeout demands it. Record the figure and its source in `## Decisions`. The later NOTE text that says "did not finish in 15s" says the new bound.
- `joharness.sh` — `cmd_authority`: when `merge-base` is empty AND `git rev-parse --is-shallow-repository` is `true`, the UNVERIFIED verdict says `shallow clone` (not "or an unrelated branch") and prints the line `run: git fetch --unshallow origin, then authority again`; on a complete history it says the branch shares no ancestor and that unshallowing cannot help. `cmd_dispatch`'s own `timeout 15 … --unshallow` gets a 60 s bound (dispatch is a command, not a hook).
- `.agents/harness/selftest/authority.sh` — a case: shallow clone whose boundary hides the merge base → verdict text names the shallow cause and the `run:` line; a case: unrelated history, complete → no `run:` line.
- `.claude/commands/manage.md` step 1, `.claude/commands/curate.md` step 1, and the `authority` step in `.claude/commands/orchestrate.md` — UNVERIFIED that names a shallow clone: run `git fetch --unshallow origin` once (bounded, Bash `timeout`), then run `authority` a second time; still not VERIFIABLE = stop and quote `authority`'s verdict text verbatim, never a paraphrase. manage.md's "ONCE, FIRST" gains this one named exception in the same sentence (the second run is still before any checkout or edit); `cmd_authority`'s NOT VERIFIABLE "never as a re-check later" text stays as is — it is about the drift branch.
- `.claude/commands/orchestrate.md` — every instruction that spawns a session with `create_session` and a `source_url` (the "Manager: `create_session` with `source_url` …" line, and the role-table spawn that says "`create_session` like a manager"): pass `clone_depth: 5000`. The Claude Code Remote `create_session` tool schema offers `clone_depth` (read 2026-10-13 by the clerk session).

## Out of scope

- A conf knob for the bound or the depth: `joharness.conf` is a core path.
- Removing the timeout entirely: a background command must be able to finish (Loop step 5).
- `clerk.md`, `scout.md`, `conduct.md` authority steps — not named by the issue; a later issue widens it if they hit it.
- Any change to the NOT VERIFIABLE (drift) branch of `cmd_authority`.

## Acceptance

- `bash .agents/harness/selftest.sh` (the runner; topic files are not runnable alone) — the new `authority` cases print PASS; with the `cmd_authority` change reverted (`git stash` the hunk), the shallow case prints FAIL. Never run a file under `selftest/` directly: it writes fixtures at `/`.
- `grep -n 'timeout 15' .agents/harness/handover-context.sh joharness.sh | grep -c unshallow` — `0`; and `grep -n 'timeout [0-9]* .*--unshallow' .agents/harness/handover-context.sh joharness.sh` — one hit in each file (the bound is kept, not removed).
- `grep -n 'clone_depth' .claude/commands/orchestrate.md` — a hit on the manager spawn line and on the role-table spawn line; read each.
- `grep -n 'fetch --unshallow' .claude/commands/manage.md .claude/commands/curate.md .claude/commands/orchestrate.md` — one hit in each.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships (handover-context.sh, joharness.sh, role commands sync): consumer check = in a consumer, `git clone --depth 1 --no-single-branch -b <an unmerged branch whose tip is not on main> <url> c && cd c && ./joharness.sh authority` prints the shallow verdict and the `run:` line (a plain `--depth 50` clone of main does not: HEAD is origin/main, so a merge base exists).

## Where to look

- `joharness.sh:cmd_authority` — the two UNVERIFIED branches.
- `joharness.sh:cmd_dispatch` — the second `timeout 15 … --unshallow`.
- `.agents/harness/handover-context.sh` — the `is-shallow-repository` fetch block near the top, and the `OWNED_UNVERIFIED` note that already distinguishes shallow from unrelated.
- `.agents/harness/selftest/authority.sh` — existing verdict cases to copy.
- `.agents/harness/selftest/handover-context-owns.sh` — how a selftest builds a shallow clone.
- `.claude/commands/orchestrate.md` — "Manager: `create_session` with `source_url` …".

## Traps

- Test for the fix must FAIL without it.
- `cmd_authority` is the gate every unattended role trusts: a wrong-but-plausible verdict there passes review. Opus tier for that reason.
- The hook bound must stay under the SessionStart hook timeout: a killed hook loses the whole handover output.
- Background or bounded commands only: every fetch keeps a `timeout`.
- Never edit `joharness.conf`, `.claude/settings.json`, `.github` (core paths).
- `joharness.sh` is `shared:`: merge `origin/main` in before the pull request.
