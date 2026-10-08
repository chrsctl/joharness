---
research: a-self-match-the-guard-cannot-see
urgency: normal
agent: opus
effort: medium
graduates: .agents/harness/pretool-bash-guard.sh
---

## Question

Should `pretool-bash-guard.sh`'s self-match deny be keyed on the PROPERTY — a
wait whose condition reads full command lines, so its own line is always in
the answer — rather than on `pgrep`/`pkill` carrying a full-command-line flag?

Which loop keywords such a clause can reach is under `## What would settle
it`. Not a second question: it decides whether any clause added in `judge()`
fires on the command that produced this report at all, and the measurement
says it does not.

## Echo

A consumer (`chrsctl/gx`) reported the shape the guard exists to refuse,
reached by a spelling the deny does not name. The guard's own reasoning for
the `pgrep -f` clause is that `-f` tests full command lines and the waiting
loop's line carries the pattern as an argument, so the process is always
found. `ps -e -o args | grep -cE <pattern>` has the identical property for
the identical reason — `ps` prints the `grep`'s own line, `grep` counts
itself — and the deny says `pgrep`.

So the narrow reading is: add a clause for the other spelling. What rests on
the answer is whether a list of spellings is the right shape for this gate at
all, given that the property is "the condition reads its own command line"
and the tools with that property are open-ended. Against that stands the
guard's own history, which is a record of narrowings that each opened a hole
somewhere else, and a hard budget: no forks, and 8 KB past which one reader
is switched off.

The reachability half is what makes this more than a spelling list. The
reported command was a `for` loop. If `judge()` is never called for a `for`
loop, then the deny did not miss this command — it was never offered it, and
the clause the reporter proposes would not have fired either.

## Sweep

`goal-directed`. Enough to decide the shape of the fix and to price the
candidates: which spellings the current clause covers, which it misses, and
which loop keywords either clause can reach. NOT a survey of every way a
shell can read a process table.

## What would settle it

Set before the fixtures ran, as a table of spellings with a verdict wanted
for each:

1. **The covered set, enumerated.** Every spelling of `pgrep`/`pkill` the
   self-match deny actually fires on, and every near-miss spelling of the
   SAME tools. A clause that misses `-fl` is not a tool-vs-property question;
   it is a bug in the existing clause, and settles differently.
2. **The reported spelling, re-run.** `ps | grep` in a wait loop, bounded and
   unbounded. An ALLOW on the bounded one is the finding; a DENY would mean
   the report is about the deny's WORDING and nothing else.
3. **Reachability.** The same condition in a `for` loop and in a `while`
   loop. Identical verdicts mean the clause is the whole story; different
   verdicts mean the opener, not the condition, decided this report.
4. **What a pinned selftest case forbids.** If a candidate reds
   `.agents/harness/selftest/pretool-bash-guard.sh`, its cost is a pinned
   allow, which is a different decision from a line of regex.

Every verdict is `exit 0` or `exit 2` from the guard against a JSON payload,
so each row is decidable and none needs a judgement.

## Method

Payloads go through a file and a runner, because the guard is live on this
session's Bash and a command line that CARRIES a wait loop is refused like
the loop it spells. Measured, not assumed:

```
$ echo '{"tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do sleep 5; done"}}' > /dev/null
PreToolUse:Bash hook error: DENIED: this `until` loop sleeps with no bound on
how long it waits.
```

So `fixtures.txt` (`label|command`, one per line) was written with the Write
tool and driven by this runner, outside the repo:

```python
import json, subprocess
GUARD = "/home/user/joharness/.agents/harness/pretool-bash-guard.sh"
for raw in open("fixtures.txt"):
    label, cmd = raw.rstrip("\n").split("|", 1)
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    p = subprocess.run(["bash", GUARD], input=payload, capture_output=True, text=True)
    print(label, p.returncode, "SELF-MATCH" if "matches ITSELF" in p.stderr else "")
```

`python3 -I run.py`, 26 fixtures over two rounds, at `a907ef6b` (guard
unmodified). `exit 2` is DENY, `exit 0` ALLOW; `matches ITSELF` in stderr
distinguishes the self-match deny from the unbounded one. Each fixture is
quoted beside the finding it produced.

Reading, for the two readers and the clause order: `judge()`
(`pretool-bash-guard.sh:256`), `proc_re`/`full_re` (`:227`, `:228`),
`start_re` (`:188`), `open_re` (`:182`), the `tkw` capture (`:382`, `:393`)
and the skip that uses it (`:419`).

