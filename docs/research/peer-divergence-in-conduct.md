---
research: peer-divergence-in-conduct
urgency: normal
agent: sonnet
effort: high
graduates: .agents/docs/orchestrated.md
---

## Question

Can two branches be shown, from their artifacts alone, to have faced the
SAME rule and answered it differently?

## Echo

Issue #251 lists four conduct questions no existing control asks. The
verifier reads the diff; the orchestrator reads the pulse; between them sits
how a manager WORKS its item, and nothing covers it. Three of the four need
a control-plane read or the diff. The fourth — peer divergence — is
different in kind, and the plan that carried the cheap slice said so in its
Out of scope and promised this file: the workstream files it would compare
are artifacts the session-start hook already reads, so no session and no
sampling cost is needed to LOOK. What separates it is judgement, not cost.

Deciding two branches faced the same rule means reading free text. A check
that guesses at sameness reports disagreements that are not there, and a
false divergence is expensive in the worst way — it accuses two managers of
inconsistency when they were answering different questions, and the first
person to read one of those learns to ignore the stage.

The measured instance is real and is what makes this worth asking rather
than assuming: in one orchestrated run six managers hit a CI gate and merged
with a documented waiver while two read the same gate strictly and parked
themselves `blocked`. Same repository, same rule, same hour. Invisible to
the verifier — each diff was fine. Invisible to the health pass — each pulse
was fine. It surfaced because a person asked why three pull requests were
sitting open, three days later.

## Sweep

`goal-directed` — enough to decide whether a mechanical check can separate
"same rule, two answers" from "two different situations". Not a survey of
conduct review generally, and not an answer to whether the sampling reviewer
#251 proposes is worth its cost: that is the human's, and the issue itself
declines to claim it.

## What would settle it

A corpus of merged edges from this repository's own history, with every pair
of branches a candidate rule would call divergent, hand-checked against what
those branches actually faced.

- A rule exists whose false positives are rare enough to name a rate for:
  the check is buildable and a plan follows, with that rate reported.
- Every candidate rule either misses the measured instance or flags pairs
  that were not divergent: the answer is that the judgement cannot be
  mechanised from artifacts, the sampling reviewer is the only route, and
  its cost is the human's decision — which is #251's own position, now with
  evidence under it.

Written before the method runs: a rule that flags the measured instance and
nothing else on a corpus of one is not evidence, because the instance is
what the rule was written from.

## Method

Not yet run. The corpus is this repository, over the window `feedback`
walks, whose default `JOHARNESS_FEEDBACK_EDGES` carries — read the value
rather than fixing a number here.

```bash
./joharness.sh feedback            # the window and the edges in it
git log --all --full-history --diff-filter=D --oneline -- 'docs/handover/*.md'
git show <that-commit>^:<path>     # each retired workstream file
```

Every finished workstream file is recoverable that way, and its `## Review`
bullets, `## Decisions` and `## Blockers` are the free text a rule would
have to read. Candidate signals worth testing, cheapest first: two branches
whose `status: blocked` reasons name the same file or the same command; two
branches whose findings cite the same rule path; two branches in one wave
whose dispositions on the same anchor differ.

For each candidate, record the pairs it flags AND the pairs it misses. A
rule scored only on what it catches is a rule scored on the instance it was
written from.

## Findings

OPEN. Nothing measured yet. Filed to keep a promise
`docs/plans/findings-with-the-fix.md` made in its Out of scope, and so the
distinction that separates this from the rest of #251 — judgement, not cost
— is not lost with the session that drew it. That plan has since been
withdrawn on its own backtest (`.agents/docs/handover/README.md`,
Reviewing), which strengthens rather than weakens this question: the ONE
conduct check that looked mechanical turned out not to be, so whether any of
them is remains open.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it. The
plan that would have — the one conduct check that looked mechanical without
judgement, whether a finding shared a commit with its fix — was withdrawn on
its own backtest, measured in `.agents/docs/handover/README.md`, Reviewing.
Nothing in this question turned on that one, and its withdrawal leaves this
one the only route left to a conduct check that is not a session. A plan
follows beside it only if this closes YES.

The rest of #251 stays with the human: whether a sampling conduct reviewer
earns a session beyond the cap. This node does not decide that and must not
be read as arguing for it. If the answer is NO, that decision gets one more
fact under it, which is all this is for.

## Verification

None yet; no finding to verify. When one exists it needs a second context
per `.agents/docs/research/README.md`. For this question the second context
must re-read the flagged pairs' workstream files itself — the claim is about
what those files say, so a verification that trusts the first reader's
summary of them verifies nothing.

## Graduates to

`.agents/docs/orchestrated.md`. Peer divergence is a property of a FLEET —
it does not exist with one manager — and that file already carries what the
orchestrated mode measured and what it costs. A yes lands there as a
mechanism; a no lands there as a measured limit on what the mode can see
about itself.
