---
plan: no-unbounded-waits
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/pretool-bash-guard.sh, .agents/harness/selftest/pretool-bash-guard.sh, .agents/harness/selftest.sh, .claude/settings.json, joharness.sh, .agents/harness/AGENTS.md
---

## Goal

Requester, 2026-09-05, after the guard from `unfinished-background-work`
fired on the session that shipped it: "maybe infinite loops should not
exist". Two commands in one session could not finish, and both were caught
after the fact — one by a human reading the background-tasks panel at 1h
17m, one by the stop guard at 18m. A rule tells a session what not to type
and a count says what it left behind; neither stops the command. This plan
adds the stage that does: refuse the command before it runs.

The two, verbatim, because the check is judged against them:

```bash
until ! pgrep -f "bash .agents/harness/selftest.sh" >/dev/null; do sleep 3; done
until grep -q 'joharness' /tmp/.../tasks/bn2t9hnge.output 2>/dev/null; do sleep 20; done
```

The first can never exit — `pgrep -f` matches full command lines and the
loop's own shell carries the pattern, so it matches itself. The second
waited for a string the file could not contain, because the command that
wrote the file had already narrowed it with `tail`. Different mistakes,
one shape: a wait with no bound on how long it waits.

## Scope

- `.agents/harness/pretool-bash-guard.sh` — new. PreToolUse hook on the
  Bash tool. Reads the tool payload's `command`, and DENIES (exit 2, with
  the reason on stderr — the one channel a PreToolUse hook has that the
  model reads) when the command holds a wait that cannot end:
  - a `while` or `until` loop whose body contains `sleep`, unless the
    command is bounded — `timeout` anywhere in it, or the loop's condition
    carries an iteration counter;
  - `pgrep -f` or `pkill -f` inside such a loop, bounded or not: the
    pattern is in the command line that runs it, so it matches itself.
    Name that in the reason, it is not obvious.
  Everything else passes silently, including a `for` loop, a `while read`
  over input, and a loop with no `sleep` in it.
- `.claude/settings.json` — register it under `PreToolUse` with
  `"matcher": "Bash"`, ending `|| exit 0` like the existing entry, for the
  same reason: a truncated or CRLF-mangled copy dies at parse time with
  status 2, which this event reads as DENY. A broken hook must not wedge
  the Bash tool.
- `.agents/harness/selftest/pretool-bash-guard.sh` — new topic, registered
  in `.agents/harness/selftest.sh`. Cases below.
- `joharness.sh` — a `perf` row for the new entrypoint. It runs on EVERY
  Bash call, which is the one hook where a fork per call is felt.
- `.agents/harness/AGENTS.md` — the step 5 rule gains one clause: the
  harness now refuses the shape, and the deny message names the two legal
  spellings. Keep it to a clause; the rule already says the thing.

## Out of scope

- An escape hatch. `JOHARNESS_ALLOW_UNBOUNDED=1` would be typed by the
  next session that hits a false positive, and then it is a rule again.
  If the check is wrong, narrow the check.
- Killing or reaping anything at Stop. The stop guard reports and never
  acts; that stands. This plan adds a gate at the other end, it does not
  change that end.
- A `./joharness.sh wait-for` helper, or any new entrypoint subcommand.
  The deny message teaching `timeout N` is the whole affordance.
- Bounding non-loop commands that can hang (`tail -f`, `nc -l`, a test
  suite with no timeout). Real, and a different plan: the two measured
  incidents are both wait loops, and a gate that fires on things nobody
  got wrong is a gate sessions learn to route around.
- Reading `run_in_background`. Foreground and background arrive as the
  same tool with the same `command`; the text is what is checked, and a
  foreground unbounded wait is the same bug with a shorter fuse.

## Acceptance

- `.agents/harness/selftest.sh` — all green, including, in the new topic:
  - each of the two incident commands above, verbatim, is DENIED;
  - `timeout 300 bash -c 'until test -f /tmp/x; do sleep 5; done'` is
    ALLOWED — a bound is the fix, and the fix must pass;
  - a counter-bounded loop (`i=0; while [ $i -lt 10 ]; do sleep 1;
    i=$((i+1)); done`) is ALLOWED;
  - `while read -r line; do echo "$line"; done < f` and `for i in 1 2 3;
    do sleep 1; done` are ALLOWED — the false positives that would get
    this routed around;
  - a `pgrep -f` wait loop WITH a `timeout` is still DENIED, and the
    reason says self-matching, not "unbounded";
  - malformed stdin, empty stdin, a payload with no `command` key: exit
    0, allow, say nothing. Fail OPEN, the doctrine
    `pretool-feedback.sh` states at its top.
- `./joharness.sh mutate .agents/harness/pretool-bash-guard.sh <line>` on
  the deny decision and on the bound-detection line: each reds at least
  one case. A gate nothing pins is a gate that quietly stops gating.
- `./joharness.sh ci` — `ci: pass`, with the new perf row inside budget.
- SHIPS: `.agents/harness/` and `.claude/settings.json` reach every
  consumer at its next sync, so the consumer-side check is that a Bash
  call carrying an unbounded wait is denied in a repo that only synced —
  no consumer-side registration step of its own.

## Where to look

- `.agents/harness/pretool-feedback.sh` — the existing PreToolUse hook:
  how it reads the payload with ONE line before any key (a multi-line
  payload turns `grep`'s `^` into a per-line anchor and a Write's content
  can then steer the hook), and its fail-open doctrine. Read that header
  before writing a line of the new one.
- `.claude/settings.json` — the registration shape, and the `|| exit 0`
  that keeps a broken hook from denying.
- `.agents/harness/handover-guard.sh` — the stop-side count this gate
  makes rarer, and the comment that says why it is a bound and not a
  census.
- `.agents/harness/AGENTS.md` step 5 — the rule this enforces.

## Traps

- DENY is exit 2 and stderr for PreToolUse. A hook that prints its reason
  on stdout has told nobody: plain stdout is logged and shown to no model.
  `pretool-feedback.sh` says this at its top about the JSON envelope; the
  same trap, the other decision.
- Fail open, always. Bad stdin, no `command`, a missing entrypoint, an
  unreadable payload — exit 0. This hook sits in front of every Bash call
  in every consumer; a hook that denies when confused is worse than no
  hook.
- A false positive is how a gate dies. Deny the two named shapes; let
  everything else through, and let the stop guard keep catching what the
  gate misses.
- The perf budget counts external commands per entrypoint. This one runs
  on every Bash call: do the matching in the shell, not in a pipeline of
  forks, and find the loop rather than raising the number.
- Never skip, disable or quarantine a case to get green; a test written
  for this must fail without the fix (revert it, watch it red).
- Measured number carries what produced it, same sentence.