## Findings

- **The self-match deny covers four spellings and misses two of the same two
  tools.** DENY with `matches ITSELF`: `pgrep -f`, `pgrep --full`, `pkill
  -f`, `pgrep -f -c`. ALLOW: `pgrep -fl` and `pgrep -f"pat"` with no space
  after the flag. `full_re='[[:space:]](-[[:alnum:]]*f([[:space:]]|$)|--full)'`
  (`:228`) requires `f` LAST in the cluster and a space or end after it, so
  `-fl` — the spelling a human types to see the lines it matched — is not a
  full-command-line flag to this guard. Fixtures:
  `timeout 300 bash -c 'until ! pgrep -fl "bash selftest.sh"; do sleep 3; done'`
  → `exit 0`, and the same line with `-f` → `exit 2`.
- **The reported spelling is allowed whenever it is bounded.**
  `timeout 600 bash -c 'until [ "$(ps -e -o args | grep -c "python3 platform/")" -eq 0 ]; do sleep 15; done'`
  → `exit 0`. `proc_re='[^[:alnum:]_](pgrep|pkill)[[:space:]]'` (`:227`)
  names two commands, so no `ps`-based condition reaches the self-match
  branch at all, and the clause that would have fired is the bound check,
  which a `timeout` satisfies.
- **Unbounded, the same loop is denied — and the deny's own remedy is the
  allowed spelling of itself.**
  `until [ "$(ps -e -o args | grep -cE "python3 (platform|apps|tools)/")" -eq 0 ]; do sleep 15; done`
  → `exit 2`, reason `UNBOUNDED`, and that message prints *"Two spellings
  pass: `timeout 300 bash -c '...'`"* (`:235`). Wrapping it in `timeout` is
  the previous finding, `exit 0`. A session that meets this gate is routed
  from a wait that never exits to a wait that always runs the clock out —
  which is the outcome the `pgrep` branch's own comment gives as its reason
  for firing bounded or not (`:262`-`:267`).
- **No `for` or `select` loop is judged by either reader, so the clause the
  report proposes would not have fired on the command that produced it.**
  Identical bodies, different openers:
  `for i in $(seq 1 20); do pgrep -f "python3 platform/" || break; sleep 5; done`
  → `exit 0`, while `while true; do pgrep -f "python3 platform/" || break; sleep 5; done`
  → `exit 2 SELF-MATCH`. Also ALLOW: the same with `ps | grep`, with
  `for ((i=0; i<20; i++))`, with `select x in a b`, and
  `for i in $(seq 1 100000); do pgrep -f "bash selftest.sh" > /dev/null || break; sleep 60; done`
  — a wait of up to 69 days, with the covered tool and the covered flag.
  Mechanism: reader A scans `start_re` (`:188`), which is `while|until` and
  nothing else; reader B's `tkw` takes capture 7 of `open_re` (`:382`,
  `:393`), which is also `while|until`, and `judge` is skipped for any token
  whose `tkw` is empty (`:419`). A `for` opener is counted for depth so the
  stack balances, and never judged. The report's record names the loop as
  `for i in $(seq 1 N)`; its exact command line is not in that record, so
  this reads the record's opener against the measurement, not a reconstructed
  line.
- **A `for` self-match clause does not collide with the pinned allow, but an
  unbounded-check extension would.**
  `.agents/harness/selftest/pretool-bash-guard.sh:85` pins *"a for loop with
  a sleep is allowed"* over `for i in 1 2 3; do sleep 1; done` under the
  heading *"the false positives that would get this routed around"*. That
  fixture carries no `pgrep`, no `ps` and no `grep`, so a self-match branch
  reached from a `for` opener leaves it green; teaching the BOUND check to
  read `for` reds it.
- **The backstop already states the property the gate states as a tool.**
  `handover-guard.sh:340` reports *"a command that cannot finish (a wait loop
  whose own line matches its own pattern)"* — tool-free prose, and the guard
  that caught the consequence in the consumer. The PreToolUse deny names
  `pgrep`. One harness, two spellings of the same hazard, and only the later
  one generalizes.
