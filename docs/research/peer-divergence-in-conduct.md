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

Run. The written corpus below ran first and produced nothing to test a
candidate rule against; the deviation that followed is the second block,
recorded here rather than left to Findings to explain alone (an unrecorded
method is a failed file).

```bash
./joharness.sh feedback            # the window and the edges in it
git log --all --full-history --diff-filter=D --oneline -- 'docs/handover/*.md'
git show <that-commit>^:<path>     # each retired workstream file
```

Result: 44 retired workstream files recovered (joharness's own 50-edge
feedback window), one `status: blocked` edge among them and it is a stale
`in-progress` label on an already-merged branch, not a real block. Zero
candidate pairs to test.

Deviation, `chrsctl/gx` (the consumer where issue #251's measured instance
happened — this repo's own corpus had nothing to test):

```bash
# attach and deepen
add_repo owner=chrsctl repo=gx; git clone --depth 1 .../gx /home/user/gx
git -C /home/user/gx fetch --depth=3000 origin main   # reaches the initial commit

# the blocked branch issue #266 named
git -C /home/user/gx show d87e17c8:docs/handover/crm-ui-dashboard-widget-marks.md

# the waiver convention: every merge that went ahead on red CI opens with
# the same literal sentence
git -C /home/user/gx log --all --grep="MERGED WITH GITHUB" -F --format='%H %ci %s'
git -C /home/user/gx log --all --grep="MERGED WITH GITHUB" -F | wc -l   # 47

# every status: blocked workstream file ever written in gx's history
git -C /home/user/gx log --all -p -- 'docs/handover/*.md' \
  | grep -B5 '^+status: blocked' | grep -E '^\+\+\+|^\+status'
# -> crm-ui-dashboard-widget-marks.md, crm-workflow-branching.md,
#    license-gate-issues.md (3 files, read each at the commit that added
#    the line, via git log --all -S"status: blocked" --format='%H' -- <path>)

# the earlier occurrence, and whether a waiver precedent existed when it blocked
git -C /home/user/gx log --all -S"crm-workflow-branching" --format='%H %ci %s' -- 'docs/handover/*'
git -C /home/user/gx log --all --format='%ci %H' --grep="MERGED WITH GITHUB" -F | sort

# the config fix, and whether the blocked branch's own text ever checked it
git -C /home/user/gx log --all -S"JOHARNESS_CHECKS=local" --format='%H %ci %s' -- joharness.conf
git -C /home/user/gx show d87e17c8:docs/handover/crm-ui-dashboard-widget-marks.md | grep JOHARNESS_CHECKS
```

Candidate signals tested, cheapest first: two branches whose `status:
blocked` reasons name the same file or the same command; two branches
whose findings cite the same rule path; two branches in one wave whose
dispositions on the same anchor differ. Only the first had any pair to
test — the other two had zero instances in either corpus, in both repos,
over all of history, not just the feedback window.

For each candidate, record the pairs it flags AND the pairs it misses. A
rule scored only on what it catches is a rule scored on the instance it was
written from.

## Findings

Run per Method, plus one deviation recorded here rather than silently: the
written corpus is "this repository" (joharness), and joharness's own
50-edge feedback window has no comparable instance — one `status: blocked`
edge, and it is a stale `in-progress` label left on a merged leftover
branch, not a real block (`./joharness.sh feedback`; the edge is PR #287's,
workstream `managers-closing-report`). With nothing in the written corpus
to test a candidate rule against, the measured instance itself was read
instead: issue #251 names it as happening in `chrsctl/gx`, and issue #266
(closed) names the exact commit. Added `chrsctl/gx` via `add_repo`, fetched
full history, and read it directly — a wider corpus than the Method names,
logged here so the finding does not look like it ran on the window
originally promised.

- **GROUNDED.** The blocked branch is `d87e17c8` in `gx`
  (`docs/handover/crm-ui-dashboard-widget-marks.md`, PR #403): `status:
  blocked`, body cites `runner_id: 0`, logs 404, and names PR #351's merge
  commit as precedent for a human-granted waiver. Second-context verified.
- **GROUNDED.** PR #351's merge commit (`106051b5`) opens its second
  paragraph with the literal sentence: *"MERGED WITH GITHUB'S CHECKS RED,
  on a waiver a human granted after this branch stopped and asked."*
  Second-context verified.
- **GROUNDED.** That exact phrase ("MERGED WITH GITHUB'S CHECKS RED")
  opens 47 merge-commit bodies across `gx`'s full history
  (`git log --all --grep="MERGED WITH GITHUB" -F | wc -l`) — a repo
  convention for "merged despite red CI," reused across at least three
  separate outage incidents weeks apart (Aug 13-14 billing; Sept 11-13
  runner allocation; Sept 16-17 recurrence of the same). Second-context
  verified.
- **GROUNDED.** Exactly 3 workstream files in `gx`'s entire history ever
  carried `status: blocked`: `crm-ui-dashboard-widget-marks.md`,
  `crm-workflow-branching.md`, `license-gate-issues.md`
  (`git log --all -p -- 'docs/handover/*.md' | grep -B5 '^+status:
  blocked'`, cross-checked against `grep -c '^+status: blocked'` on the
  same output = 3). Second-context verified by rerunning the same command.
- **UNGROUNDED as first written here, corrected below.** My first pass
  claimed only two of the three blocked files named the CI-outage cause
  and `license-gate-issues.md` was about something else. The second
  context went to the commit that actually added the line (`d18cb809`,
  not the later commit my first pass had read) and found the opposite —
  recorded as its own claim next.
- **GROUNDED.** All three blocked files name the *same* cause family: a
  GitHub Actions runner/billing outage. `license-gate-issues.md`, read at
  `d18cb809` (`git show d18cb809:docs/handover/license-gate-issues.md`,
  blocked 2026-08-14, the earliest of the three), reads: *"CI cannot
  run... the job reports `runner_id: 0`... This is a billing or
  spending-limit condition on the account."* Identical signature to the
  other two. In this repo's history, `status: blocked` has so far meant
  exactly one thing, always.
- **GROUNDED, and this is what makes the case for "divergence" weaker than
  issue #251's summary reads.** `license-gate-issues.md` (Aug 2026-08-14)
  blocked with NO waiver precedent anywhere in its window — the "MERGED
  WITH GITHUB'S CHECKS RED" convention did not exist until Sept 11. It was
  resolved by a FIX (`d18cb809`, `027b193d`: "record why CI cannot run",
  "stop CI paying twice"), not a waiver, and had no contemporaneous peer to
  diverge from. Not a divergence instance — the uncontested origin case.
- **GROUNDED.** `crm-workflow-branching` blocked itself at `2026-09-11
  14:41:35Z` ("CI allocates no runner, repo-wide, since 2026-09-07"). The
  earliest "MERGED WITH GITHUB'S CHECKS RED" commit in the whole history
  (`ee72e637`, PR #339) is timestamped `2026-09-11 16:03:42 +0200` =
  `14:03:42Z` — recomputed in UTC; the verifier confirms it lands *before*
  the block by ~38 minutes (my first pass had sorted raw offset strings
  and misread this as after). So a waiver precedent arguably existed by
  minutes, not hours, when this branch blocked — too close to call this a
  clean "no precedent yet" case the way `license-gate-issues` is.
- **WEAK.** PR #403's own merge commit (`5f989583`, merged by a human by
  hand per issue #266's correction) carries no waiver or outage text —
  one title line plus one short description line, nothing more (not a
  literal bare title with "nothing else" as my first pass overstated; the
  substance — no waiver narration where 47 other commits have it — holds).
  A rule keyed on the FINAL merge commit's own text would miss this branch
  outright; the signal only exists in the branch's own retired workstream
  file, written before the human merged it by hand.
- **GROUNDED.** `JOHARNESS_CHECKS=local` landed in `gx`'s `joharness.conf`
  at `fcad0961`, `2026-09-16T15:14:03Z` — 10h15m before `d87e17c8` (the
  block). `d87e17c8`'s own text never mentions `JOHARNESS_CHECKS` at all;
  it reasons entirely from the older human-waiver precedent. Peers in the
  same fleet, same day, correctly cited the new config instead (e.g.
  `5ee67086`, PR #439, merged ~13h after the block, during the same
  outage: *"JOHARNESS_CHECKS=local replaces that condition and no
  other"*).

**What a candidate rule can and cannot do with this.** A time-windowed,
cause-keyword rule — "a `status: blocked` workstream file whose text names
a GitHub Actions runner/billing cause, paired with a merge commit within
roughly a day whose text names the same cause and merges anyway" — catches
both real incidents here (`crm-workflow-branching` against the Sept 11
wave that includes PR #339; `crm-ui-dashboard-widget-marks` against the
Sept 16-17 wave that includes PR #439), each pairing the block against
however many same-window peers share the cause text, not against exactly
one. It raises no alarm spanning the three incidents against EACH OTHER —
Aug 13-14, Sept 11-13 and Sept 16-17 share the identical convention but a
day-scale window keeps them apart, which is the only false-positive shape
this corpus could have produced and didn't. That is evidence the window
and the keyword match do the job THEY were built for; it is not a
precision/recall count across many pairs, because this corpus has exactly
two incidents, not many, to count across.

But the rule that does this is not a peer-to-peer comparison — it is a
per-branch check against GROUND TRUTH (does the repo's own `joharness.conf`
already answer the condition this branch names as unresolved?), run against
one branch at a time, not a diff between two branches' artifacts. That is
exactly `.agents/docs/orchestrated.md`'s `analyst` role and
`JOHARNESS_IDLE_ANALYSIS`, built from issue #266 — the SAME incident this
file's Echo cites as "the measured instance" is the incident that already
produced the fix. Issue #266 is dated one day after the gap in #251's own
account (#251 says 09-13 to 09-16; the block it is describing is dated
09-17), which reads as the same run continuing past the date #251 gave it,
not a second occurrence.

Neither `joharness`'s corpus nor `gx`'s produced a single instance of the
Method's other two candidate signals — "two branches whose findings cite
the same rule path" or "two branches in one wave whose dispositions on the
same anchor differ." Zero pairs to test means zero evidence either way for
the GENERAL case #251's language reaches for (any rule, read two ways).
What is grounded is narrower than what was asked: one specific, recurring
shape (an infrastructure condition read two ways) is mechanizable, cheaply,
as a one-branch-against-config check — and this harness already has that
check. Nothing here shows a *peer-comparison* mechanism earns its keep
beyond it.

## Consequence for the queue

**Closes NO**, narrowly and for a specific reason rather than by default.
Not "every candidate rule misses the measured instance" — one does catch
it, correctly separating the two real incidents in this corpus from each
other and from a third, unrelated-in-time incident sharing the same
wording. What closes it NO is that the rule which catches it
is not a peer-comparison mechanism: it is a single branch's stated cause
checked against the repo's own current config, which is what
`JOHARNESS_IDLE_ANALYSIS` / the `analyst` role already does
(`.agents/docs/orchestrated.md`), built from the same incident (issue
#266) this file's own Echo cites as the measured instance. No new plan
follows, because the mechanism this question asked for already exists for
the one shape found, and nothing here shows a second, general,
peer-diffing mechanism is buildable: the Method's other two candidate
signals (shared finding-citation; same-wave differing disposition) have
zero instances in either corpus to test against, so the general claim in
#251 — any rule, read two ways, by any two peers — stays exactly where
#251 left it: not shown, not refuted.

The rest of #251 stays with the human: whether a sampling conduct reviewer
earns a session beyond the cap, for the three OTHER conduct questions it
raises that this file never addressed (a stalled `next:`, a backdated
finding, a self-asserting acceptance criterion). This node answers only
the fourth, and answers it: the "peer divergence" framing over-states what
the artifacts show. Re-read as two single-branch staleness cases rather
than as simultaneous disagreement, the fix already exists.

## Verification

Two independent second-context passes, neither in the context that wrote
the claims.

A `general-purpose` subagent re-ran every cited command against
`/home/user/gx` itself and read the primary sources, without access to
this file's prose. Of the 10 bullets above: 8 GROUNDED outright, 1 WEAK on
an immaterial wording point (the PR #403 bullet — substance confirmed,
"nothing else" overstated), 1 UNGROUNDED — my own first-pass claim that
`license-gate-issues.md` named a different cause, which the bullets above
now carry as its own UNGROUNDED entry followed by the corrected GROUNDED
one, per this file's own rule that a refuted claim needs its own word
rather than being silently rewritten. That pass also caught a
timezone-normalization error in my first pass (raw-offset string sort
instead of UTC) that had `crm-workflow-branching`'s block landing after
the earliest waiver precedent instead of ~38 minutes before it; corrected
above.

A `verifier` subagent (sonnet, per `.claude/agents/verifier.md`) then read
the DIFF itself — not the gx facts again, the write-up — and found seven
defects, tagged `(verifier)` in this branch's workstream file's `##
Review`: the research file not yet deleted despite arguing its own
closure; the tally above originally miscounted (fixed, this section); the
UNGROUNDED/corrected split not using the three required words (fixed); the
PR #403 bullet's GROUNDED tag contradicting this section's own WEAK (fixed
to WEAK); the Method section claiming "Not yet run" while Findings
described a run (fixed, Method rewritten); one Findings bullet naming no
reproducible command for a load-bearing count (fixed, command added); and
a vague "two days earlier" in the graduated `orchestrated.md` paragraph
with no named anchor date (fixed to exact dates). All seven fixed in this
same commit.

## Graduates to

`.agents/docs/orchestrated.md`. Peer divergence is a property of a FLEET —
it does not exist with one manager — and that file already carries what the
orchestrated mode measured and what it costs. A yes lands there as a
mechanism; a no lands there as a measured limit on what the mode can see
about itself.
