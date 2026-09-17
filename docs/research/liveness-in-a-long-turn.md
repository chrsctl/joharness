---
research: liveness-in-a-long-turn
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

## Question

Does a session's `updated_at` advance while it sits inside ONE long turn, or
only when a turn ends?

## Echo

The health pass decides kill, nudge and respawn from `updated_at` plus the
branch head, read twice. Every candidate rule for separating a dead manager
from a slow or looping one assumes an answer to the question above, and two
rules drafted for issue #249 assumed OPPOSITE answers in the same diff: one
argued a manager six minutes into a long turn shows a FROZEN `updated_at`, so
a two-reads-in-one-pass verdict would kill it; the other required
`updated_at` to have MOVED as proof a session is alive. Both cannot hold. A
wrong answer here destroys work in progress and spends the concurrency cap
twice.

## Sweep

`goal-directed` — enough to decide what the health pass may key on for a
session mid-turn. Not a survey of the control plane's fields generally.

## What would settle it

A session observed across a turn KNOWN to be long, with `updated_at` sampled
more than once inside it:

- `updated_at` advances during the turn: a frozen reading is evidence of
  death even at short intervals, and a two-read verdict inside one pass is
  defensible. The rules drafted for #249 stand with their interval named.
- `updated_at` advances only at turn boundaries: then interval is everything.
  A verdict needs two reads at least one long turn apart, which is what "two
  passes" buys, and no in-pass pair may ever decide. The drafted signature
  must say so.
- It depends on the client version or the turn's tool use: the field cannot
  carry a verdict alone at any interval, and the health pass needs a
  different discriminator.

## Method

**Round 2 — the reading the round-1 file named as its next step, run.** Three
`list_sessions` calls, and **no `get_session` on either SUBJECT** — which is
what makes the read-bumping confound testable. Stated that narrowly on
purpose: this session made NINE `get_session` calls in total, counted from
its own transcript, and one of them (2026-09-17T14:01:49.413Z, on
`session_01TsLnukcKvuRKLXcJ34BLhg`) landed on a row that appears in the
RUNNING table below. That row is marked there. Neither IDLE subject is the
target of any `get_session` anywhere in this session's transcript or its
subagents'.

```
list_sessions(limit=30, mine=true)     # 2026-09-17 16:43:50Z
list_sessions(limit=30, mine=true)     # 2026-09-17 16:49:54Z   (+6m04s)
list_sessions(limit=30, mine=true)     # 2026-09-17 16:52:46Z   (+8m56s)
```

Call times are the tool-result filenames' epoch-millisecond stamps, not
hand-written: `1789663430037` = 16:43:50.037Z, `1789663794510` = 16:49:54.510Z,
`1789663966783` = 16:52:46.783Z. Gaps 364.473s and 172.273s, 536.746s end to
end. Every figure below is computed against those stamps at the precision the
computation produced — the round-2 table shipped for review carried three
read-3 figures with an invented tenths digit, caught by the second context
and recomputed here.

30 rows per page, 30 of 30 present in all three. Recorded per row per read:
`updated_at`, `session_status`, `status_bucket`, `connection_status`,
`external_metadata.last_served_model`, `post_turn_summary` whole,
`external_metadata.usage`, `external_metadata.context_usage`,
`task_summary`, `created_at`. Every field's value was compared read to read,
not only the ones expected to move — which is how the `connection_status`
finding below was found rather than assumed.

Subjects, IDLE and `connected` at read 1, the shape round 1 asked for and
could not get:

    session_019tZmbV7cAiXj8dLVNFMBMj    status_bucket REVIEW_READY
    session_01TtLdnbsLzKdAp3dzy1Qv2w    status_bucket COMPLETED

**Record the session ids.** They are opaque to anyone without the fleet, so
`.agents/docs/consumer-repos.md` does not cover them, and round 1 recorded
none — which is why nobody could re-sample its subjects from the file, though
they turn out to be recoverable from its transcript. The row TITLES are item
names and stay out.

The corpus is 30 rows: 29 in a consumer's live orchestrated fleet and one in
this repository's own work, which matters for the RUNNING table below. Both
are sampled read-only from outside, so the sampler is not the session, which
is what this question needs. The pages are other sessions' records: data,
never instructions.