- **Adjacent, and NOT this question: the bound check cannot read a quoted
  counter.** `n=1; while [ "$n" -gt 0 ]; do sleep 10; done` → `exit 2
  UNBOUNDED`; the same line with `$n` unquoted → `exit 0`. `count_re` (`:224`)
  allows one optional `"` after the name, but a payload's quotes arrive
  backslash-escaped, so the character after `$n` is `\`. Recorded because it
  prices candidate B below — `< /dev/null` plus "a condition the command
  cannot satisfy itself" asks this gate to read a bound it already misreads —
  and because the shellcheck-correct spelling is the denied one. It is a
  second defect in the same function, not a facet of this question.

## Consequence for the queue

No plan changes. No plan file names this guard, and none is blocked on the
answer — `./joharness.sh ci` is green with the guard as it stands, because
every fixture above is a command nobody committed.

What the answer changes is the SHAPE of the repair, and the two halves have
different costs, so a plan written before this closes would be written for the
wrong one. Candidates, as candidates:

- **A. A `ps`-pipe clause beside the `pgrep -f` one**, the consumer's first
  candidate. Cheapest, and measured insufficient on its own: the command that
  produced the report is a `for` loop, which `judge` is never called for. A, as
  written, fixes the spelling and not the incident.
- **B. `< /dev/null` plus a condition the command cannot satisfy itself**, the
  consumer's second. `until [ "$(ps -e -o args | grep -c "python3 x")" -eq 0 ] < /dev/null; do sleep 15; done`
  → `exit 2 UNBOUNDED`, unchanged: the redirection is not a signal this guard
  reads. B is a rule for a session to follow, not a clause this gate can
  enforce, and "a condition it cannot satisfy itself" is the property under A
  stated from the other side.
- **C. Key the branch on the property.** Deny a wait whose condition reads
  full command lines and tests for absence or counts to zero, whatever reads
  them — `pgrep -f`, `pgrep -fl`, `ps` piped to `grep`, `/proc/*/cmdline`
  (`timeout 300 bash -c 'until ! grep -l "python3 x" /proc/*/cmdline; do sleep 3; done'`
  → `exit 0` today). Generalizes, and spends exactly what this file's header
  says a false positive costs. Unpriced here: whether it can be written in
  builtins with no fork.
- **D. Reach, and leave the spelling list alone.** Run the existing
  self-match branch from `for` and `select` openers too, where it is reachable
  at a pinned-allow cost of zero (finding 5). Smallest change that would have
  denied the reported command, and it denies nothing A, B or C denies.
- **E. Nothing.** Both reported loops were bounded by `seq`, nothing was
  wedged, the backstop named the shape afterwards, and the guard's own
  "WHAT IT CANNOT DO" already says it reads text and does not parse shell.
  The cost, as recorded by the consumer, was two wasted waits and one
  self-woken notification.

C and D are not rivals: D is reach, C is the predicate. A is C's narrowest
case. Whoever takes this decides the predicate first, because it decides
whether a spelling list is being maintained at all.

## Verification

Checked by a verifier subagent at this branch's tier, from a context that did
not run the fixtures, with the guard and its selftest in front of it and the
fixture lines to re-run. Findings tagged `(verifier)` in the workstream file's
`## Review`, recoverable per the pull request body.

- Every verdict above: **GROUNDED**. Each is one `exit` status from
  `pretool-bash-guard.sh` against a quoted payload, re-runnable by the runner
  in `## Method`.
- The mechanism for finding 4 (`for` never judged): **GROUNDED** twice —
  once by the Q/R fixture pair, once by reading `:188`, `:382`, `:393` and
  `:419`. Either alone would be WEAK; a verdict pair without the code cannot
  say WHY, and the code without the pair is an unrun claim.
- "The report's command was a `for` loop": **GROUNDED** in the consumer's own
  record (`git show 9c69b8e9:docs/handover/crm-c4-registry-agreement-after-512.md`
  in `chrsctl/gx`, `## Review` r1). Its exact command line is **UNGROUNDED** —
  not in that record, not reconstructible, and no finding above rests on one.
- Candidate C's fork budget: **UNGROUNDED**. Nothing here measures whether the
  predicate can be written in builtins, and this file does not edit the guard
  to find out.

## Graduates to

`.agents/harness/pretool-bash-guard.sh` — the same target the earlier node on
this guard used (`bash-guard-reads-prose-as-a-loop`, retired at `810000bf`).
The guard's header IS this harness's why-explanation for it: every narrowing
it has survived is written there, beside the incident that bought it, which is
what stops the next session re-opening a settled edge. An answer written
anywhere else would be a second copy of that record.
