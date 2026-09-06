---
plan: orchestrator-respawn-liveness
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: orchestrated-mode
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md
---

## Goal

The health table's respawn row reads IDLE as *session gone* and spends a
manager on ONE observation, with no nudge step. The kill row beside it
requires two signals, a nudge and a confirming pass. A session between turns
is therefore cheaper to replace than one that has genuinely stopped.

Found by the orchestrator of run 1 (`.agents/docs/orchestrated.md`, Runs) by
walking into it: consumer `chrsctl/gx`, 2026-09-06, one duplicate manager,
about 17 USD.

## The mechanism

`.claude/commands/orchestrate.md`, health pass table:

```
| not RUNNING | any | branch unmerged, status in-progress / review / done | session gone. RESPAWN on that branch, below. |
```

The control plane has at least RUNNING, IDLE, PENDING and ARCHIVED. **IDLE
means between turns.** A manager that arms its own check-in — which every
manager in run 1 did while waiting on a slow `crm` job — reads IDLE for the
whole interval. `not RUNNING` therefore selects working sessions.

Two smaller faults ride along:

- `status_category: completed` is a session's self-report about its TURN. Run
  1's manager reported `completed` while its pull request was open and its
  head was not an ancestor of `main`. Merge state is git's answer, and the
  table does not say so.
- The respawn row has no nudge, so there is no cheap probe between observing
  and spending. `SendMessage` costs nothing and would have settled it.

## The measurement

17:13Z, `crm-aggregate-reasoning`: `SESSION_STATUS_IDLE`, `status_category:
completed`, pull request #296 open, `crm` red on CRM444, head `8f7dd84e` not
an ancestor of `origin/main`. Read against the row above this is unambiguously
RESPAWN, and the orchestrator respawned it — correctly, by the text.

The session was not gone. It woke at 17:41Z and merged #296 itself as
`4a4f3cc0`. The duplicate spent ~17 USD re-running the same diagnosis before
it was interrupted and archived at 17:42Z.

The same orchestrator had refused this exact inference at 13:22Z on a
different manager, reasoning in its own ledger that "IDLE is not gone". The
text won the second time. A rule that needs the reader to override it is the
defect.

## The third state the table cannot see: a crashed session

Same run, 18:13:30Z, `crm-public-dataroom`. Its turn crashed. What each
reader said afterwards:

| reader | value | what it means |
| --- | --- | --- |
| `dispatch` | `in-progress  pushed 3m` | healthy. The git view cannot see a crash at all. |
| `session_status` | `SESSION_STATUS_IDLE` | **the field the table branches on said IDLE** |
| `status_bucket` | `SESSION_STATUS_BUCKET_FAILED` | dead. Named nowhere in `orchestrate.md`. |
| `post_turn_summary.status_category` | `failed` | dead, but this is the session's own self-report |
| `status_detail` | `[ede_diagnostic] result_type=user last_content_type=n/a stop_reason=tool_use` | a tool call that never resolved |

So the table's own dimension — RUNNING / not RUNNING — reads a crashed
session as *not RUNNING*, indistinguishable from one that is merely between
turns. It reaches RESPAWN today only through the defective row above, and
**fixing that row without this one makes a crash strictly worse**: a dead
session would get the nudge-then-confirm pair, and the nudge is spent on
something that cannot answer.

This is `.agents/harness/AGENTS.md`'s own prohibition, one layer up: *don't
guard against a closed set by enumerating it, and check which members your
enumeration can actually reach.* The table enumerates two states of one
field; the control plane has at least five across three, and the two that
matter most — ARCHIVED and FAILED — are in fields it never reads.

The orchestrator handled it correctly on 2026-09-06 only by going outside the
text: it read `status_bucket`, took a second look 3 minutes later, saw the
record frozen at 18:13:30 with the head unchanged, archived and respawned at
18:28Z. Nothing was lost — three commits and the workstream file were already
pushed — but that recovery is not in any rule.

## Scope

- Define gone: **ARCHIVED, not found on the control plane, or a FAILED
  control-plane state confirmed by a second look.** Never IDLE alone, never
  PENDING.
