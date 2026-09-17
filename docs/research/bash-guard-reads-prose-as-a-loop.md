---
research: bash-guard-reads-prose-as-a-loop
urgency: normal
agent: opus
effort: medium
graduates: .agents/harness/pretool-bash-guard.sh
---

<!--
A report from a consumer (`chrsctl/gx`), filed by the route
`.claude/commands/upstream-report.md` names. Canonical decides. The
measurements below could not be taken here, because they are about a
session running the harness against real work.
-->

## Question

Does `pretool-bash-guard.sh` deny commands containing no unbounded loop,
because it pairs the word `while` in ordinary text with a `done` that
belongs to a different, bounded loop?

## Echo

The guard's discrimination is *"a `while` or `until` with `do`, a `sleep` in
the body, and `done`"*, and its own comment says requiring the full loop is
*"what keeps `grep -n 'until.*sleep' file` out of this net — a pattern is not
a loop, it has no `do` and no `done`"*. The walk cuts one loop out at a time
starting from each keyword match. What I am asking is whether that pairing is
positional rather than structural: the keyword can come from a quoted string
and the `done` from a `for` loop further along the same command line, and
nothing checks that the two belong to each other.

Unusually for this shape, the observation was already made before this file
was written — the reproduction is below rather than owed. What is NOT settled
is which half is wrong, and that is left to canonical.

## Sweep

`goal-directed` — enough to establish whether the denial fires on a command
with no unbounded wait in it, and what it costs a session when it does. Not a
survey of the guard's other rules, and not a proposal for a new pattern.

## What would settle it

The observation is settled by the pair in `## Findings`. What remains, and
what a session taking this should decide:

- **Whether the RULE is wrong or only the MESSAGE.** If the guard is meant to
  deny any command whose text spells an unbounded wait — the position its own
  comment defends for a heredoc writing a loop into a script — then a
  `for` loop plus the word `while` in a commit message is a false positive
  the comment does not cover, because the text spells no loop and the loop it
  finds is bounded by construction. If instead the guard is meant to catch
  the shape wherever it sits, then the keyword and the `done` have to be shown
  to belong to the same loop before the pair counts.
- **What a fix must not cost.** The file is emphatic that *"a false positive
  is how a gate dies"*, and it is equally emphatic about the two incidents it
  was bought with. Any narrowing owes a selftest case for each incident the
  guard already catches, not just for the new one.
  `.agents/harness/selftest/pretool-bash-guard.sh` is where that is decided;
  it has no case today pairing a keyword in text with an unrelated loop's
  `done` — which is why this has been green.
- **Whether a session can even report this without tripping it.** Noted
  because it shaped how the measurement below had to be taken: the first
  attempt to test the guard was itself denied by the guard, since the test
  command contained both the word and a `for` loop. The payloads had to be
  written to disk by a non-shell tool and fed in separately.

## Method

Two payloads, one word apart, fed to the guard on stdin as the PreToolUse
hook receives them. Run against **canonical's own copy** at `8143e0a`
(`.agents/harness/pretool-bash-guard.sh`, `start_re` at line 116), not
only against the consumer's:

    bash .agents/harness/pretool-bash-guard.sh < a.json ; echo "EXIT=$?"
    bash .agents/harness/pretool-bash-guard.sh < b.json ; echo "EXIT=$?"

`a.json` and `b.json` hold `{"tool_name":"Bash","command": …}` with:

    A:  echo "the UI floor moved while they were written" && \
        for d in 2 4; do true && break || sleep $d; done

    B:  echo "the UI floor moved when they were written" && \
        for d in 2 4; do true && break || sleep $d; done

## Findings

- **The guard denies A and allows B, and the only difference is one word
  inside a quoted string.** For A, `EXIT=2` and the first line of stderr is

      DENIED: this `while`/`until` loop sleeps with no bound on how long it waits.

  For B, `EXIT=0` and no output. Neither command contains a
  `while` or `until` loop. Both contain one `for` loop over a two-element
  list, which cannot run unbounded. Measured 2026-09-16 against canonical
  `8143e0a` and against `chrsctl/gx` at the same time, same result both
  places.

- **It fired on real work twice in one session, and the first time cost a
  push.** The command was an ordinary commit-and-push:
  `git add -A docs/ && git commit -q -m "$(cat <<'MSG' … MSG)" && for d in 2
  4 8; do git push -q && break || sleep $d; done` — the retry shape the Git
  guidance prescribes. The commit message inside the heredoc read *"The UI
  floor moved under two of these plans **while** they were written"*. That
  `while`, the `for` loop's `done`, and the `sleep $d` between them are the
  three parts the walk looks for. The session re-ran the commit without the
  retry loop; the shape it was told to use is the shape that was refused.

- **The deny message names a construct the command does not contain, and that
  is what sent the diagnosis to the wrong file.** *"this `while`/`until`
  loop"* about a command holding a `for` loop reads as a claim about the
  text, so the session concluded the guard could not have been the denier
  and attributed the refusal to a different gate — writing that attribution
  into a plan that told its next reader to ignore the only evidence it had
  about which gate was firing. That plan was withdrawn when a reviewer
  reproduced `start_re` and found `for` absent from it. The rule was closer
  to right than the message: a reader who trusts the message looks for a
  loop that is not there and concludes the guard is innocent.

