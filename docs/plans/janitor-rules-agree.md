---
plan: janitor-rules-agree
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:.claude/commands/janitor.md, shared:.claude/commands/orchestrate.md
---

## Goal

Three issues, one file. `.claude/commands/janitor.md` contradicts itself
twice and has one release rule that fired on a live session.
#293: §5 orders a verifier spawn and `## Never` forbids "spawn anything".
Three sweeps each spent a reasoning round deciding which line wins.
#291: the §5 report line says "only the second of its four cases" is a
queue claim. `cmd_janitor` prints five `holds:` cases, and the queue
claim is the one saying "out of the queue while this claim stands". The
second case is "no plan", its opposite. #284: step 2's FAILED row released
a session that had hit a weekly rate limit. Rate-limited and dead read the
same on every field the row reads. Only `status_detail` differs: it names
the limit.

## Scope

- `.claude/commands/janitor.md`, `## Never`: replace the line
  `- Run a second pass, or spawn anything.` with
  `- Run a second candidate pass, or spawn anything but the step 5 reader.`
- `.claude/commands/janitor.md`, §5 Finish, the Report paragraph: replace
  `and only the second of its four cases is one;` with words that name no
  number, e.g. `and only the case that says "out of the queue while this
  claim stands" is one — copy whichever line the sweep printed;`. Keep the
  rest of the sentence.
- `.claude/commands/orchestrate.md`, step 2 field table, the
  `status_bucket` row. `janitor.md` says the field rules are "stated once,
  there", so the rule goes there and only there. Add: a FAILED bucket whose
  `status_detail` names a usage limit, a rate limit or a quota is
  **throttled, not dead** — it may clear itself. No row may archive,
  release or respawn on it. Report it with the detail text. The asymmetry,
  one sentence: text written by the session (`status_detail`) may WITHHOLD
  a death verdict, never justify one. Same direction as the
  `post_turn_summary.status_category` row's "May never decide liveness on
  its own".
- `.claude/commands/janitor.md`, step 2 table, the FAILED row: add the
  pointer, not the rule — `unless the bucket reads throttled (field table,
  orchestrate.md step 2): then leave it and report it`.
- Same section, one sentence naming the mitigation that already exists: a
  release is undoable because a returning session may set the status back
  (step 3 already writes that sentence into the note). This is why the
  hedge withholds and does not add a waiting period.

## Out of scope

- A later second read, or any interval on it (#284 shape 2). The comment on
  #284 measured it: an 18-day wait would have been needed. No number exists
  to write.
- `.claude/commands/orchestrate.md` beyond the one field-table sentence.
  Its health-table FAILED rows read the field table and need no edit.
- `joharness.sh` and its janitor output text. The janitor output's
  candidate footer says "a FAILED bucket confirmed twice = gone". Leave it.
  `janitor-zero-candidate-says-why` owns that function this round.
- Any selftest. Nothing here is code. `release-reds-the-branch-it-releases`
  owns `.agents/harness/selftest/janitor.sh`.

## Acceptance

- `grep -c "spawn anything but the step 5 reader" .claude/commands/janitor.md` → `1`
- `grep -c "four cases\|second of its" .claude/commands/janitor.md` → `0`
- `grep -n "out of the queue while this claim stands" .claude/commands/janitor.md` → at least one hit, in §5.
- `grep -n -i "rate limit\|quota\|usage limit" .claude/commands/orchestrate.md` → hits in the step 2 field table.
- `grep -n -i "throttled" .claude/commands/janitor.md` → a hit in the step 2 FAILED row.
- `grep -c "out of the queue while this claim stands" joharness.sh` → at least `1`. Proves the quoted phrase is still the code's.
- `./joharness.sh ci` → `ci: pass`.
- SHIPS: `.claude/commands/` syncs to consumers. The consumer check is the
  same `grep` lines, run in a consumer after its next sync.

## Where to look

- `.claude/commands/janitor.md:## Never` — the contradicting line.
- `.claude/commands/janitor.md:## 5. Finish` — the Report paragraph.
- `.claude/commands/janitor.md:## 2. Prove it gone — the step that must not be guessed` — the FAILED row.
- `joharness.sh:cmd_janitor` — the five `holds:` printf lines. Read them, do not edit them.
- `.claude/commands/orchestrate.md:## 2. Health pass — before any spawn` — the field table's `post_turn_summary.status_category` row.

## Traps

- `release-reds-the-branch-it-releases` also edits `.claude/commands/janitor.md`
  (step 3). Both plans mark it `shared:`. Expect a reconcile at step 7, and
  keep both edits.
- Glossary: `ci` lints `.claude/commands/*` for banned spellings. Run `ci`
  after each edit, not only at the end.
- `role-files-say-it-first`, `ledger-losses-named` and the dispatch plans
  also edit `orchestrate.md`. All `shared:`. Reconcile at step 7.
- Protocol text is not a core path (`./joharness.sh protocol-paths`). This
  plan is free work, and it touches no core path.