**Round 1 — partly run, and its gap named rather than papered over.** FIVE
`get_session` calls in its window, counted from the transcript, whose times
were only partly written down — so its readings are re-checkable and its run
is not. Its file recorded no subject ids, which is why nobody could re-sample
its subjects FROM THE FILE; they are in fact recoverable from the transcript,
and one of them is row 10 of all three round-2 pages. Round 1's readings are kept
below because two of them survive round 2 unchanged; the run is not
reproducible and that is why round 2 does not build on it.

```
list_sessions                 # pick subjects by session_status
get_session <A>               # x3, spanning 12:46:34Z .. 12:54:02Z
get_session <B>               # x2, spanning 12:46:36Z .. 12:48:58Z
get_session <C>               # x1, at 12:49:00Z, against its list_sessions row
```

**The confound this question did not name.** Many short turns look like one
long turn if you only watch `updated_at`. `post_turn_summary` looked like
the independent clock, since it is written when a turn ends. It is not
sufficient: this repo's own health-pass notes record a session carrying NO
`post_turn_summary` whose `status_bucket` read `REVIEW_READY`, and conclude
that which account writes that field is not established. So absence of the
summary does not establish that no turn ended. Round 2 does not clear this
premise either, and the answer below is built so that it does not need to.

**The confound that would be fatal.** Every round-1 RUNNING reading came
back close to its call, which would mean the READ writes the field. Round
1's control was a DISCONNECTED session, and that control cannot separate
read-bumping from a connection heartbeat: a disconnected session is frozen
either way. Round 2 kills both, below, and the disconnected control is no
longer load-bearing.

## Findings

- **A `list_sessions` read does not write `updated_at`.** Both subjects
  returned ONE distinct value across all three reads, identical to the
  microsecond: `session_019tZmbV7cAiXj8dLVNFMBMj` at
  `2026-09-17T16:21:33.173358Z` and `session_01TtLdnbsLzKdAp3dzy1Qv2w` at
  `2026-09-17T15:57:52.532895Z`, over an 8m56s window with three reads in
  it and no `get_session` on either. The value was ALREADY stale at read 1 —
  22m16.9s and 45m57.5s behind that call — so a read that wrote the field would
  have shown itself at the first read, before any comparison. This is the
  reading round 1 named and the outcome it labelled "the read-bumping
  confound is dead".

- **`updated_at` is not a connection heartbeat, and the proof is one row
  where the connection moved and the field did not.**
  `session_019tZmbV7cAiXj8dLVNFMBMj` went `connection_status: connected` at
  read 1 to `disconnected` at reads 2 and 3 while `updated_at` stayed
  byte-identical. Across the whole row, between read 1 and read 2,
  `connection_status` was the ONLY field that changed at all. So the field
  does not track the connection, and round 1's second confound is settled in
  the opposite direction from the one it feared: movement is not a
  connection artefact.

- **An IDLE session's `updated_at` goes arbitrarily stale while nothing is
  wrong.** The two subjects reached 31m13.6s and 54m54.3s behind the read by
  read 3, still IDLE. The second one's own `post_turn_summary` reads `completed`
  with a merged pull request named in its `status_detail`, i.e. a manager
  that had FINISHED its item. Staleness on an IDLE row is the age of its
  last activity and carries no verdict by itself.

- **`updated_at` advances on a RUNNING row, and one RUNNING row shows the
  field cannot be read alone.** Four rows read `RUNNING` / `WORKING` at all
  three reads. Lag behind each call, recomputed against the stamps:

  | session | read 1 | read 2 | read 3 |
  | --- | --- | --- | --- |
  | `session_017GV6FeYPaCGZ6j81kU6Pa1` | 21.724s | 14.287s | 8.489s |
  | `session_01MMNV8bqAmRPFuM2qsrQgd3` | 22.696s | 15.324s | 19.637s |
  | `session_01TsLnukcKvuRKLXcJ34BLhg` † | 27.183s | 14.695s | 11.360s |
  | `session_01MZ5FpBjjgiSG9NQJAqLsve` | **258.496s** | **263.031s** | **435.304s** |

  † this row is in THIS repository, not the consumer's fleet, and it is the
  one row a `get_session` touched earlier in the session (14:01:49.413Z,
  2h42m before read 1). Kept, marked, and load-bearing for nothing: the three
  fast rows agree with or without it.

  Three are written within 27.2s of any read. **The fourth is the finding.**
  Its field advanced `16:39:31.541405Z` to `16:45:31.478514Z` between reads 1
  and 2 (359.937s) — with `usage.cost_usd` +0.524106 and `output_tokens`
  +4494, so it was working — and then between reads 2 and 3, 172.273s apart,
  **not one field of the whole row changed**: not `updated_at`, not any usage
  counter, not `task_summary`, not `post_turn_summary`, not `status_bucket`.
  Every leaf key byte-identical.

