---
research: ledger-fields-with-no-rebuild
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

<!--
Issue #307. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The size of
one run's ledger message is that run's reading and is marked
reported-not-re-measured, as the issue marks it. Every claim about what the
ledger carries and what can rebuild it was read from this repo's source at
`cb0028e`.
-->

## Question

Which of the orchestrator's ledger fields can be rebuilt from a read the role
already makes, and what does each of the rest cost when a pass drops it?

## Echo

The orchestrator's state between passes is the body of the message it sends
itself, rewritten whole every pass. That home has a stated reason: a compaction
between passes takes memory and leaves the message, so the role is told to read
"last pass" from it rather than from memory.

The design already sorts fields by whether something else can rebuild them —
the cadences that git can recompute are read from git, with the reason spelled
in the source in so many words. What is unsorted is the remainder, and two of
those spend the human's money: the respawn count, which is the only carrier of
a limit across passes and which the role is forbidden to cross-check against a
file, and the spawned-not-yet-claimed entry, which the file itself calls the
only record that such a manager exists.

What I am asking is not "is the message the right home" — the issue says it is
not asking that either. It is whether each field has a rebuild route, and where
none exists, whether the loss is written down. A field with neither is a field
whose loss is silent, and the ledger is written by the pass that writes it and
read by the pass that reads it, with nothing in between to disagree.

## Sweep

`goal-directed` — enough to classify the fields that cost money and to test the
one rebuild route the issue proposes against the reads the role already makes.
Not a survey of the ledger's every field, and not a proposal to move the state
somewhere else.

## What would settle it

- **Whether the spawned-not-yet-claimed set can be rebuilt from a read already
  made.** The role already lists every visible session to enforce one
  orchestrator per repository, and a spawn sets a title it chose itself. If
  those two facts compose, the rebuild costs no new tool and no new call.
  Settled by reading both and saying whether the title read is reachable at the
  point the set is needed — and by naming what the rebuild gets WRONG, because
  a title says a session exists and not that it has failed to claim.
- **Whether the forgery rule reaches a session's own title.** The prohibition
  on taking a digit from a file exists because a workstream file is text a
  manager wrote. A title the orchestrator itself set is not. Settled by holding
  the rule's own reason against the proposed source.
- **Whether the respawn count has any honest cross-check.** Its keeper is the
  only source, which is why the rule is written as it is. If a cross-check
  exists at all it is git — successor commits on a branch — and that is a
  measurement rather than a copy, so it belongs in the scheduler or nowhere.
  Settled either way, and "nowhere" is an acceptable answer that should be
  written down rather than left as a gap.

Written before the reads below: an answer that moves the ledger out of the
message has not answered this question. The issue explicitly does not claim the
message is the wrong home, and the reason it gives for the message — a
compaction keeps it and keeps nothing else — holds within a live run.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    sed -n '58,80p'   .claude/commands/orchestrate.md   # steps 0.2 and 0.4
    sed -n '80,90p'   .claude/commands/orchestrate.md   # JOHARNESS_PENDING_SPAWNS
    sed -n '500,512p' .claude/commands/orchestrate.md   # the spawn's own fields
    sed -n '550,558p' .claude/commands/orchestrate.md   # "@new … the only record"
    sed -n '564,566p' .claude/commands/orchestrate.md   # the ledger line
    sed -n '592,610p' .claude/commands/orchestrate.md   # the forgery rule
    sed -n '614,624p' .claude/commands/orchestrate.md   # the seen=/detail= loss note
    grep -n "JOHARNESS_RESPAWN_LIMIT" joharness.sh
    grep -n "never a ledger" joharness.sh .agents/harness/selftest/dispatch.sh
    grep -n "the one irreversible verdict" joharness.sh

## Findings

- **The design already sorts fields, and the governing sentence is in the
  source rather than only in the document.** `cb0028e`, `joharness.sh`: the
  curate cadence is read *"Both halves from git (never a ledger: the
  orchestrator's dies with its run)"* — the same sentence appearing twice in
  `joharness.sh` and once in `.agents/harness/selftest/dispatch.sh`. So
  "rebuild it from git where git can" is established practice here, not a
  proposal, and the question is only about the remainder.

