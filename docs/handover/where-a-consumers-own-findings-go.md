---
workstream: where-a-consumers-own-findings-go
status: in-progress
branch: claude/where-a-consumers-own-findings-go
pr: none
plan: where-a-consumers-own-findings-go
issue: none
session: https://claude.ai/code/session_0128i4WUdEgZ88ygzuHHtXEK
agent: opus
updated: 2026-10-08
next: Read the verifier subagent report, record its findings tagged (verifier) in ## Review, answer each, THEN retire this file + no plan to delete (the plan is the deliverable) and open the pull request
---

## Goal

Settle `docs/research/where-a-consumers-own-findings-go.md`: where a finding a
consumer discovered about its OWN product goes, given `upstream` refuses to
carry it to the canonical and `feedback` serves it only to a session touching
the same path. Graduate the answer into `.agents/docs/feedback.md` and delete
the research file.

## Decisions

- **Counted, not reasoned, and not on the canonical code path.** `cmd_upstream`
  returns early on `JOHARNESS_CANONICAL=1`, so the sweep ran with that one line
  stripped from a scratch conf (`JOHARNESS_CONF=<scratch>/consumer.conf`), over
  all 272 merged edges of `origin/main`. Every number below carries its command.
- **The answer is a PLACEMENT fix, not a destination.** #258's third direction
  asks for a place for the findings `upstream` calls `unplaceable`. Counted, the
  bucket holds zero consumer product findings: where a finding has a fix path on
  a consumer-owned file it is already served by `cmd_feedback` and the
  PreToolUse hook, and where it has no path it cannot be keyed by anything. So
  the graduation records that the destination exists and names the two
  misclassifications that make it look empty.
- **The two defects go in a plan, not this branch.** Both are in `joharness.sh`,
  which `./joharness.sh protocol-paths` names; this session is bound unattended
  and cannot commit there. Plan is SUPERVISED ONLY.

## Rejected

- **Building #258's destination.** It would serve a bucket whose placeable
  members already have a reader and whose unplaceable members have no key. The
  issue's own "largest change and the one that fits the existing design best"
  is, on this corpus, a destination for nothing.
- **Narrowing `upstream_text_paths` to kill the junk tokens.** 142 of the 151
  text-path findings resolve to nothing real (`origin/main` 20, a bare `/` 8,
  `precision/recall`, `before/after`). Tempting, and wrong: it would also drop
  the 44 that name a canonical-owned file. The predicate that decides OWNERSHIP
  is what is wrong, not the one that finds tokens.
- **Claiming 45 missed-owned findings.** My first count resolved a token by
  suffix, so `docs/handover/README.md` — a real path in every consumer —
  matched `.agents/docs/handover/README.md`. Recounted on bare basenames and an
  exact `./`-strip only: 44.

## Review

- r1: (session) my first missed-owned count was 45, resolved by a regex
  anchored `(^|/)<token>$` — a SUFFIX match, not a basename. It paired the token
  `docs/handover/README.md`, which is a genuine consumer-owned path in every
  repo running this harness, with `.agents/docs/handover/README.md`, and would
  have reported a consumer's own file as canonical's. Recounted with bare
  basenames (no slash) and an exact `./`-strip only: **44**, one fewer
  (`wc -l < missed-strict.txt`, 2026-10-08). The overclaim was in the direction
  that matters — it inflated the defect I was about to file.
- r2: (session) the plan shipped with no consumer-side acceptance check.
  `./joharness.sh ci` names it — `upstream-placement-defects: SHIPS to
  consumers — joharness.sh, shared:.agents/docs/feedback.md`, and the stage
  says a shipping plan's Acceptance must name the check a consumer runs
  (`ci.txt`, this tree, 2026-10-08; `ci: pass`, so advisory, not red). It
  bites harder here than the generic rule suggests: the one entrypoint the
  plan changes cannot be exercised in canonical at all, because
  `cmd_upstream` returns early on `JOHARNESS_CANONICAL=1`. A plan whose
  acceptance is all local would be green in the only repo where the changed
  code never runs. (fixed — Acceptance now requires the stripped-conf
  fixture run and the 44 appearing under `harness findings`.)
- r3: (session) `origin/main` moved 9 commits mid-branch (PR #316), so the
  corpus the graduation cites was no longer the corpus the merge lands on.
  Re-ran the whole sweep after merging: 273 edges, 2005 findings,
  1356 / 119 / 530, and the 530 split unchanged at 379 pathless and 151
  text-path, 44 missed-owned, 9 real, 0 durable consumer product file. Only
  the two totals and the kept count moved. Figures updated and the section now
  says the totals climb with the corpus while the third row is what the answer
  rests on. (fixed — and the catch was the step 4 periodic re-fetch, not luck.)
- r4: (session) "another repo's `README.md`" undersold the 9. Two of them are
  `README.md` and only one of those is another repository's (gastown); the
  other is a queue-directory README, and one more is `docs/product/`, a
  directory my prose did not list. Reworded to what the 9 actually are. The
  load-bearing word is `durable`, and it survives: none of the 9 is a
  consumer-owned product file.

## Blockers

None. In flight at this push, neither blocking: `./joharness.sh ci` re-running
after the base-branch merge (it passed before it, and the merge brought no
non-`*.md` file), and the opus verifier subagent, whose findings step 5 needs
before the retire commit. `verify` already green (6 passed, 0 failed) though
this diff is `*.md` only and step 7 does not require it.

## Where to look

- `docs/research/where-a-consumers-own-findings-go.md` — the question, its
  `What would settle it`, and its `Method` clause saying this repo cannot
  answer it from its own checkout (`JOHARNESS_CANONICAL=1`).
- `joharness.sh:cmd_upstream` — the three-way split whose boundaries the
  question says are not where a reader expects.
- `joharness.sh:cmd_feedback` — the reader that already serves path-keyed
  findings out of merged history.
- `.agents/docs/feedback.md` — graduation target.
