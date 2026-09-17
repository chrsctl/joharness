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

## Consequence for the queue

`.agents/harness/pretool-bash-guard.sh` changes, or its message does, and
`.agents/harness/selftest/pretool-bash-guard.sh` gains a case either way —
one where the keyword and the `done` belong to different constructs. Nothing
else in the harness is implicated and no plan here is waiting on it.

**What this node does NOT ask.** The same session hit three refusals from the
host's auto-mode classifier on actions the protocol requires — step 7's
merge verification (`git fetch` + `git log`), `/manage` § 4's `merged <stem>`
notification, and the push retry above — and canonical ships
`.claude/settings.json` with hooks and no `permissions` block. Whether that
file should carry one is a real question and a different one; it is named
here only so the connection is on the record, because the retry loop that
met this guard existed because of it. The consumer's own copy of that
question is `chrsctl/gx` PR #396. Filing it is not this report's business.

## Verification

Taken by the session that made the findings, so treat the second half
accordingly: the pair in `## Method` was run a second time against a fresh
clone of canonical at `8143e0a` rather than only against the consumer's
tree, and both arms answered identically — GROUNDED. The claim that
`start_re` matches only `while|until` is GROUNDED (`grep -n "start_re="`
on both copies, line 116, identical). The claim about what the message cost
the diagnosis is a report of this session's own behaviour and is therefore
WEAK as evidence about anyone else, though the plan it produced and the
reviewer's reproduction are both in `chrsctl/gx`'s history. No independent
reader has re-run these payloads.

## Graduates to

`.agents/harness/pretool-bash-guard.sh` — the file whose rule or whose
sentence is wrong, and whose selftest is where the answer becomes something
that cannot regress.
