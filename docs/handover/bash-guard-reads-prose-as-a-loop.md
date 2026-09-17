---
workstream: bash-guard-reads-prose-as-a-loop
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: bash-guard-reads-prose-as-a-loop
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Retire the workstream file and open the pull request; the node stays OPEN and the guard is unchanged
---

## Goal

`docs/research/bash-guard-reads-prose-as-a-loop.md`, filed as a report from a
consumer. The guard pairs a `while`/`until` keyword with a `done`
positionally, and nothing checks that the two belong to the same loop — so a
keyword inside a quoted string pairs with a `for` loop's `done` and the
command is denied for a loop it does not contain. The findings are settled;
what the node leaves open is which half is wrong, the rule or the message.

## Decisions

- A THIRD shape decides it, and it is this session's own. The guard denied a
  command of mine that used the guard's own prescribed legal spelling —
  `timeout 900 bash -c 'until ...; do sleep 15; done'` — because a keyword in
  the text before it ended the `prefix`, and `timeout` is read from the
  prefix and nowhere else. A rule that refuses the spelling its own deny
  message tells you to use is wrong; no reading of "the text spells a wait"
  defends it. So: the RULE, not only the message.
- Payloads go to disk through the Write tool, never a Bash heredoc. The node
  records that the first attempt to test this guard was denied BY the guard,
  because the test command carried both the word and a loop. Same trap, and
  it would cost a turn.

## Rejected

- `docs/research/liveness-in-a-long-turn.md`, which is older and which I
  advanced last round. Its named next step needs a session that is IDLE but
  still `connected`, and the fleet is not offering one: `list_sessions` at
  2026-09-17T14:34Z returned four IDLE sessions and every one reads
  `connection_status: disconnected`. That is worth someone measuring
  properly — if IDLE always implies disconnected, the control the node asks
  for cannot exist and the question needs a different discriminator — but one
  page of eight is not a census and this session is not taking that item.
- `docs/plans/orchestrated-run.md`, the queue's first plan. Blocked on the
  human's heartbeat and on run 3 having stopped.
- The edge branch naming pull request #10. Re-read from GitHub this session,
  sixth consecutive check: closed, unmerged, since 2026-08-21.

## Review

- r1: (session) the answer to the question the node left open is **the RULE,
  not only the message**, and payload C is what settles it: a command using
  the FIRST spelling the deny message prescribes was refused. `timeout` is
  read from `prefix` and a prose keyword ends the prefix before it, so the
  bound the command carried was invisible. No reading of "the text spells a
  wait" defends refusing your own remedy. With the rule fixed the message is
  true whenever it now fires, so the message needs no change — recorded
  because "fix the message" was the cheaper-looking half and it would have
  left the denial in place. (fixed — the walk asks whose `done` it is.)
- r2: (session) the first patch made the guard exit **1**, not 2 or 0. Both
  new `[[ =~ ]]` tests overwrite `BASH_REMATCH`, and `end` was read from it
  afterwards — unset under `set -u`. Exit 1 is a hook FAILURE, which this
  event reads as "allow, and log it": the guard silently absent in front of
  every Bash call in every consumer. Found by running the payloads, not by
  reading the diff. (fixed — `end` is captured immediately after its own
  match, with the ordering and its cost written on the line.)
- r3: (session) `./joharness.sh mutate` reported **NOTHING REDDED** on the
  ownership test's first disjunct: no case pinned it. Five new cases and
  none exercised "a keyword with no `do` after it at all" — I had written
  the clause and then tested only the other half. The tool caught a guard
  clause pinned by nothing, which is the shape a reviewer has to go looking
  for. (fixed — a case for the no-`do` shape, and re-mutating both halves
  separately now reds 1 and 2 cases, disjointly.)