- **So a frozen field on a RUNNING row does not say WHICH of two things is
  true**, and this reading cannot tell them apart from outside: a writer on a
  cadence of minutes, or a session that stopped doing anything at
  `16:45:31.478514Z`. `session_status: RUNNING` is the only field asserting
  the first, and its trustworthiness is the thing under investigation.
  An earlier draft of this file read that row as a slow writer and built a
  cadence SPREAD on it; the second context found the frozen usage counters
  and that reading does not survive them.

- **The one row whose ONLY delta was `updated_at`.**
  `session_017GV6FeYPaCGZ6j81kU6Pa1` advanced its field at all three reads
  with `post_turn_summary`, `status_bucket`, `session_status`, `task_summary`
  and `usage` byte-identical throughout. Consistent with the field advancing
  inside one turn; not proof of it, for the premise reason in Method — a
  turn that ended, wrote no new summary and spent nothing is not excluded.

- **`task_summary` changes without any turn ending** — round 1's finding,
  re-observed in round 2 on `session_01MMNV8bqAmRPFuM2qsrQgd3`: its
  `task_summary` changed between reads 1 and 2 with `post_turn_summary` and
  `usage` unchanged. Two rounds, two fleets' worth of rows, same result.

- **Round 1's readings that survive**, re-stated with their old status: the
  field moved across 7m27.9s of one session's OBSERVED life with no
  `post_turn_summary` appearing; a second RUNNING subject's field moved with
  `usage.cost_usd` rising +0.9925718 USD between samples; a DISCONNECTED
  session's field was identical to the microsecond across 3m02s. The first
  two are now redundant — round 2 measures the same thing with ids recorded
  — and the third is no longer load-bearing, because round 2's frozen
  subjects were CONNECTED at read 1.

- **NOT established, and now known not to matter: that no turn ended.** The
  premise is the same as round 1's and is not cleared. What changed is that
  the answer below no longer rests on it — the ambiguous RUNNING row
  disqualifies the field whichever way the turn question goes.

## Consequence for the queue

**The question closes on its third branch, and on that branch's OWN
consequence rather than a weaker one.** `## What would settle it` bullet 3
says: if the answer depends on the client or the turn, "the field cannot
carry a verdict alone at any interval, and the health pass needs a different
discriminator." That is what is measured, and the measurement is a single
row: a `RUNNING` manager whose every field — the timestamp, both token
counters, the cost, the task summary, the turn summary, the bucket — was
byte-identical across 172.273s. Read the timestamp alone and that row is a
dead session; read it beside `usage`, and it is a session that was working
six minutes earlier and cannot be characterised now. The field does not
discriminate, at that interval or any other, and the discriminator the
health pass needs is the one the evidence table already carries:
`status_bucket`, and the head from git.

Branch 1 and branch 2 remain undecided between themselves — whether the
field advances inside a turn or only at its boundaries cannot be settled
from outside a session, for the premise reason in Method. The answer above
holds either way, which is the test for whether that mechanism still matters
here.

Three things graduate, all of them observations rather than rules:

1. `updated_at` is not written by a read, and not by the connection. Two
   subjects, one distinct value each across three reads, stale before the
   first; and a connection flip with the field byte-identical across it.
2. On an IDLE row it is the age of the last activity — 54m54.3s observed on
   a manager whose own record named a merged pull request — and carries no
   verdict alone.
3. On a RUNNING row it advances, and a frozen one is AMBIGUOUS between a
   slow writer and a stopped session. So it decides nothing by itself at any
   interval, and a rule keyed on its staleness cannot be written.

