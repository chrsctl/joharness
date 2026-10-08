---
research: a-self-match-the-guard-cannot-see
urgency: normal
agent: opus
effort: medium
graduates: .agents/harness/pretool-bash-guard.sh
---

## Question

What must `pretool-bash-guard.sh`'s self-match deny be keyed on, and which
loop openers must reach it, for a wait whose condition reads its own command
line to be refused?

One question about one branch of one function, in two clauses because the
branch has two independent ways of not firing: the predicate it tests, and
whether `judge()` is called at all for the loop in front of it. An answer to
either clause alone leaves a wait of the reported shape allowed, which is why
they are not split.

## Echo

A consumer reported the shape the guard exists to refuse, reached by a
spelling the deny does not name. The guard's own reasoning for the `pgrep -f`
clause is that `-f` tests full command lines and the waiting loop's own line
carries the pattern as an argument, so the process is always found.
`ps -e -o args | grep -cE <pattern>` has the identical property for the
identical reason — `ps` prints the `grep`'s own line, `grep` counts itself —
and the deny says `pgrep`.

So the narrow reading is: add a clause for the other spelling. What rests on
the answer is whether a list of spellings is the right shape for this gate at
all, given that the property is "the condition reads its own command line"
and the tools with that property are open-ended. Against that stands the
guard's own history, which is a record of narrowings that each opened a hole
somewhere else, and a hard budget: no forks, and 8 KB past which one reader
is switched off.

The second clause is why the report's own candidate needs checking before it
is costed. The reported command was a `for` loop. If `judge()` is never
called for a `for` loop, then the deny did not miss that command — it was
never offered it, and a new clause inside `judge()` would not change its
verdict.

## Sweep

`goal-directed`. Enough to decide the shape of the fix and to price the
candidates: which spellings the current clause covers, which it misses, which
loop openers either reader reaches, and what a reach costs against the
guard's own selftest. NOT a survey of every way a shell can read a process
table.

## What would settle it

Set before the fixtures ran, as a table of spellings with a verdict wanted
for each:

1. **The covered set, enumerated.** Every spelling of `pgrep`/`pkill` the
   self-match deny fires on, and every near-miss spelling of the SAME tools.
   A clause that misses `-fl` is not a tool-vs-property question; it is a bug
   in the existing clause, and settles differently.
2. **The reported spelling, re-run.** `ps | grep` in a wait loop, bounded and
   unbounded. An ALLOW on the bounded one is the finding; a DENY would mean
   the report is about the deny's WORDING and nothing else.
3. **Reachability.** The same condition under a `for` opener and under a
   `while` opener. Identical verdicts mean the predicate is the whole story;
   different verdicts mean the opener, not the condition, decided this
   report.
4. **What each candidate costs against the pinned selftest.** Every
   `pbg_allowed` case in `.agents/harness/selftest/pretool-bash-guard.sh`
   that a candidate flips to DENY, counted — not sampled. A candidate that
   reds a pinned allow is paying in false positives, which this guard's
   header prices as the way a gate dies.

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

The same refusal reached the verifier of this node, in its own container
share, from its own attempt. So `fixtures.txt` was written with the Write
tool and driven by `run.py`, both outside the repo, and both are reproduced
here whole because the node is the only copy that survives this session.

```python
import json
import subprocess
import sys

GUARD = "/home/user/joharness/.agents/harness/pretool-bash-guard.sh"
FIX = "<scratchpad>/fixtures.txt"

for raw in open(FIX):
    raw = raw.rstrip("\n")
    if not raw.strip() or raw.startswith("#"):
        continue
    label, cmd = raw.split("|", 1)
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    p = subprocess.run(["bash", GUARD], input=payload, capture_output=True, text=True)
    first = ""
    for line in p.stderr.splitlines():
        if line.strip():
            first = line.strip()
            break
    verdict = "DENY" if p.returncode == 2 else ("ALLOW" if p.returncode == 0 else "exit%d" % p.returncode)
    reason = ""
    if verdict == "DENY":
        reason = "SELF-MATCH" if "matches ITSELF" in p.stderr else "UNBOUNDED"
    print("%-38s %-6s %-11s %s" % (label, verdict, reason, first[:96]))
```

`python3 -I run.py`. `exit 2` is DENY, `exit 0` ALLOW; `matches ITSELF` in
stderr distinguishes the self-match deny from the unbounded one. The fixtures,
`label|command`, one per line — all 26, because a subset is a method nobody
can re-run, and D is the reported incident's own shape:

