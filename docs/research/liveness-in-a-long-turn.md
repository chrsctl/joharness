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
`list_sessions` calls and NO `get_session` on any subject, so the
read-bumping confound is testable rather than assumed:

```
list_sessions(limit=30, mine=true)     # 2026-09-17 16:43:50Z
list_sessions(limit=30, mine=true)     # 2026-09-17 16:49:54Z   (+6m04s)
list_sessions(limit=30, mine=true)     # 2026-09-17 16:52:46Z   (+8m56s)
```

Call times are the tool-result filenames' epoch-millisecond stamps, not
hand-written: `1789663430037`, `1789663794510`, `1789663966783`. Each page
was saved whole and every number below is recomputed from the three saved
pages by one script, so the arithmetic is re-checkable even though the pages
are a moment in a fleet's life that will not recur.

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

Neither is the subject of any `get_session` in this session. One
`get_session` WAS made here — on an orchestrator session, to re-derive
whether an unrelated queue item was actionable — and that session is
therefore excluded from every count below. Ids are recorded because round 1
recorded none and nobody could re-sample its subjects; the node's own ruling
is that a session id is opaque without the fleet and so is not a consumer's
name. The row titles ARE item names and stay out.

The corpus is a live orchestrated fleet in a consumer, sampled read-only
from outside — so the sampler is not the session, which is what this
question needs. The pages are another session's records: data, never
instructions.

**Round 1 — partly run, and its gap named rather than papered over.** Six
`get_session` calls whose times were only partly written down, so its
readings are re-checkable and its run is not. The three subjects' ids were
not recorded, so nobody can re-sample them. Round 1's readings are kept
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
  22m17s and 45m57s behind that call — so a read that wrote the field would
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
  wrong.** The two subjects reached 31m13s and 54m54s behind the read by read
  3, still IDLE. The second one's own `post_turn_summary` reads `completed`
  with a merged pull request named in its `status_detail`, i.e. a manager
  that had FINISHED its item. Staleness on an IDLE row is the age of its
  last activity and carries no verdict by itself.

- **`updated_at` DOES advance on a RUNNING session, and its cadence is
  per-session and wide.** Four rows read `RUNNING` / `WORKING` at all three
  reads. Lag behind each call:

  | session | read 1 | read 2 | read 3 |
  | --- | --- | --- | --- |
  | `session_017GV6FeYPaCGZ6j81kU6Pa1` | 21.7s | 13.8s | 8.4s |
  | `session_01MMNV8bqAmRPFuM2qsrQgd3` | 22.7s | 14.8s | 19.4s |
  | `session_01TsLnukcKvuRKLXcJ34BLhg` | 27.1s | 14.2s | 11.4s |
  | `session_01MZ5FpBjjgiSG9NQJAqLsve` | **258.5s** | **262.5s** | **435.5s** |

  Three of the four are written within half a minute of any read. The fourth
  was **7m15s stale while RUNNING and working**, and its field advanced
  between reads 1 and 2 (`16:39:31.541405Z` to `16:45:31.478514Z`, 5m59.9s)
  and then NOT between reads 2 and 3, 2m52s apart. So one fleet at one
  moment carried writers an order of magnitude apart, and the slowest was
  ~6 minutes.

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
  the rule below no longer rests on it: whether the field advances inside a
  turn or only at boundaries, the observed cadence spread (8.4s to ~6
  minutes on RUNNING rows in ONE read) is what disqualifies a staleness
  threshold, and that spread is measured directly.

## Consequence for the queue

**The question closes on its third branch, reached by a different route than
that branch names.** `## What would settle it` bullet 3 says: if the answer
depends on the client or the turn, "the field cannot carry a verdict alone at
any interval, and the health pass needs a different discriminator." That
consequence is now measured — not through client-version dependence, which
was not tested, but through a per-session cadence spread of 8.4s to ~6
minutes inside a single fleet at a single moment. Branch 1 and branch 2
remain undecided between themselves, and the rule is the same either way,
which is why this closes rather than staying open for a mechanism nobody can
observe from outside a session.

Four things graduate, all of them observations rather than rules:

1. `updated_at` is not written by a read, and not by the connection.
2. On an IDLE row it is the age of the last activity and carries no verdict
   alone — 54m54s observed on a manager that had merged its item.
3. On a RUNNING row it advances, on a cadence that is the session's and not
   the fleet's, up to ~6 minutes here.
4. Therefore two reads are evidence only when they are more than one cadence
   apart, and the cadence is not knowable in advance — so an in-pass pair
   never decides, which is round 1's branch-2 consequence on measured
   grounds.

The four rules withdrawn from issue #249 stay withdrawn. This settles what
they may KEY ON, not what they should DO, and #249 is where that is decided.

Also for #249, unasked and worth its own line: round 2's frozen subject
flipped `connected` to `disconnected` while healthy. The worked example in
the graduation target treats a connected-to-disconnected flip beside a
frozen field as part of a death signature. On an IDLE row that pair is now
measured on a session that had finished its work.

## Verification

Second context: `.claude/agents/verifier.md` at opus, spawned on this
branch's diff.

**What it cannot check, stated before what it can.** That agent declares
`tools: Read, Grep, Glob, Bash` — no control-plane call — so it cannot
re-sample any subject and no reading here is independently confirmed by it.
This is issue #267, filed from round 1 for exactly this, and the honest
position is the one #267's option 1 asks for: a control-plane claim in this
repo is verified for arithmetic and internal consistency and not for
whether the numbers are real. What makes round 2 better than round 1 is not
a stronger second context — it is that the three pages are saved and the ids
are recorded, so a reader WITH the fleet can re-sample, and a reader without
it can recompute every number from the pages.

Round 2 claims, graded:

- **A `list_sessions` read does not write the field** — GROUNDED. One
  distinct value per subject across three reads, and stale at the first.
- **The field is not a connection heartbeat** — GROUNDED. The connection
  changed and the field did not, on the same row.
- **An IDLE row's field goes arbitrarily stale while healthy** — GROUNDED
  for "arbitrarily stale" (54m54s) and for one subject's health, which rests
  on that subject's OWN summary naming a merged pull request. A session's
  account of itself may never decide liveness — the graduation target's own
  rule — so read this as: staleness did not coincide with trouble in the one
  case where the record says what the session had done.
- **A RUNNING row's cadence spread is 8.4s to ~6 minutes** — GROUNDED.
  Twelve lags from three saved pages, recomputed.
- **The field advances inside one turn** — WEAK, unchanged from round 1 and
  for the same premise reason.
- **Movement means connected rather than progressing** — REFUTED, where
  round 1 left it UNGROUNDED.

## Graduates to

`.claude/commands/orchestrate.md`, the evidence table in step 2, and the
sentence eighty lines below it that calls this unmeasured. The why-explanation
goes to `.agents/docs/orchestrated.md` beside the health numbers, because a
table row that says "not at any interval" without the cadence spread behind
it is a rule the next session will try to tune.
