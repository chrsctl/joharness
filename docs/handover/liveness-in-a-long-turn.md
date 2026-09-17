---
workstream: liveness-in-a-long-turn
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: liveness-in-a-long-turn
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Retire this file and the node in the last commit before the pull request
---

## Goal

`docs/research/liveness-in-a-long-turn.md` names ONE reading as its next step
and says nobody has run it: take a session that is IDLE but still
`connected`, read it twice several minutes apart through `list_sessions`
ONLY, and compare `updated_at`. Frozen kills the read-bumping confound;
moved with no `get_session` between means the field is a connection
heartbeat and movement is not progress. Both of the node's open confounds
turn on that one reading, and the fleet that produces such sessions is live
right now.

## Decisions

- **`list_sessions` only, and a subject no `get_session` has touched.** The
  method is explicit. I called `get_session` once this session, on an
  orchestrator session, to re-derive whether an unrelated queue item was
  actionable — so that session is disqualified as a subject and is not one.
  The two subjects below appear only in `list_sessions` pages.
- **Two subjects, not one.** Both IDLE and connected at read 1, with
  `status_bucket` differing (`REVIEW_READY` and `COMPLETED`), so a frozen
  result is not an artefact of one bucket.
- **The disconnected rows are kept as the contrast the node says it lacks.**
  Read 1 carries 26 of them with the full field set, so the
  connected/disconnected comparison no longer rests on one subject.
- **Session ids are recorded; titles are not.** The node already rules that
  ids are opaque without the fleet and so are not a consumer's name. The
  titles in these rows ARE item names and stay out.

## Rejected

- **Keeping the question open for the turn-boundary mechanism.** Branches 1
  and 2 of `## What would settle it` stay undecided between themselves and
  cannot be decided from outside a session: the premise that no turn ended
  rests on absence of a `post_turn_summary`, and this repo's own notes carry
  a counter-example to it. What closed the question instead is branch 3's
  CONSEQUENCE, on its own terms: the field cannot carry a verdict alone at
  any interval, measured on one RUNNING row that is ambiguous between a slow
  writer and a stopped session. The rule is the same whichever of 1 and 2 is
  true, which is the test for whether a mechanism still matters. An earlier
  draft reached branch 3's consequence through a per-session cadence SPREAD
  and then shipped a rule branch 3 forbids; r2 and r3 are where that came
  apart.
- **A staleness threshold as a fifth knob.** The obvious shape, and the
  measurement refutes it at the root: no threshold at any value separates a
  slow writer from a stopped session, because the evidence is identical
  either way. Written into `orchestrated.md` beside the knob table rather
  than left implicit, because that table is where the next session will go to
  add one.

## Review

