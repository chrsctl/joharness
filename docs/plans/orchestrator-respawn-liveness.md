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

## Scope

- Define gone: **ARCHIVED, or not found on the control plane.** Never IDLE,
  never PENDING, never a `status_category`.
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
