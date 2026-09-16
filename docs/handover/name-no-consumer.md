---
workstream: name-no-consumer
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Reword the fifteen mentions, add the rule to consumer-repos.md, review, retire, open the pull request
---

## Goal

Requester's rule, 2026-09-16: internal development and review stay separate
from the harness. Fifteen places name a specific consumer repository, and
most of the files carrying them ship to every consumer, so one operator's
internal work travels into all of them. `#250` cleared the three files it
was already editing; this clears the rest and writes the rule down so it
does not recur.

## Decisions

- No plan file. The work is a rename sweep with a self-describing diff and
  no design content, the same carve-out the protocol gives copy and sync
  tasks (`.agents/docs/handover/README.md`, "When NOT to write one"). The
  rule it lands is one paragraph, not a feature.
- Identity out, measurement in. Every citation keeps its command, its
  commit, its counts and its date; only the repository name goes. A number
  stops being re-countable by a stranger either way — they never had that
  repo — and stays re-countable by whoever does.
- The rule goes in `.agents/docs/consumer-repos.md`, which owns the
  canonical-to-consumer boundary and already carries the neighbouring rule
  about not pointing at a conf comment a consumer may not have.
- No `ci` gate proposed here. A check listing consumer names would be the
  leak it prevents, and a looser `owner/repo` pattern check is a design
  question for the human, recorded in the rule's own text as the open
  option rather than built on this branch.

## Rejected

- Rewriting history to remove the name from merged commits. Out of scope, it
  is not what was asked, and a force-push over shared history is forbidden
  by the branch-flow rules whatever the motive.

## Review

- r7: (verifier, noise) it reported the working tree dirty and the `## Review` section empty at the commit it read. Both were this session committing r1 to r3 while it reviewed; nothing was lost and every finding it raised against that commit is above. Recorded so the sequence is legible, not as a defect.
- r1: (session) the first sweep searched for ONE repository's name and called the tree clean. Widening it to any `owner/repo`, any session identifier and item-name shapes found three more classes: two OTHER consumer repositories named in shipping docs, and consumer item names — eight of them listed in one Runs entry, two more in the orchestrate command's worked examples, one in the run 3 entry this session itself wrote last hour. Item names are the worse leak: `permission-system-at-ten-thousand-seats` and `drive-slides-editor` describe somebody's roadmap, not just where a number came from. (fixed — all scrubbed; the rule's text already said plan and item names count, which is how the gap was visible at all)
- r6: (verifier) the rule's "not gated, on purpose" reasoning was false. It said a check listing the names to ban would be the leak it prevents — but such a list belongs in `.agents/harness/selftest/`, which is canonical-only and reaches no consumer, as this branch's own edits to two files in that tree demonstrate. (fixed — the reason is now the true one: enumerating an operator's repositories is their decision, not a session's, and the looser unmeasured shape is named beside it. Flagged to the requester as a decision rather than built.)
- r5: (verifier) the rule claimed `.agents/harness/` ships, full stop. Its `selftest/` tree and `selftest.sh` are canonical-only (`sync-to-consumer.sh`), so the sentence overstated the exposure of two files this branch itself edited. (fixed — the carve-out is named, and the rule is extended to the canonical-only files anyway, because a rule with an exception is one nobody remembers correctly)
- r4: (verifier) the rewrite in `handover-context.sh` deleted the colon along with the name, leaving "Measured in a consumer repo 17 files at one session's start" — it reads as the repo's 17 files rather than as a count. (fixed)
- r3: (session) the rule's own text said "fifteen mentions across eight files", true of the first pass and stale the moment r1 widened it — a written number in the paragraph that exists to stop written numbers. (fixed — re-counted, 27 lines across 12 files, with the command that counts them)
- r2: (session) the run 1 entry's eight item names carried pull request numbers and commit SHAs with them. Those stay: opaque to anyone without the repo, and they are the evidence the counted number rests on. Identity is the name, not the hash. (no change — recorded so the next reader does not strip them as a second pass)

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` `DIRS`/`FILES` — which of the eight
  files reach a consumer and which stay canonical-only.
