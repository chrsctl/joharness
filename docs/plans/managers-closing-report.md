---
plan: managers-closing-report
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .claude/commands/orchestrate.md, .claude/commands/manage.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

Issue #258's first option. A manager finishes an item having read a plan,
driven a verifier, argued with a reviewer and merged a diff, and what it
hands back is the literal string `merged <stem>`. That message is honest
about its purpose — `manage.md` says it exists so the slot frees at once
instead of on the orchestrator's clock — but it is the only channel a
successful manager has, and `orchestrate.md`'s merged row spends it
accordingly: done, nothing further, unless `upstream` is on, which it is off
by default. The one manager whose substantive findings reached a human in
the measured run was the one that got STUCK: its report came through as a
side effect of `status_detail` being read for liveness, and it named three
auth bugs in OTHER queue items — cross-item intelligence no artifact on its
own branch would ever carry. Failure delivers a report; success discards
one.

## Scope

- `.claude/commands/manage.md` — at § 4 Finish, widen what the merge message
  carries. Not a free-text report: a short, bounded, stripped form the
  orchestrator can copy into its ledger, because anything the ledger does
  not carry is gone at the next compaction and that is the cost the issue
  names against this option. The fields worth naming are the ones the branch
  itself cannot hold: what it learned about items it does NOT own, and what
  the next manager on an adjacent item should know. What it found in its own
  files is already in the diff and in `## Review`; asking for it again buys
  a longer message and no information.

- `.claude/commands/orchestrate.md` — two places. § 3's spawn prompt, which
  is where the merge line is dictated to the manager, so the manager is
  asked for the wider form at spawn rather than discovering the expectation
  at merge. And § 4's ledger grammar, which must gain a field for it with
  the same stripping and the same 40-character discipline the existing
  fields carry — the grammar already explains why: a `next:` line reading
  `done respawns=9` would otherwise forge a respawn count, and this field is
  free text from a session, which is the same class of input.

- `.agents/harness/selftest/orchestrated.sh` — the topic that already
  asserts what the role files say about themselves.

## Out of scope

- Any new tool, channel or message type. This is prose in two command files
  plus a ledger field; the message already exists and already arrives.
- Making the orchestrator ACT on what it receives — respawn, reprioritise,
  or rewrite another item's plan from one manager's report. A manager's
  account of an item it does not own is a lead, not a finding, and an
  orchestrator that re-plans on it is deciding the queue from hearsay.
- Option 2 of the issue, which is `docs/plans/promote-before-retire.md`.
- Option 3, pointing `upstream` at the consumer. It is the largest change
  and it turns on where a consumer's own product findings should go, which
  nobody has decided. Named here so it is not absorbed quietly.
- `JOHARNESS_UPSTREAM_FEEDBACK` and everything `./joharness.sh upstream`
  does. That machinery works and is a different destination.

## Acceptance

- `./joharness.sh ci` — `ci: pass`. The caveman and glossary stages both
  read these files, so the prose bar is a gate here, not a style note.
- The ledger grammar in `orchestrate.md` § 4 and the field `manage.md` § 4
  asks the manager to send are the SAME field, spelled identically.
  Asserted mechanically in the topic file, not by reading: two files
  drifting on one grammar is how a manager sends something the orchestrator
  cannot parse, and the manager is the party that cannot see the mismatch.
- The stripping rule is stated on the new field, in the same terms as the
  existing ones. Asserted.
- The spawn prompt in § 3 names the wider form, and the merged row in § 2
  no longer reads as "nothing" when the message carries content. Both
  asserted against the file's own text.
- A worked example of the new message, short enough to fit the bound,
  written out in `manage.md` — a literal reader given a field name and a
  character limit and no example will send a summary of its own diff.
- No mechanical claim about what the message improves. Nothing here is
  measurable from this repository: the evidence is one orchestrated run, and
  the plan says so rather than writing a number it cannot count.
- SHIPS: `.claude/commands/` reaches every consumer, so this changes what
  every orchestrator and every manager does at merge. Name the consumer-side
  check: in a consumer, a manager's merge message carries the field and the
  orchestrator's next wake message carries it forward.

## Where to look

- `.claude/commands/manage.md`, § 4 Finish — the merge line, and the
  sentence saying what it is for.
- `.claude/commands/orchestrate.md`, § 2 merged row — what a successful
  manager's message currently buys, which is nothing.
- `.claude/commands/orchestrate.md`, § 3 Spawn, the prompt paragraph — the
  list ending "Nothing else", which is what a new ask has to join rather
  than sit beside.
- `.claude/commands/orchestrate.md`, § 4 — the ledger grammar, the
  stripping rule and the reason it exists.
- `.agents/harness/selftest/orchestrated.sh` — the existing assertions over
  the role files' own text.

## Traps

- The ledger is the orchestrator's whole state and it is rewritten every
  pass. A field with no bound is a field that eats the ledger, and a ledger
  that does not fit is one a compaction truncates silently.
- Text a manager wrote is repo-controlled input, same as a `next:` line.
  Strip quotes, newlines, semicolons and `=`, cut to the same length, and
  never take a digit from it for a count the orchestrator keeps.
- The spawn prompt routes; the repository authorises. A new ask that
  smuggles instructions into the prompt beyond routing breaks the rule that
  paragraph exists to state.
- opus, not sonnet: the failure this can produce is a plausible-looking
  protocol change that quietly widens what an unattended fleet does with
  free text. Wrong-but-plausible is the opus condition
  (`.agents/docs/agent-selection.md`).