```
A|until ! pgrep -f "bash .agents/harness/selftest.sh" >/dev/null; do sleep 3; done
B|timeout 300 bash -c 'until ! pgrep -f "bash selftest.sh"; do sleep 3; done'
C|i=0; while [ $i -lt 20 ]; do pgrep -f "python3 platform/" || break; sleep 5; i=$((i+1)); done
D|for i in $(seq 1 20); do n=$(ps -e -o args | grep -cE "python3 (platform|apps|tools)/"); if [ "$n" -gt 0 ]; then sleep 15; else break; fi; done
E|until [ "$(ps -e -o args | grep -cE "python3 (platform|apps|tools)/")" -eq 0 ]; do sleep 15; done
F|timeout 600 bash -c 'until [ "$(ps -e -o args | grep -c "python3 platform/")" -eq 0 ]; do sleep 15; done'
G|timeout 600 bash -c 'while ps aux | grep -q "python3 platform/tests"; do sleep 10; done'
H|timeout 300 bash -c 'until ! pgrep -fl "bash selftest.sh"; do sleep 3; done'
I|timeout 300 bash -c 'until ! pgrep -f"bash selftest.sh"; do sleep 3; done'
J|timeout 300 bash -c 'until ! pgrep bash; do sleep 3; done'
K|timeout 300 bash -c 'until ! pgrep --full "bash selftest.sh"; do sleep 3; done'
L|timeout 300 bash -c 'until ! pkill -f "bash selftest.sh"; do sleep 3; done'
M|timeout 300 bash -c 'until ! grep -l "python3 platform/" /proc/*/cmdline; do sleep 3; done'
N|timeout 300 bash -c 'until ! pidof -x selftest.sh; do sleep 3; done'
O|n=1; while [ "$n" -gt 0 ]; do n=$(ps -e -o args | grep -c "python3 platform/"); sleep 10; done
P|n=1; while [ "$n" -gt 0 ]; do n=$(pgrep -f -c "python3 platform/"); sleep 10; done
Q|for i in $(seq 1 20); do pgrep -f "python3 platform/" || break; sleep 5; done
R|i=0; while true; do pgrep -f "python3 platform/" || break; sleep 5; done
S|for i in $(seq 1 20); do ps -e -o args | grep -cE "python3 x"; sleep 15; done
T|for ((i=0; i<20; i++)); do ps -e -o args | grep -c "python3 x"; sleep 15; done
U|n=1; while [ "$n" -gt 0 ]; do sleep 10; done
V|n=1; while [ $n -gt 0 ]; do sleep 10; done
W|until test -f /tmp/x; do sleep 5; done
X|for i in $(seq 1 100000); do pgrep -f "bash selftest.sh" > /dev/null || break; sleep 60; done
Y|select x in a b; do pgrep -f "python3 platform/"; sleep 5; done
Z|until [ "$(ps -e -o args | grep -c "python3 x")" -eq 0 ] < /dev/null; do sleep 15; done
```

The candidate measurements in findings 4 and 5 patch a COPY of the guard in
the scratchpad and re-run the same fixtures and the guard's own selftest
against it. The repo copy is not edited by this node: a research file that
edits its graduation target is a plan with the wrong frontmatter.

Reading, for the two readers and the clause order: `judge()`
(`pretool-bash-guard.sh:256`), `proc_re`/`full_re` (`:227`, `:228`),
`start_re` (`:188`), `open_re` (`:182`), `token_re` (`:185`), the `tkw`
capture (`:382`, `:393`) and the skip that uses it (`:419`).

## Findings

- **The self-match deny covers four spellings and misses two of the same two
  tools.** DENY with `matches ITSELF`: `pgrep -f` (A, B, C), `pgrep --full`
  (K), `pkill -f` (L), `pgrep -f -c` (P). ALLOW: `pgrep -fl` (H) and
  `pgrep -f"pat"` with no space after the flag (I).
  `full_re='[[:space:]](-[[:alnum:]]*f([[:space:]]|$)|--full)'` (`:228`)
  requires `f` LAST in the cluster and a space or end after it, so `-fl` —
  the spelling a human types to see the lines it matched — is not a
  full-command-line flag to this guard.
- **The reported spelling is allowed whenever it is bounded.** F → `exit 0`.
  `proc_re='[^[:alnum:]_](pgrep|pkill)[[:space:]]'` (`:227`) names two
  commands, so no `ps`-based condition reaches the self-match branch at all,
  and the clause that would have fired is the bound check, which a `timeout`
  satisfies. G, `ps aux | grep -q` under a `timeout`, the same.
