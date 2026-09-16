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

- `.claude/commands/orchestrate.md`, two additions, both independent of any
  unmeasured fact:
  1. **The `session:` URL names a writer, not a worker.** It is whatever the
     last writer of the workstream file put there, so after a respawn a
     branch being driven can advertise its dead predecessor. A caution, not
     a decision rule: it tells a reader which source wins, and needs no new
     field and no enumeration of sessions.
  2. **The worked reading of a dead manager wearing the LOOP row's shape**,
     with its four timestamps, so the misdiagnosis that cost one run is
     checkable rather than retold. It ends by saying what is NOT settled.

- `docs/research/liveness-in-a-long-turn.md`, the question those two leave
  open and the four withdrawn rules depended on.

## Out of scope, and why four rules were withdrawn

A death signature keyed on `connection_status`, a duplicate-by-branch check,
a LOOP precondition, and the ledger fields they needed were drafted, reviewed
three times and withdrawn. Two verifier passes at opus found 15 and then 13
defects; the second round's fixes introduced four more, which is the review
churn `.agents/docs/agent-selection.md` names — and the conflicting
requirement it says to look for turned out to be a fact nobody has measured:
whether `updated_at` advances inside one long turn. One withdrawn rule
assumed it does, another assumed it does not, in the same diff. Patching
could not converge because the answer is not in the repository. The research
file carries the question; these rules are its consequence, not this plan's.

Also out of scope, as before: the scheduler that issue #249 calls its whole
question, and whether the respawn path should attempt an archive first.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- Neither addition reads or writes a ledger field, so neither can be dead
  text after a compaction: `git diff origin/main...HEAD -- .claude/commands`
  touches no `ledger:` line.
- Neither addition is a decision rule. The caution says which source wins;
  the worked reading ends by naming what is unsettled. Read both: no row of
  the health table changes, and `git diff` shows no table row edited.
- Each cited reading carries its date AND its owner, issue #249. Read every
  added line carrying a timestamp.
- The research file has all nine sections `.agents/docs/research/README.md`
  names, and its `graduates:` points at the file a verdict would change.
- SHIPS: `.claude/commands/` reaches every consumer. The addition cites no
  path under `docs/`, which does not ship — the rule PR #246 graduated.


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