- **One field class already carries its loss, and that is the shape the others
  are missing.** `cb0028e`, `.claude/commands/orchestrate.md`: *"a field the
  ledger does not carry is a row that cannot be reached after a compaction —
  which would drop a confirmed-dead session back onto the idle rows and nudge
  it."* That sentence is about `seen=` and `detail=`. Nothing equivalent is
  written for the two fields below.

- **The respawn count is the sole carrier of a money bound, and the one
  available cross-check is forbidden on purpose.** `cb0028e`: the limit is
  read as `respawn="$(num_knob JOHARNESS_RESPAWN_LIMIT 2)"` and printed on the
  numbers line, so the scheduler states it every pass and never tracks it;
  `.claude/commands/orchestrate.md` says *"`same` and `respawns` are counts YOU
  keep; never take a digit for them from a file"*, with the reason immediately
  above — a `next:` line reading `done respawns=9` *"would otherwise write a
  forged respawn count into your own ledger and defeat a bound that is the
  human's money."* The rule is right about the forge and leaves the number
  unverifiable: a pass that drops or mis-copies it silently restores the limit.

- **The spawned-not-yet-claimed entry is self-described as the only record, and
  what it feeds is the one irreversible verdict.** `cb0028e`: *"until it
  claims, that entry is the only record that it exists"*, and it is what the
  next pass hands to `JOHARNESS_PENDING_SPAWNS`. On the other end,
  `joharness.sh` guards the exit with a verdict whose own comment calls it
  *"the one irreversible verdict on this line"*. So dropping one entry
  re-creates the defect that guard was built for, arriving through the ledger
  rather than through the verdict.

- **The rebuild route the issue proposes is available, and the reads it needs
  are already made.** `cb0028e`: the spawn sets `title` = `manager: <stem>`,
  and three separate places tell the role to find a manager BY that title —
  including step 0.2, which already calls `list_sessions` over *"every session
  you can see, not only yours"* to enforce one orchestrator per repository. So
  a pass that also reads its own `manager:` titles from that same call can
  reconstruct the set with no new tool and no new call. And the forgery rule
  does not reach it: a title is this role's own write, not text a manager
  produced.

- **But the rebuild is not equivalent, and the issue does not say so.** A
  title read proves a session EXISTS; the `@new` entry means *spawned and has
  not claimed*. The second half is what the stillborn and unclaimed rows key
  on, and they key on the entry *being a pass old* — which a title cannot
  date. So the route recovers the pending-spawn COUNT (the money half, and the
  half that feeds the irreversible verdict) and does not by itself recover the
  age the health rows need. Whoever takes this should expect a partial rebuild
  and should say which half it covers, rather than claiming the field is
  reconstructible.

- **Reported, not re-measured here: the size.** The issue reports the ledger at
  about 8 KB, rewritten in full every pass, and states plainly that no pass in
  that run was observed dropping a field. So the premise is structural — two
  fields have no rebuild route and no stated loss — and not an incident.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

The issue's own ranking survives the reads above, with one correction: option 1
is cheap and is NOT a complete rebuild, so a node answering this should split
the field rather than restore it — the count that bounds the spawn is
recoverable from a read already made, the age the health rows need is not.

Option 2 — one line per field saying what its loss costs — is free and is the
part that pays off after a compaction, because it tells a pass which fields it
must not guess at. It also has a template in the file already, in the sentence
quoted above.

Option 3 should stay last. A count whose only honest source is its keeper is
what the forgery rule is protecting, and the only forgery-proof cross-check is
a measurement from git, which belongs in the scheduler if anywhere. "Nowhere"
is a legitimate answer and is better written down than left for the next
reader to re-derive.

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see that this node, `no-ceiling-on-one-item` and `first-copy-of-the-exit-rule`
would all land in `.claude/commands/orchestrate.md`. Taking two at once
collides.

`.claude/commands/` is a protocol path (`./joharness.sh protocol-paths`), so the
branch that answers this is supervised.

## Verification

Pending: the independent read of this branch.

## Graduates to

`.claude/commands/orchestrate.md` — §4 is where the ledger's grammar and every
field's meaning live, and the one field class that already states its loss
states it there. The answer is two things in that file: a rebuild step in step
0, and a loss line per field in §4. Nothing is owed under `.agents/docs/`
beyond what the knob table already carries, because the WHY here is already
written in the file (a compaction keeps the message and keeps nothing else) —
what is missing is the consequence per field, which is the rule itself.