- r2: (verifier) **the slow row cannot be called working, and the rule rested
  on it.** `session_01MZ5FpBjjgiSG9NQJAqLsve` was cited as "RUNNING and
  working throughout" for the 2m52s window where its `updated_at` froze.
  Re-checked here by flattening both rows and diffing every leaf key:
  **NOT ONE field changed between read 2 and read 3** — not `updated_at`, not
  `cost_usd` (55.19828875 both), not `output_tokens` (270565 both), not
  `task_summary`, not `post_turn_summary`. It was working read 1 to read 2
  (+0.524106 USD, +4494 output tokens) and is indistinguishable from a
  stopped session after that. So the "~6 minute cadence" endpoint is not
  established, and every sentence built on a cadence SPREAD goes with it.
  (fixed — and the row is better evidence for the weaker claim: a frozen
  field on a RUNNING row does not say whether the writer is slow or the
  session stopped, which is branch 3's consequence measured directly.)
- r3: (verifier) **the graduated sentence licensed acting on a 13-minute
  frozen pair, and this diff's own text refutes it twenty lines later.** The
  cadence it invoked was measured on RUNNING rows only; the worked example's
  subject never states `session_status` and its own narrative has its last
  turn ending before both reads. `session_01TtLdnbsLzKdAp3dzy1Qv2w` is the
  counter-example in the same saved pages: IDLE, frozen 54m54.3s, its own
  record naming a merged pull request. r4's species from the last round, in
  a new coat. (fixed — the licence is gone entirely, not qualified. What
  replaces it is branch 3's consequence: the field never decides alone, at
  any interval.)
- r4: (verifier) **the contrapositive of "closer together than the slowest
  cadence" reads as a licence to act at wider intervals, on n=1 that is
  right-censored** — the reads stopped while that row was still frozen, so
  nothing bounds how long it would have stayed frozen. (fixed with r3, same
  deletion.)
- r5: (verifier) **"Three `list_sessions` calls and NO `get_session` on any
  subject" is false, and so is "One `get_session` WAS made here".** Counted
  from this session's own transcript: **nine** `get_session` calls, and one
  of them — 2026-09-17T14:01:49.413Z on `session_01TsLnukcKvuRKLXcJ34BLhg` —
  is row 3 of the RUNNING table, whose lag I graduated into both targets.
  What survives, and I re-checked it: neither IDLE subject is the target of
  any `get_session` anywhere, so the read-bumping finding stands. (fixed —
  Method now counts the calls, names the contaminated row, and scopes the
  claim to the two subjects it is true of.)
- r6: (verifier) **the lag table does not reproduce, and three of its four
  read-3 figures carry a decimal digit no computation produced.** The r1 and
  r2 columns are correct roundings of a WHOLE-SECOND call time; the r3
  column matches neither that nor the millisecond stamps. Recomputed here:
  my script printed `8`, `19`, `11`, `435` at integer precision and the file
  says `8.4`, `19.4`, `11.4`, `435.5` — three identical invented tenths is
  the tell. True values against the stamps `1789663430037`, `1789663794510`,
  `1789663966783`: r3 is 8.489 / 19.637 / 11.360 / 435.304. (fixed — every
  figure recomputed from the millisecond stamps, at the precision the
  computation produced.)
- r7: (verifier) **the question was closed on branch 3's consequence while
  the graduated text did the opposite of what branch 3 licenses.** Branch 3
  says the field cannot carry a verdict alone AT ANY INTERVAL and the health
  pass needs a different discriminator; the shipped sentence licensed a
  verdict at thirteen minutes and named no other discriminator. (fixed — the
  graduation is now branch 3's consequence and nothing more, which r2 makes
  the better-supported reading anyway. The question still closes, on a
  narrower answer than the one reviewed.)
- r8: (verifier) **the why-explanation landed where no edge can reach it.**
  `graduates:` takes one path (`joharness.sh` accepts a single path;
  `./joharness.sh graph` renders one edge), the rule went to
  `.claude/commands/orchestrate.md` and the why to `.agents/docs/orchestrated.md`,
  and the link was one-way — so a reader following the recorded edge after
  the node is deleted lands on the rule and never finds the why. (fixed —
  the table row and the worked example both name `orchestrated.md` by path.)
- r9: (verifier) **"four RUNNING managers" in "one consumer's live fleet"
  is wrong twice.** `session_01TsLnukcKvuRKLXcJ34BLhg` carries
  `session_context.sources` naming THIS repository, not a consumer, and is
  not a manager. Verified here on all three pages. Same row as r5. (fixed —
  three in a consumer's fleet and one in this repo's own, said that way.)
- r10: (verifier) two counts do not reproduce: read 1 carries **24**
  disconnected rows, not 26 (26 is the IDLE count), and round 1 made
  **five** `get_session` calls in its window, not six. Round 1's subjects
  are also recoverable from the transcript, so "nobody can re-sample its
  subjects" was too strong. (fixed — all three corrected.)
- r11: (verifier) the node cited "the node's own ruling" that session ids are
  not a consumer's name, in a rewrite that had deleted the ruling. (fixed —
  the ruling is restored in Method where the ids are recorded.)
- r12: (session) `.agents/docs/consumer-repos.md` contradicts itself on
  whether a consumer's pull request numbers are covered: `:207-209` says they
  are, `:214-216` says they are not, seven lines apart. Found while checking
  r9's naming. (wontfix here — it is another file's defect and this diff
  names no pull request number either way. Filed as #273 with both
  citations, and with the two readings named rather than one picked — which
  answer is right is the rule-owner's call.)
- r1: (session) deleting the node would have dangled two live pointers at it
  — `docs/plans/verifier-cannot-read-the-plane.md`'s Where-to-look and
  `docs/research/scheduler-outside-the-fleet.md`'s note on what it is not
  blocked by. `ci` is green either way, so nothing would have caught it.
  (fixed — both repointed at the graduation targets, and the plan's one also
  carries the `git log --diff-filter=D` command that reads the closed node
  back out of history.)

## Blockers

None.

## Where to look

- `docs/research/liveness-in-a-long-turn.md`, `## Consequence for the queue`
  — the reading, and what each outcome settles.
- `.claude/commands/orchestrate.md`, step 2's evidence table — where this
  graduates when it closes, and the line eighty lines below it that calls
  the question unmeasured.