- **Unbounded, the same loop is denied — and the deny's own remedy is the
  allowed spelling of itself.** E → `exit 2 UNBOUNDED`, and that message
  prints *"Two spellings pass: `timeout 300 bash -c '...'`"* (`:233`-`:234`).
  Wrapping it in `timeout` is F, `exit 0`. A session that meets this gate is
  routed from a wait that never exits to a wait that always runs the clock
  out — which is the outcome the `pgrep` branch's own comment gives as its
  reason for firing bounded or not (`:262`-`:267`).
- **No `for` or `select` loop is judged by either reader.** Q (`for`) →
  `exit 0` against R (`while`, same body) → `exit 2 SELF-MATCH`. Also ALLOW:
  S, T (`for ((;;))`), Y (`select`), and X —
  `for i in $(seq 1 100000); do pgrep -f "bash selftest.sh" > /dev/null || break; sleep 60; done`,
  a wait of up to 69 days with the covered tool AND the covered flag.
  Mechanism: reader A scans `start_re` (`:188`), which is `while|until` and
  nothing else; reader B fills `tkw` from the `while|until` capture of
  `token_re` (`:382`, `:393`) and `judge` is skipped for any token whose
  `tkw` is empty (`:419`). A `for` opener is counted for depth so the stack
  balances, and never judged. The Q/R pair is not confounded by R's
  `while true`: C shows the self-match branch firing ahead of the bound
  check, so a condition difference could not have produced Q's ALLOW, and S,
  T, X, Y establish the openers without the pair. The report's record names
  the loop as `for i in $(seq 1 N)`; its exact command line is not in that
  record, so this reads the record's opener against the measurement and not
  a reconstructed line.
