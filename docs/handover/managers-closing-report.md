---
workstream: managers-closing-report
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: managers-closing-report
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Review the diff, then retire the plan and the workstream file and open the pull request
---

## Goal

`docs/plans/managers-closing-report.md`, issue #258's first option. A manager
finishes an item having read a plan, driven a verifier, argued with a
reviewer and merged a diff, and hands back the literal string `merged
<stem>`. That is honest about its purpose — freeing the slot at once rather
than on the orchestrator's clock — but it is the only channel a successful
manager has, and the merged row spends it on nothing. The one manager whose
findings reached a human in the measured run was the one that got STUCK: its
report arrived as a side effect of `status_detail` being read for liveness,
and it named bugs in OTHER queue items. Failure delivers a report; success
discards one.

## Decisions

- The lead is keyed to the item it is ABOUT, not the one that reported it,
  and rides its OWN `leads:` ledger line. This is the design's whole hinge:
  a merged item leaves the ledger — dispatch stops listing it, the entry is
  dropped — so a field written into that entry dies with the manager that
  sent it, which is the exact failure being closed. The plan said "§ 4's
  ledger grammar must gain a field"; a field on the per-item line would have
  satisfied the letter and none of the purpose.
- ONE spelling, `lead <stem>: <text>`, in both command files. The manager is
  the party that cannot see a mismatch — it sends what `manage.md` asks for
  into a grammar `orchestrate.md` defines — so the sameness is asserted
  mechanically rather than by reading, and a near-miss spelling reds it.
- Relay, never act. Not into a spawn prompt, not into a plan, not into a
  respawn. The plan's Out of scope forbids acting; feeding a lead into a
  spawn prompt is the near-miss version of that, because the prompt
  paragraph's own rule is "the prompt routes; the repository authorises",
  and a lead is one session's reading of somebody else's files. The human
  decides what it is worth, which is why the pass report is where it lands.
- 40 characters, matching every other borrowed field. A lead is a POINTER,
  not a report: the detail is in the merged branch's history and recoverable,
  and an unbounded list is a ledger a compaction truncates without saying so.
  Bounded at five, one per stem, dropped when that stem merges.
- Taken at opus, which is the plan's own tier. Its Traps name why: the
  failure this can produce is a plausible-looking protocol change that
  quietly widens what an unattended fleet does with free text.

## Rejected

- `docs/plans/orchestrated-run.md`, which the queue ranks first. Its one
  remaining deliverable is the Runs row saying what stopped run 3, and run 3
  has not stopped. Re-counted 2026-09-17T02:16Z from the control plane: four
  managers `SESSION_STATUS_RUNNING` with `updated_at` inside the minute, two
  of them spawned at 02:03Z. Its other precondition, the heartbeat, is the
  human's by the plan's own words.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  `state: closed`, `merged: false`, closed 2026-08-21. Not edge work to
  finish; deleting the branch is the human's.

## Review

- r1: (session) the first draft of the worked example in `manage.md` used a
  consumer's real item names, taken from issue #258's own text. `.claude/`
  ships to every consumer, so that is the requester's standing rule and
  `.agents/docs/consumer-repos.md`, "Name no consumer", broken in the one
  place it costs most. Caught before the commit by the sweep this repo does
  for exactly that. (fixed — neutral placeholder stems; `git diff | grep`
  for the consumer's item-name shapes now returns nothing.)
- r2: (session) the first selftest block carried a `refute` whose haystack
  was a literal string I supplied, so it asserted nothing and would pass over
  any file content at all. Written while reaching for a negative assertion
  and the exact could-never-fail shape this repo has recorded three times.
  (fixed — replaced by two positive assertions against the file, and both red
  under mutation C.)
- r5: (session) the stripping rule covered the lead's TEXT and said nothing
  about its STEM, which is free text from the same session and sits one
  field to the left. A manager sending `lead a;b=c: x` writes a `;` and an
  `=` straight into the ledger line — the separators the whole rule exists
  to keep out, entering through the field nobody was watching. Found reading
  my own diff against the grammar it edits, before the verifier reported.
  (fixed — the stem is CHECKED, not copied: it must be an item this pass's
  dispatch output already names, and anything else drops the lead with a
  line in the report. Checking beats stripping here because the orchestrator
  already holds the whole queue from step 1, so there is a right answer to
  compare against rather than a character class to guess at.)
- r4: (session) a needle written with backticks inside single quotes tripped
  shellcheck SC2016, and `ci` fails on info level here — `ci: FAIL` with
  every stage below it green, which is the confusing shape. (fixed — a
  backtick-free needle from the same line.)
- r3: (session) an assertion spanned a line wrap in the prose it was
  reading, so it failed on the real file: these are `.md` files and needles
  that cross a newline break on a reflow that changed nothing. Found by
  running the suite, not by reading it — 2026-09-17. TWICE, on this branch:
  once on the never-act sentence and again on the stem-check one, and the
  second time after the first was fixed. The habit, not the needle, is the
  defect: a needle written from the sentence I had just typed, rather than
  from the wrapped line the file actually holds. (fixed both — single-line
  needles, read out of the file. The rule for the next one: `grep` the
  candidate needle against the file before committing it, because a needle
  that has never matched anything is indistinguishable from one that will.)

## Blockers

None.

## Where to look

- `.claude/commands/manage.md`, § 4 Finish — the merge line and what it is
  for.
- `.claude/commands/orchestrate.md` § 2 merged row, § 3 spawn prompt, § 4
  ledger grammar — the three places that have to agree.
- `.agents/harness/selftest/orchestrated.sh` — the existing assertions over
  the role files' own text.