- **The answer to the open question: the RULE, not only the message.** A
  third shape settles it, and it is worse than the pair above because it is
  the deny's own remedy being refused. Measured 2026-09-17 against this
  copy: `echo "wait while the suite finishes"; timeout 900 bash -c 'until
  grep -q PASS /tmp/out; do sleep 15; done'; cat /tmp/out`
  → EXIT=2. That `timeout N bash -c '...'` is verbatim the FIRST spelling
  the deny message prescribes. `timeout` is read from `prefix`, and the
  prose keyword ends the prefix before it, so the bound the command carried
  was invisible.

- **And the message is wrong TOO, not instead.** It prints `Nothing in it
  can stop it: no timeout, no iteration counter` about a command carrying
  `timeout 900`, two lines above prescribing that same spelling. So this is
  not a rule-or-message choice; both are owed.

- **A narrowing was built, measured and REVERTED. It cannot be done this
  way.** The attempt: a keyword heads a loop only if its own `do`
  comes before any other opener (`for|while|until`), else advance past the
  keyword and let the owning loop be judged on its own pass. It closed the
  three shapes above and failed twice, both measured 2026-09-17 with exit
  codes on the attempt then on the unchanged guard:

  - **It opened a wider hole than it closed.** `for` has to be in the opener
    list — a `for` owns its own `do` and `done` — and
    `for` is deliberately NOT in `start_re`, because a `for` cannot run
    unbounded. So the word `for` inside a loop's own condition skips the
    keyword, and the walk never restarts: nothing is left for `start_re` to
    match. `until docker compose logs db 2>&1 | grep -q "ready for
    connections"; do sleep 5; done` → 0 / 2. So did
    `until grep -q "ready for merge" /tmp/out; do sleep 20;
    done` and incident command 1 with two words added to its
    pattern. `"ready for connections"` is a real readiness line and this
    repo selects the docker layer. A `while`/`until` in that position
    self-heals, because the walk restarts at it — 2 / 2 — so `for` was the
    whole hole.
  - **It did not close the false positive.** The test passes whenever a bare
    `do` sits between the prose keyword and the next opener, and
    ordinary English supplies one: the third shape above plus three words,
    `echo "wait while we do the suite"; timeout 900 bash -c
    '...'` → 2 / 2. The shapes that DID pass passed only because none of
    them happened to contain a lowercase `do`.

## Consequence for the queue

**This is one defect, not two, and it is not a clause.** Pairing a keyword
with a `done` positionally fails from both ends: which keyword owns
this `done` (this file) and which `done` closes this
keyword (#271, where an unbounded loop with a nested `for` ahead of its
sleep slips through — 0 / 0, so that one is not a regression, it has always
been open). A narrowing that answers one end opens the other. The fix is the
depth-tracking rewrite #271 names: walk forward counting `do` up
and `done` down, and the loop's own `done` is the one that
returns to zero.

`.agents/harness/pretool-bash-guard.sh` is UNCHANGED by the branch that
wrote this section, on purpose. What a rewrite owes, and what the reverted
attempt proved is not optional:

- Both incident commands still denied, verbatim.
- Every false-positive case in the topic still allowed.
- A case for each shape above — including the two the narrowing broke, which
  no case covered and which green `ci` and green `verify` said nothing
  about.
- Every new clause pinned. `./joharness.sh mutate <file> <line>
  <replacement>` names which cases red; it found three unpinned clauses in
  the reverted attempt, two of them after I had used it twice and thought I
  was done.

This question stays open because its ANSWER is settled and its FIX is not:
no plan should be written from it that adds one more test to the walk.

## Verification

Second context: `.claude/agents/verifier.md` at opus, which re-derived every
exit code above from its own payloads rather than reading these numbers, and
separated regression from pre-existing by running each one against the
unchanged guard as well.

- **The guard denies commands holding no unbounded loop** — GROUNDED. Three
  shapes, and a one-word control for each.
- **The rule is wrong, not only the message** — GROUNDED. The refused
  command is the deny's own first prescribed spelling.
- **The message is also wrong** — GROUNDED. It was made to print
  `no timeout` about a command carrying one.
- **The ownership narrowing is a regression** — GROUNDED, and found by the
  second context, not the first. The session that built it had gone looking
  for false negatives and tested a nested `for` LOOP, never the word `for`
  in a string ahead of the `do`.
- **The false positive survives the narrowing** — GROUNDED.

Earlier claims in this file, taken by the session that made them, are
unchanged: the A/B pair was re-run against a fresh clone, and `start_re`
matching only `while|until` was grepped on both copies.

## Graduates to

`.agents/harness/pretool-bash-guard.sh` — the file whose rule AND whose
sentence are wrong, and whose selftest is where the answer becomes something
that cannot regress. Nothing lands there until the rewrite above: a
narrowing was tried, measured and reverted, and the measurement is in
`## Findings` so nobody spends the same day on it.