- **Distinguish the two "failed" signals, because one is authority and one is
  not.** `status_bucket` (and `session_status`) are the control plane's own
  account of the session and may decide liveness. `post_turn_summary.
  status_category` is the session's self-report about its TURN — the same
  field that said `completed` over an unmerged head at 17:13Z — and may never
  decide liveness on its own. An earlier draft of this plan said "never a
  `status_category`", which would have forbidden the signal that caught the
  crash; the distinction is the field's *source*, not its name.
- Name the fields to read. A table that says "not RUNNING" without saying
  which field carries RUNNING invites reading exactly one.
- Add a FAILED row: **no nudge** — nothing is listening, and the nudge exists
  to ask a working session for a push. Confirm instead: a second look showing
  the session record's `updated_at` AND the branch head both unchanged. Then
  archive and respawn. No `interrupt_session` first; there is nothing to stop.
- Give the respawn path the nudge-then-confirm pair the kill path has: one
  `SendMessage`, ledger it, and only respawn if the next pass shows head AND
  `status_detail` both unchanged.
- State in the table that merge state comes from git (`git merge-base
  --is-ancestor`), never from a session's summary — and that `completed` over
  an unmerged head is the case that MOST needs the nudge, not one that skips
  it.
- Carry the same three lines into `.agents/docs/orchestrated.md`'s copy of the
  health table, or the two disagree and the next reader picks one (ADR 0110's
  shape: a second file carrying a defect the first already fixed).

## Out of scope

- The stall path. It is correct: two signals, nudge, confirming pass.
- Raising `JOHARNESS_RESPAWN_LIMIT`. The limit was never reached; the defect
  spends respawns on healthy sessions, and a larger budget spends more.
- Teaching the orchestrator to merge or to judge a manager's CI. Not its role.

## Acceptance

- The text names ARCHIVED / not-found as the only gone states, and no reading
  of the table lets IDLE alone reach RESPAWN. Checked by reading the table
  back as a literal reader would — the failure mode here is prose, so the
  check is a second reader who did not write it (`verifier`), not a script.
- A worked example in the table's vicinity carrying THIS run's shape: IDLE +
  `completed` + unmerged head → nudge, not respawn. The example is the part a
  hurrying session actually reads.
- **A second worked example, the crash**, because the two are one keystroke
  apart in the record and opposite in what they need: `session_status` IDLE +
  `status_bucket` FAILED + unmerged head → confirm once, then archive and
  respawn, no nudge. Both examples carry their field names, or a reader
  cannot tell which of the two rows in front of them applies.
- The FAILED path can fail as a check: hand a session the amended table plus
  run 1's 18:13:30Z reading and require *confirm-then-respawn, no nudge*. The
  text as it stands today answers *respawn immediately* (via the defective
  row), and the text with only the IDLE fix applied answers *nudge* — so the
  check discriminates all three versions, which is the point.
- `.agents/docs/orchestrated.md` and `.claude/commands/orchestrate.md` say the
  same thing about what gone means. Diff them; two copies is how this rots.
- **Consumer-side** (this plan SHIPS): in a consumer running orchestrated
  mode, take a manager that is IDLE with an unmerged branch and confirm the
  orchestrator's next pass sends a nudge and does NOT spawn, then that a
  second pass with head and `status_detail` both unchanged does respawn. The
  cheap version needs no fleet: hand a session the amended table plus run 1's
  17:13Z reading (IDLE, `completed`, `#296` open, head not an ancestor of
  `main`) and check it answers *nudge*, not *respawn* — the old text answers
  respawn, so the check can fail. Canonical has no fleet to run the full
  version on (`.agents/docs/plans/README.md`, SHIPS).

## Where to look

- `.claude/commands/orchestrate.md` — the health table, the KILL sequence
  below it (the pattern to copy), and the Tools table's two-signals sentence.
- `.agents/docs/orchestrated.md` — the second copy of the health table.
- `.agents/docs/unsupervised.md`, Heartbeat — the monitor rule that already
  says push time is not liveness in either direction.

## Traps

- Do not fix this by removing IDLE from the table's vocabulary and leaving the
  respawn row otherwise intact. The missing nudge is half the defect: any
  single-observation respawn spends a manager on a guess.
- The measurement is the contribution. Canonical has no consumers to run a
  fleet on (`.agents/docs/feedback.md`, When the consumer is the detector) —
  keep the 17 USD and the two timestamps in whatever text lands.