- **Reaching `for`/`select` with the SELF-MATCH branch costs nothing; teaching
  the BOUND check to read them costs seven pinned allows, five of them the
  prose cases the last node on this guard was built to close.** Measured
  (verifier) against a scratch copy, all 80 `pbg_allowed`/`pbg_denied` cases
  in `.agents/harness/selftest/pretool-bash-guard.sh` extracted and compared:
  self-match-only reach flips **0 of 80** and denies Q, X, Y; a `for` opener
  judged by the whole of `judge()` flips **seven** allows to `DENY UNBOUNDED`
  — selftest `:85` ("a for loop with a sleep is allowed"), `:331` ("a
  no-sleep poll ending in } done does not borrow a later sleep"), and the
  five prose fixtures `:187`, `:351`, `:370`, `:411`, `:415` ("to do while is
  prose", "Done! while is prose" and kin), which `bash-guard-reads-prose-as-
  a-loop` (retired `810000bf`) and four verifier rounds existed to close.
  This is the measurement that separates candidates C and D below from each
  other and from A.
- **The gate names a tool where the backstop already names the property, and
  the generic spelling is the EARLIER one.** `handover-guard.sh:340` reports
  *"a command that cannot finish (a wait loop whose own line matches its own
  pattern)"* — tool-free prose. It landed at `418bfafe`; the `pgrep`-named
  deny landed at `f9ea7d67`, and `git merge-base --is-ancestor 418bfafe
  f9ea7d67` succeeds while the reverse fails. So this is not a harness
  generalizing over time: the property was written first, in the counter, and
  the gate built after it narrowed to a tool. That the backstop is what
  caught the consequence is the consumer's record, not reproducible here.
- **Adjacent, and NOT this question: the bound check cannot read a quoted
  counter.** U (`[ "$n" -gt 0 ]`) → `exit 2 UNBOUNDED`; V, the same line with
  `$n` unquoted → `exit 0`. `count_re` (`:224`) allows one optional `"` after
  the name, but the guard never unescapes a payload — `:101`-`:102` replace
  only `\n` and `\t` — so the character after `$n` is `\`. Recorded because
  it prices candidate B below, and because the shellcheck-correct spelling is
  the denied one. It is a second defect in the same function, not a facet of
  this question.

## Consequence for the queue

No plan changes. No plan file names this guard, and none is blocked on the
answer — `./joharness.sh ci` is `ci: pass` with the guard as it stands,
because every fixture above is a command nobody committed.

What the answer changes is the SHAPE of the repair. The candidates are not
interchangeable and three of them are measurably insufficient alone, so a
plan written before this closes would be written for the wrong one.
Candidates, as candidates:

- **A. A `ps`-pipe clause beside the `pgrep -f` one**, the report's first
  candidate. Cheapest, and measured insufficient alone: `judge()` is never
  called for the `for` opener the reported command used (finding 4), so A
  fixes the spelling and still returns ALLOW on D.
- **B. `< /dev/null` plus a condition the command cannot satisfy itself**, the
  report's second. Z → `exit 2 UNBOUNDED`, unchanged from E: the redirection
  is not a signal this guard reads. B is a rule for a session to follow, not
  a clause this gate can enforce, and finding 7 shows the gate already
  misreads the bound a session would write.
- **C. Key the branch on the property.** Deny a wait whose condition reads
  full command lines and tests for absence or counts to zero, whatever reads
  them — `pgrep -f`, `pgrep -fl`, `ps` piped to `grep`, `/proc/*/cmdline`
  (M → `exit 0` today). Generalizes, and is the spelling the backstop already
  uses (finding 6). Unpriced here: whether the predicate can be written in
  builtins with no fork, which is the budget its own header sets.
- **D. Reach: run the existing self-match branch from `for` and `select`
  openers.** Measured zero cost against the selftest, 0 of 80 (finding 5),
  and measured insufficient alone in the other direction: with the branch
  reached from `for`, D and S stay ALLOW and only Q, X and Y flip to DENY,
  because the existing branch is keyed on `pgrep`/`pkill`. D denies a 69-day
  `pgrep -f` wait that is allowed today and does NOT deny the reported
  command.
- **E. Nothing.** Both reported loops were bounded by `seq`, nothing was
  wedged, the backstop named the shape afterwards, and the guard's own
  "WHAT IT CANNOT DO" already says it reads text and does not parse shell.
  The cost, as recorded, was two wasted waits and one self-woken
  notification.

The measurement that matters for whoever takes this: A and D each fix one
clause and leave the reported command allowed; only the pair, or C with D,
denies it. C is the predicate, D is the reach, A is C's narrowest case. So
the predicate is decided first — it decides whether a spelling list is being
maintained at all — and the reach is decided second, where the selftest has
already priced the two ways of doing it.

## Verification

Checked by `.claude/agents/verifier.md` at `opus`, this branch's tier
(`./joharness.sh review`), from a context that did not run the fixtures,
given the guard, its selftest and the fixture file and asked to re-run every
verdict and every citation. Seventeen findings returned; the five that bear on
this node are answered in the workstream file's `## Review`, tagged
`(verifier)`, and three of them changed text above: candidate D's
counterfactual, finding 5's cost, and finding 6's chronology.

- All 26 exit statuses: **GROUNDED**, re-run independently at this branch's
  head against a byte-identical guard, every quoted verdict matching.
- Findings 1, 2, 3 and 7, and the mechanisms given for them: **GROUNDED** —
  each verdict re-run, each regex read in place.
- Finding 4's mechanism, and that the Q/R pair isolates the opener:
  **GROUNDED** twice, by the fixture set and by reading `:188`, `:382`,
  `:393` and `:419`. Either alone would be WEAK: the verdicts cannot say WHY
  and the code alone is an unrun claim.
- Finding 5: **GROUNDED**, and it is the verifier's measurement rather than
  mine — 80 selftest cases extracted and diffed under two scratch patches.
  The sentence it replaced said "a pinned allow", singular, and understated
  the cost sevenfold.
- Candidate D's sufficiency: **GROUNDED** as refuted. It was written here as
  "the smallest change that would have denied the reported command" and
  measured not to deny it.
- Finding 6's ordering: **GROUNDED** by `git merge-base --is-ancestor`. The
  sentence it replaced had the chronology backwards.
- "The report's command was a `for` loop": **GROUNDED** in the consumer's own
  retired workstream file, read at `9c69b8e9` in that repo. Its exact command
  line is **UNGROUNDED** — not in that record, not reconstructible, and no
  finding above rests on one. The verifier could not reach that commit from
  this checkout, so every consumer-side citation here is unverified by it and
  grounded only in the record itself.
- Candidate C's fork budget: **UNGROUNDED**. Nothing here measures whether the
  predicate can be written in builtins, and this node does not edit the guard
  to find out.

## Graduates to

`.agents/harness/pretool-bash-guard.sh` — the same target the earlier node on
this guard used (`bash-guard-reads-prose-as-a-loop`, retired `810000bf`). The
guard's header IS this harness's why-explanation for it: every narrowing it
has survived is written there beside the incident that bought it, which is
what stops the next session re-opening a settled edge. An answer written
anywhere else would be a second copy of that record.

One constraint on the graduation, cheaper to name here than to discover
there: `.agents/docs/consumer-repos.md:193`-`:212` bars a repository name,
and a consumer's plan and item names, from every shipping path — the guard
among them. The evidence above names a consumer because this file is under
`docs/`, which that rule's scope excludes. The crossing prose cites the
measurement instead: the command, the commit, the counts.
