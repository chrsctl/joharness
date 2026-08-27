# Feedback loops, and how to score one

A harness rule that never gets better is a rule that was guessed once. This
document: what a feedback loop is here, how to tell a good one from a busy
one, and what this repo's own history says when you count it.

Measure it yourself: `./joharness.sh feedback`. Every number below is counted
from git at read time, nothing stored. Trust counted numbers, never written
numbers — including the ones on this page, which were true on 2026-08-24 and
are re-derivable in two seconds.

## The four stages

A loop that improves anything has to clear four bars in order. Each one is a
place a loop dies quietly:

1. **Detect** — something notices the defect. (Review, CI, a gate.)
2. **Record** — the noticing survives the moment. (Findings in the workstream
   file's `## Review`.)
3. **Generalize** — one defect becomes a rule about a class of defects.
   (Graduation: `.agents/docs/handover/README.md`.)
4. **Prevent** — the rule reaches the next session before it repeats the
   defect, not after.

Stages 1 and 2 are cheap and visible, which is why most loops stop there and
still feel like loops. Stage 4 is the only one that changes an outcome.

## Scoring

Four yields, one outcome. The yields diagnose; only the outcome scores.

| Number | Question | Where it comes from |
| --- | --- | --- |
| Coverage | Does the loop run at all? | merged edges recording a review / edges carrying a workstream file |
| Retention | Does its output survive? | findings a later session can reach without archaeology |
| Generalization | Did a finding become a rule? | review-fix commits touching an `AGENTS.md` or `docs/` rule file |
| Cost | What did it take? | commits per finding, churn peak per branch |
| **Recurrence** | **Did the same thing come back?** | **file-level fixes landing where an earlier edge already fixed a finding** |

**Recurrence is the score. Everything else explains it.** A loop is good if
the same file stops drawing the same class of finding, and for no other
reason.

METRIC UNDER REPAIR: as computed today recurrence cannot fall — the dedup
set never clears, so the number saturates upward (`./joharness.sh
feedback` measured 36% on 2026-08-24, 54% on 2026-08-27, coverage steady).
Read it as volume, not signal, until `docs/plans/recurrence-can-fall.md`
lands.

### Volume is not a score

Counting findings and calling more of them better is the trap. The review
churn rule (`.agents/docs/agent-selection.md`) already establishes it from
measurement: finding counts are no signal, false in both directions — five
findings can be one real defect found five ways, and zero can be a review
nobody ran. A loop scored on volume optimizes for volume; the models under
this harness are literal enough to deliver exactly that.

Recurrence has the opposite property. It cannot be gamed by producing more
output, because producing more output is not what makes it fall.

## Measured here (2026-08-24)

39 merged edges, 28 carrying a workstream file, 46 recorded findings.

- **Coverage: 9/9 since the ledger, 0/19 before it.** The review ledger
  landed in PR #31. Every merged edge after it recorded findings; not one
  before it did. A step change on the commit that added the mechanism —
  the strongest evidence in this repo that a recording mechanism, not
  exhortation, is what makes recording happen.
- **Volume: 46 findings — 33 fixed, 6 wontfix, 2 verified-no-change, 5
  unmarked.** 5.1 findings per reviewed edge. The 5 unmarked all arrived on
  one edge, written without the TEMPLATE's `r1:` id: counted, but unlinkable
  to any file. The measure says so rather than dropping them.
- **Cost: 0.8 commits per finding, mean churn peak 1.7** against a threshold
  of 5. Reviews here are not what drives rework.
- **Recurrence: 7 of 19 file-level fixes (36%)** landed on a file an earlier
  merged edge had already fixed a finding in.
- **Hot spots:** `.agents/harness/AGENTS.md` drew findings on 4 separate
  edges; `.agents/harness/selftest.sh` on 3. The harness's own rule file is
  the most defect-prone file in the repo by this measure.
- **Retention: zero.** The finish ritual deletes the workstream file, by
  design — a file left on `main` reads as current. So all 41 findings live
  in merge history and nowhere a session is told to look. Nothing in the
  harness read them until `feedback` did.

One exact repeat is visible in the record: PR #34's r1 and PR #35's r9 are
the same defect one edge apart, and the second finding says so in its own
text. The loop's stages 1 and 2 worked perfectly both times. Stages 3 and 4
did not exist.

## What the numbers picked

Retention zero and recurrence 36% pick the same intervention: carry findings
past the merge that deletes them, and put them in front of the next session
that touches the same file. That is what `feedback` does — the scorecard, and
`feedback <path>` for what a file has already cost. The review step prints the
pointer for the files in the branch's own diff, which is the moment it pays.

The alternatives were weighed against these numbers, not against taste:

- **Running the review instead of recording it** (spawn reviewers per lens):
  coverage is already 8/8. Buys nothing the numbers show missing.
- **Gate self-measurement** (do the thresholds earn their keep): worth doing,
  but churn's mean peak of 1.8 against a threshold of 5 says the gates are
  quiet, not miscalibrated. Later.
- **Feeding outcomes back into agent selection**: needs recurrence per tier,
  which needs more edges than 4 days of history holds. Blocked on data this
  measure now accumulates.

## When the consumer is the detector

The four stages assume one repo. A consumer running this harness splits them:
**Detect** happens where the work is, **Prevent** only reaches it after a sync.
That extra hop is where this loop dies, and the direction rule
([`consumer-repos.md`](consumer-repos.md)) says only where the fix goes, not how
you get it there.

Walked three times in one consumer session, 2026-08-25. What that cost:

### 1. Decide whether the harness is actually wrong

The signal is that you fought it: a gate you argued with, a message you worked
around, a ritual you skipped. That signal is **not** evidence the harness is
wrong, and this is the stage that goes wrong.

Ask one question: **does the fact it states match what it measures?**

That session's handover guard said *"branch changes code but has no workstream
file"* on a branch whose diff was two `.md` files. The session concluded the
guard had misfired, stopped through it twice, and told its user the harness was
at fault. The guard was right — the branch was changing the queue documents
with no claim, which is exactly its job. What was wrong was one word in the
message and a comment promising an exemption the filter never implemented.

So the feedback was real and it was **about the wording, not the rule**. Had
the session trusted its irritation, it would have relaxed a check that had just
caught it — which is the reverse of a feedback loop.

> **Never relax a guard that just caught you.** Fix what made you misread it.

### 2. Carry the measurement, because canonical cannot reproduce it

Canonical has no consumers to measure on. The number is the whole contribution:

| what canonical got | what it could not have found |
| --- | --- |
| `finish` gate | *three of eight pull requests merged carrying their workstream file, each turning `main` red within seconds; the two that did not were the two that retired first* |
| guard wording | *a session read "code", saw two `.md` files, and stopped through a claim it owed — twice* |
| `decide_ref` | *`cleanup --apply` deleted a live claim on a checkout with no base ref* |

A defect report without its measurement is a preference. With it, the ADR or
the comment writes itself, and the next reader gets the reason rather than the
rule.

### 3. Land it in canonical, never in the consumer

Not doctrine for its own sake. **The next sync overwrites every harness-owned
file in the consumer**, so a harness fix made locally is deleted by the
mechanism whose job is keeping it current — silently, and usually weeks later
when nobody connects the two.

### 4. Inline or routed

The context rule keeps *sync* out of a session holding product work because a
sync diff is thousands of lines. Feedback is the opposite shape: the diff is
small and specific, and the evidence is in that session's head and nowhere
else. So:

- **Capture always, immediately.** In the workstream file's `## Review` if the
  branch has one, in the canonical pull request body otherwise.
- **Fix inline when it is small** — a message, a comment, a guard's scope.
- **Route it when it is not**, and carry the measurement into whatever picks
  it up.

### 5. Stage 4 is the sync, not the merge

A fix merged in canonical has not prevented anything in the consumer that
found it. It prevents on the sync that lands it, which is the one stage of the
loop nobody in either repo is watching — the consumer's session has moved on
and canonical never sees the consumer.

Close the loop by name: when the sync lands, check the thing that bit you is
gone. That session ran `./joharness.sh finish` on the very sync branch carrying
`finish`, which is the cheapest possible version of it.

## What this cannot see

Named because a measure that hides its blind spots is worse than no measure:

- **Only the newest 50 edges are read** (`JOHARNESS_FEEDBACK_EDGES`,
  default 50 — `joharness.sh:cmd_feedback`). Past that, findings fall out
  of every count above; the output names how many edges went unread.
- **Classes, not files.** Recurrence is measured on paths. Two findings of
  the same *kind* in different files read as unrelated; the same file drawing
  two unrelated findings reads as a repeat. Classifying prose needs judgment,
  and a field for sessions to fill in is a field that rots.
- **Commit-level attribution.** A finding is linked to its fix commit, so a
  commit carrying several findings attributes all of them to every file it
  touched.
- **Findings without the `r1:` id.** Attribution keys on the id the TEMPLATE
  prescribes. A bullet written without one still counts in volume — the
  handover hook counts it too — but nothing links it to a file. One of the
  nine reviewed edges here wrote all five of its findings that way, which is
  how the gap got noticed; the scorecard prints the count rather than
  quietly reading those edges as clean.
- **Disposition read from prose.** `(fixed)`, `wontfix` and "no change" are
  matched in the finding's text, so a finding saying "fixed; no change to the
  docs" reads as no-change. The alternative is a structured field per
  finding, and a field a hurried session fills in wrong is the failure mode
  delete-on-merge exists to avoid.
- **Renames.** A path recorded before a move resolves by unique-suffix match
  and otherwise stands as recorded. This repo's own `.agents/` move split one
  hot spot into two cold ones until that was fixed.
- **Four days.** 8 reviewed edges is enough to see a step change and a
  36% recurrence rate. It is not enough to see a slope. The number to watch
  is whether recurrence falls; ask again at 30 edges.
- **Merged history only.** An open branch has recorded nothing yet.
