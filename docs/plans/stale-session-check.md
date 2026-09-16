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

`ci` is necessary and proves nothing here: it reads no health-table row and
is green with every row deleted. So each bullet below names what to read.

- `./joharness.sh ci` — `ci: pass`.
- Every field the new rules WRITE appears in step 4's ledger grammar: the
  `ledger:` line in step 4 contains both `conn=<connected|disconnected>` and
  `dup=<branch>`. Grep the grammar line, not the file — each string also
  appears in the rule that writes it, so a whole-file count answers a
  different question. A rule keyed on a ledger field
  nothing writes is dead text after one compaction — this file has paid for
  that once already (`feedback`, PR234 r3).
- The triple never shortens the two-pass rule: the signature paragraph
  contains `two\n  PASSES` or `two PASSES`, and no wording that offers a
  verdict sooner.
- No rule decides liveness on one field. Read the LOOP row: it names
  `updated_at` AND head. Read the signature: it names three fields and says
  it corroborates.
- Every new rule prescribes an action for BOTH branches of its own test.
  The LOOP row says where a not-alive session falls; the duplicate rule says
  report once and what not to do.
- Each cited reading carries its date and its owner, issue #249, so a reader
  can check a number this checkout cannot recount.
- The mirror agrees: in `.agents/docs/orchestrated.md`, the table row whose
  first cell is `looping` no longer reads `any` in its control-plane column.
  Other rows there use `any` correctly, so read that row rather than counting
  the file.
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
