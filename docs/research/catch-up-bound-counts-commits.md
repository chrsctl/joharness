---
research: catch-up-bound-counts-commits
urgency: normal
agent: sonnet
effort: high
graduates: .agents/docs/consumer-repos.md
---

<!--
Report from the consumer chrsctl/gx, filed on the canonical. Canonical decides.
-->

## Question

Does `finish`'s CATCH-UP bound (`JOHARNESS_CATCHUP_COMMITS`, default 20 base commits) measure how far the base moved, when a consumer's merged pull requests carry 5-8 commits each?

## Echo

CATCH-UP lets a head that went behind during a green `finish` re-check cheaply
instead of re-running the full pass, provided the base moved "a little" and
touched no shared file. "A little" is counted in commits. If a consumer's pull
requests are merge commits carrying several commits each, 20 commits is only a
few pull requests, and CATCH-UP refuses on ordinary traffic. What rests on it:
whether green full passes are thrown away for want of a catch-up that the
no-shared-file condition would have allowed.

## Sweep

`goal-directed`: one consumer (chrsctl/gx), one 12-hour window of its manager
fleet, and gx's `origin/main` history over the same window.

## What would settle it

Yes, it measures it: refusals over the bound happen when many pull requests
landed. No: refusals over the bound happen when only 2-4 pull requests landed,
because each carries 5-8 commits.

## Method

- Manager transcripts read with `list_events` across 27 gx manager sessions,
  2026-11-10T22:00Z to 2026-11-11T10:10Z, by the gx session that wrote this
  brief. Second context for this reading: none yet — a session tooled for
  `list_events` on gx (or the operator) has to re-take it; this checkout's
  verifier cannot.
- In a gx checkout, after `git fetch origin main`, per window `<a>..<b>`:
  `git log origin/main --since=<a> --until=<b> --format=%h | wc -l` and
  `git log origin/main --first-parent --merges --since=<a> --until=<b> --format=%h | wc -l`.
  Run twice on 2026-11-11 by two gx sessions; same output.

## Findings

- **F1. Most finishes that went behind did not catch up.** 66 `finish` runs
  across the 27 sessions: 34 pass, 7 behind, 22 red, 3 unknown. About 9 green
  full passes (~3.3 h, estimated) were discarded because `origin/main` moved
  before the merge. CATCH-UP fired (re-run 0-1 min) in only 2 sessions
  (reeve-fit-access, reeve-fit-field-usage-door). Source: the `list_events`
  reading in Method.
- **F2. Worst case: seven green finishes before one merge.** Manager
  calendar-step-speak-for had seven green finishes ~26 min each between 23:08
  and 01:31, merged at 02:06, 178 min after its first finish. Its own lines:
  00:37 "Passed again (1537 s), and main is 12 ahead again. Main moves faster
  than one `finish` run."; 01:03 "Pass on d938e8a27 (1553 s), but main is 24
  ahead now."; 01:31 "Six green passes, but main (43 commits ahead now) moves
  faster than one 26-minute `finish`." Source: the `list_events` reading in
  Method.
- **F3. 20 commits is 3-4 pull requests on gx.** Commits vs first-parent
  merges on gx `origin/main`: 2026-11-10T23:08..11-11T00:37 31 commits / 4 PRs;
  00:37..01:04 19 / 3; 01:04..01:31 14 / 3; 01:50..02:21 4 / 2; whole window
  22:00..10:10 220 / 27, about 8 commits per merged pull request. Source: the
  two `git log` commands in Method.
- **F4. Over the bound by commits, not by pull requests.**
  reeve-fit-field-order-door at 02:21, "`origin/main` moved 33 commits during
  the 31-minute `finish`". Source: the `list_events` reading in Method.
- **F5 (context, a second cause, not the question). Renumbering also takes a
  branch out of CATCH-UP.** 10 of the 27 sessions renumbered criterion ids
  after a merge; a renumber edits files the base also changed, which also takes
  a branch out of CATCH-UP by the no-shared-file condition. gx handles that on
  its own side (its plan criterion-id-blocks). Source: the `list_events`
  reading in Method.

## Consequence for the queue

Proposal; canonical decides. In `.agents/docs/consumer-repos.md` § Local checks
(CATCH-UP) and `finish`: count first-parent merges (pull requests) on the base
rather than commits, e.g. `JOHARNESS_CATCHUP_MERGES` default 5, keeping the
no-shared-file condition and the one-catch-up-per-full-run rule unchanged; or
at least print both numbers (commits and first-parent merges) in the CATCH-UP
refusal line so consumers can tune the bound from evidence. Cost, already
documented there: a semantic clash across disjoint files passes a catch-up; a
wider bound widens that window.

## Verification

Not yet verified from a context that did not produce the findings.

- F3: GROUNDED — re-run independently by a second gx session; numbers match.
- F1, F2, F4, F5: WEAK — one session's transcript reading.

## Graduates to

`.agents/docs/consumer-repos.md`, which documents CATCH-UP and
`JOHARNESS_CATCHUP_COMMITS`.