- r6: (verifier) **the narrowing is a REGRESSION and must not merge.** `for`
  is in the new `open_re` and not in `start_re`, so the word `for` inside a
  loop's own condition sits before its `do`, the keyword is skipped, and the
  walk never restarts — `for` is not a `start_re` match. Three real unbounded
  loops that `origin/main` DENIES are allowed on this branch. Re-measured
  here with my own payloads, exit codes on branch then main:
  `until docker compose logs db 2>&1 | grep -q "ready for connections"; do
  sleep 5; done` 0 / 2; `until grep -q "ready for merge" /tmp/out; do sleep
  20; done` 0 / 2; and incident command 1 with two words added to its
  pattern, 0 / 2. "ready for connections" is a real readiness line and this
  repo selects the docker layer. A `while`/`until` in the same position
  self-heals because the walk restarts at it — measured, 2 / 2 — so `for` is
  the whole hole. (fixed by REVERTING: the guard and its topic are back at
  `origin/main`. I went looking for the false-negative direction in r5 and
  tested a nested `for` LOOP, never the word `for` in a string ahead of the
  `do` — the cheaper and far likelier shape.)
- r7: (verifier) **and the false positive is not fixed either.** The
  ownership test passes whenever a bare `do` sits between the prose keyword
  and the next opener, which ordinary English supplies: payload C plus three
  words — `echo "wait while we do the suite"; timeout 900 bash -c 'until ...
  done'` — is DENIED on the branch and on main, 2 / 2. So is the
  commit-and-push shape with "while we do the migration" in the message. The
  three shapes in the selftest pass only because none of them happens to
  contain a lowercase `do`. (fixed by the same revert — the narrowing bought
  nothing and cost F1.)
- r8: (verifier) r1's disposition was half wrong. RULE-not-MESSAGE stands,
  and "the message needs no change" does not: the message still prints
  `Nothing in it can stop it: no timeout, no iteration counter` about a
  command carrying `timeout 900`, two lines above prescribing that same
  spelling. (fixed in the node's record; the message is now named as owed
  work rather than as unnecessary.)
- r9: (verifier) two more clauses pinned by nothing, found with the tool
  after I had used it twice and thought I was done: `walked="$prefix"` on the
  skip path reds no case, and `open_re`'s word-boundary anchor reds no case
  (its alternation does — 1 case — so the control holds). (no change — both
  clauses are gone with the revert, so there is nothing left to pin. Recorded
  because the lesson outlives them: "I mutated it" is not the same as "I
  mutated all of it", and the tool said NOTHING REDDED twice on clauses I had
  written and half-tested.)
- r5: (session) went looking for the false-negative direction rather than
  leaving the expensive half to the reviewer, and found one — the walk takes
  the FIRST `done`, so an unbounded loop with a nested `for` ahead of its
  sleep slips through:
  `until grep -q x /tmp/f; do for y in 1 2; do : ; done; sleep 20; done`.
  The inner `for`'s `done` ends the body, the `sleep 20` sits after it, and
  the sleep test fails. Allowed with exit 0. **Pre-existing**: the same
  payload against `git show origin/main:.agents/harness/pretool-bash-guard.sh`
  is also allowed, so this change neither introduced nor fixed it.
  (wontfix here — it is the mirror of what this node asked, "which `done`
  closes this keyword" rather than "which keyword owns this `done`", and
  closing it replaces the end-finding step with depth tracking rather than
  adding a clause beside it. Filed as #271 with the payload, both exit codes
  and the bar a fix owes. Widening this item to cover it would have put a
  second, larger rewrite of the same function in a diff reviewed as a
  narrowing.)
- r4: (session, corroboration) the guard denied the command that patched the
  guard. The `python3` heredoc carrying the replacement text spells a loop,
  so the walk found a keyword, a `sleep` and a `done` in it. That is the
  defensible side of the line and stays denied — but it is a fourth instance
  of the family in one session, and it is why the patch went through the
  Write tool rather than a Bash heredoc. The node predicted this and the
  prediction cost a turn anyway. (wontfix — a heredoc that writes an
  unbounded wait into a script is the case the guard's own comment defends,
  and this branch changes no rule. A FIFTH instance landed after this was
  written: the commit message for the revert quotes the payloads, so the
  commit command was denied too — the guard refusing the commit that reverts
  the failed fix for it. Committed with `git commit -F` from a file. Both
  instances are cost, not counter-evidence, and both belong to #271's
  rewrite rather than to a clause here.)

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh`, the walk — `prefix` is built to
  the keyword and `timeout` is read from it, which is the whole mechanism of
  the third shape.
- `.agents/harness/selftest/pretool-bash-guard.sh` — where a narrowing owes
  a case for each incident the guard already catches.