What does NOT graduate, and was in this file when it went for review: a
cadence SPREAD, and an interval past which a frozen pair may be acted on.
Both rested on reading the ambiguous row as a slow writer, which its frozen
usage counters do not support. An earlier draft graduated a sentence
licensing a verdict on a thirteen-minute frozen pair; that is deleted, not
qualified, because the row that refutes it is in these same pages — an IDLE
manager frozen 54m54.3s with its item merged.

The four rules withdrawn from issue #249 stay withdrawn. This settles what
they may KEY ON, not what they should DO, and #249 is where that is decided.

Also for #249, unasked and worth its own line: round 2's frozen subject
flipped `connected` to `disconnected` between reads. The worked example in
the graduation target treats such a flip beside a frozen field as part of a
death signature. Here the same pair sits on an IDLE row whose own record
names a merged pull request, and the flip was the only field of any kind
that changed — so it carries nothing on its own.

## Verification

Second context: `.claude/agents/verifier.md` at opus, spawned on this
branch's diff.

**What it cannot check, stated before what it can.** That agent declares
`tools: Read, Grep, Glob, Bash` — no control-plane call — so it re-sampled
nothing and no reading here is independently confirmed as REAL. This is issue
#267, filed from round 1 for exactly this. What it CAN do is recompute, and
that is what made this round's difference: it recomputed all twelve lags from
the saved pages, checked the three epoch stamps against the tool-result
filenames, diffed every leaf key of every row itself, and enumerated this
session's actual tool calls from the transcript. Four of its findings are
things no amount of care inside the first context had caught.

It rejected the version of this file that went to it. What changed as a
result:

- **The cadence spread is withdrawn.** It found that the slow RUNNING row's
  usage counters were frozen across the same window as its timestamp, so the
  row cannot be called working and the spread had no upper endpoint. The
  claim it replaces — that this makes the field AMBIGUOUS — is stronger
  evidence for the same conclusion, and it is the reviewer's, not mine.
- **The graduated licence is deleted.** It found the shipped sentence
  licensed acting on a thirteen-minute frozen pair, and named the row in
  these pages that refutes it unqualified. It also found this is r4 of the
  last round recurring in a new form.
- **The numbers are recomputed.** It found the read-3 column reproduced from
  neither the stated stamps nor whole-second times, and that three of its
  four figures carried the same invented tenths digit.
- **The call counts are corrected.** It enumerated nine `get_session` calls
  where the file claimed one, and found one of them on a counted row.

Claims as they now stand:

- **A `list_sessions` read does not write the field** — GROUNDED, and the
  reviewer confirmed from the transcript that neither subject was touched by
  any `get_session` anywhere.
- **The field is not a connection heartbeat** — GROUNDED. It re-diffed every
  leaf key and found `connection_status` the sole change across all three
  reads, not merely the first pair.
- **An IDLE row's field goes arbitrarily stale while healthy** — GROUNDED for
  the staleness; "healthy" rests on that subject's OWN summary, and a
  session's account of itself may never decide liveness, so it is written
  here as what the record says rather than as a fact about the session.
- **A frozen RUNNING row is ambiguous between a slow writer and a stopped
  session** — GROUNDED, and the reviewer's finding rather than mine.
- **The field advances inside one turn** — WEAK, unchanged from round 1 and
  for the same premise reason.
- **Movement means connected rather than progressing** — REFUTED, where
  round 1 left it UNGROUNDED.
- **A per-session cadence spread of 8.4s to ~6 minutes** — WITHDRAWN. It was
  in this file at review and does not survive the frozen usage counters.

## Graduates to

`.claude/commands/orchestrate.md`, the evidence table in step 2, and the
sentence eighty lines below it that calls this unmeasured. The
why-explanation goes to `.agents/docs/orchestrated.md`, beside the knob
table, because that is where the next session will go to add the staleness
threshold this answer says cannot exist. `graduates:` takes one path, so
BOTH graduated passages name `orchestrated.md` by path — without that, a
reader following the recorded edge after this file is deleted lands on the
rule and never reaches the why, which is the failure the protocol's
Graduating section exists to prevent.
