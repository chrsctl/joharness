---
plan: stale-session-check
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .claude/commands/orchestrate.md
---

## Goal

Same-session plan for issue #249's first cut. The health pass already decides
liveness well, and one orchestrated run produced four readings it gets wrong
or cannot express. Encode those four. The scheduler the issue calls its whole
question is explicitly not here.

## Scope

- `.claude/commands/orchestrate.md` section 2, four additions:
  1. **`connection_status` as corroboration.** The death signature measured
     three times, never on a healthy session: `updated_at` frozen across two
     reads AND head static across the same two AND `connection_status`
     moving `connected` to `disconnected`. Corroboration only — it joins the
     pair, it never decides alone, on the same terms the disqualified fields
     paragraph already sets.
  2. **The `session:` line is not evidence of who works a branch.** It is
     whatever the last writer of the workstream file put there, so a respawn
     leaves a window where a branch being actively driven advertises a dead
     session. Resolve the worker from the control plane's own records.
  3. **A duplicate check, grouped by branch.** Any branch named by more than
     one non-archived session is two sessions on one branch. It fails safe:
     a false positive costs a `/who`, and the hook's own note says a missing
     claim is the expensive direction.
  4. **A dead manager can look exactly like a looping one.** A `next:` that
     never moves while the head appears to move is the LOOP row's shape and
     was, measured, a session that had already died. The two rows call for
     opposite actions, so the LOOP row requires a live reading first.

## Out of scope

- The scheduler. How a check runs without sharing the fleet's fate is the
  issue's open question, it is an operator action with money attached, and
  an agent session answering it inherits the failure.
- Whether the IDLE-gone row should attempt an archive before respawning.
  The issue raises it separately; the attempt can be refused by the
  permission classifier, and the procedure has no branch for that outcome.
  Naming it is this plan's business, answering it is not.
- Any change to `dispatch`, the hooks, or `joharness.sh`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `grep -c 'connection_status' .claude/commands/orchestrate.md` — at least 1.
- Each of the four rules states the reading that produced it and the date,
  per Loop step 5: a measured number carries what produced it.
- No rule lets one field decide liveness alone; each names the pair or
  triple it belongs to.
- SHIPS: `.claude/commands/` reaches every consumer, so an orchestrator in
  any repo reads these rows, not only the one that measured them.

## Where to look

- `.claude/commands/orchestrate.md:83` — section 2 opens with the
  `session:` URL read that rule 2 corrects.
- The disqualified-fields paragraph — the precedent for how a field earns
  or loses standing, and the shape rule 1 must match.

## Traps

- One counter-example disqualifies a field. Three confirmations do not
  promote one to deciding alone — say corroboration and mean it.
- Protocol path: supervised only. A session under unsupervised may not
  commit this file.
