---
plan: unfinished-background-work
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/handover-guard.sh, .agents/harness/AGENTS.md, .agents/harness/selftest/handover-guard.sh
---

## Goal

Requester, 2026-09-05, after watching one: "ensure in the protocol that no
script ever not finished". A background shell spun for 1h 17m in this
session and nothing noticed. The command was

```bash
until ! pgrep -f "bash .agents/harness/selftest.sh" >/dev/null; do sleep 3; done
```

and it could never exit: `pgrep -f` matches full command lines, the loop's
own shell command line CONTAINS that pattern, so it matched itself forever.
The selftest it waited for had finished long before. It was found by the
human reading the background-tasks panel, not by the harness.

Two things follow, and only one of them is a rule.

## Scope

- `.agents/harness/AGENTS.md`, step 5 — the rule, caveman: a background
  command must be ABLE to finish. Bound it, or give it a condition it
  cannot satisfy itself; never `pgrep -f` a pattern the command's own line
  carries.
- `.agents/harness/handover-guard.sh` — the fact. At Stop, count the
  processes this session started that are still running, and name the
  count. The guard is the only mechanism that can catch this class at all:
  the loop was TYPED, never committed, so `ci` cannot lint it and no
  hook that reads git can see it.
  - Find the agent process by climbing the guard's own parent chain.
  - Count its descendants, minus the guard's own subtree.
  - Measured 2026-09-05 in this container: an environment daemon started
    by `./joharness.sh setup` reparents to PID 1 (`dockerd` ppid 1,
    `containerd` its child), and the agent process has no other standing
    children — so the count is 0 on a session that left nothing running,
    with no special-casing.
- `.agents/harness/selftest/handover-guard.sh` — cases: a session with a
  live background child reports it; one with none stays silent; the
  guard's own subtree is never counted; no agent ancestor reports nothing.

## Out of scope

- Killing anything. The guard reports facts and never acts, which is the
  doctrine its every other fact already follows.
- Failing a session. Same reason: it is a Stop hook, it fires when a
  session is least attentive, and a fact that blocks is a fact that gets
  routed around.
- A `ci` lint for the pattern. The command was never in a file; a repo
  lint would catch a shape nobody commits and miss the one that bit.
- Any process supervisor, timeout wrapper, or new entrypoint subcommand.
  The harness has no daemon and this needs none.

## Acceptance

- `.agents/harness/handover-guard.sh` with a live background child of the
  agent process emits the fact and names a count.
- With none, the guard's output is unchanged from today.
- The reason string carries digits only, never a command line: it embeds
  in JSON unescaped, and a process command line is attacker-shaped input.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh mutate` on the counting line reds at least one case.

## Where to look

- `.agents/harness/handover-guard.sh` — `add_fact`, and the boundary fact
  whose "count only, never a path" rule this follows for the same reason.
- `.agents/harness/selftest/handover-guard.sh:guard` — the helper that
  feeds the hook its JSON and captures the reason.
- `.agents/harness/AGENTS.md` step 5 — where NEVER kick CI sits.

## Traps

- A fact that fires on every stop is one readers learn to skip. The
  environment daemons are the obvious false positive and they reparent to
  PID 1; prove that in a case rather than trusting this line.
- The guard must never fail a session: no `ps`, no ancestor, anything
  unexpected — exit 0, say nothing.
- The guard's own subtree is a descendant of the agent process too.
  Counting it reports at least one process on every single stop.
