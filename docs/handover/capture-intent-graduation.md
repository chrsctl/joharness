---
workstream: capture-intent-graduation
status: in-progress
branch: claude/drain-1vlaf8
pr: none
plan: capture-intent
issue: none
session: https://claude.ai/code/session_013x3au5nnN9kSRZMTSb3SpM
agent: opus
updated: 2026-09-06
next: Retire the workstream file, open the pull request, drive it green and merge
---

## Goal

Close the open question `docs/research/capture-intent.md`. Its fourteen
findings are recorded and verified from three outside contexts; nothing
carries them into a file the next session reads. Graduation writes the
answer to the file `graduates:` names — `.agents/docs/product/README.md`,
Requirements — and deletes the node.

## Decisions

- Took this item, not the queue's top plan. `docs/plans/orchestrated-run.md`
  gates on the human before any session may start it: the cap is money, the
  heartbeat needs a Routine only a human creates, and the plan's own text
  says the queue is not stocked. Reported to the human, not silently
  reordered.
- Diff carries only the graduation target, the node's deletion and this
  file. `.agents/docs/research/README.md`, "Not a plan": a research diff
  touching anything else is a plan with wrong frontmatter.
- The six adopt-candidates get no plan file. The node's own Consequence
  section leaves them to the human to queue; filing them here would invent
  work (`.agents/harness/AGENTS.md` step 2).
- Rejections land POINTING at the rules they protect, not restating them —
  the node's `## Graduates to` names both targets, and a second copy of a
  rule rots against the first.

## Rejected

- Nothing yet.

## Review

Opus depth: adversarial passes plus `.claude/agents/verifier.md`, which did
not write this diff. Eleven findings, all from that reader.

- r1: (verifier) "A GUESSED key is the opposite" inverted the mechanism — a
  guessed VALUE reds, a mistyped KEY is silent, because `lint_enum` only ever
  sees the value of a key it looked for. Reproduced here: `priorty: urgent` in
  a throwaway clone gives `ci: pass`, exit 0 (fixed — value and key are now
  separate bullets, and the silent key is named as the open downgrade)
- r2: (verifier) "no node here carries a status field" is false; workstream
  files carry `status:` and `joharness.sh:2136` reds an unknown one. The node
  scoped it to a requirement or a plan (fixed — rule re-scoped, workstream
  file's own `status:` named as the exception)
- r3: (verifier) "Most practices came out convergent" contradicts the count:
  7 adopt-candidate, 2 reject, 5 convergent of 14 (fixed — counted numbers,
  with the command that recovers the node to re-count)
- r4: (verifier) PR 140 cited as the red-on-purpose precedent; PR 140 is the
  case that stayed GREEN and cost a plan. The red precedent is the malformed
  `issue:` guard (fixed — quote and citation swapped to that guard)
- r5: (verifier) the recovery command ships to consumers via
  `.agents/scripts/sync-to-consumer.sh`, where it resolves to nothing (fixed
  — says the node is recoverable in joharness only)
- r6: (verifier) third paragraph carried adopt-candidate remedies the node
  routed to the human, and a hand-written queue snapshot nothing invalidates
  ("neither exists yet ... six sit unqueued") (fixed — snapshot deleted; what
  stays is measured intake behaviour, which does not go stale)
- r7: (verifier) `## Review` held prose, not a finding: `ci` printed "1
  finding(s) nothing can key on" twice, and no finding carried the
  `(verifier)` tag the edge gate wants (fixed — this section)
- r8: (verifier) `plan: capture-intent` dangles once the same diff deletes
  the node; `ci` warns for the pull request's whole life (wontfix — deleting
  the node IS the graduation, and the alternative, `plan: none`, hides the
  claim while the work is live. The file retires before the merge, so the
  warn dies with it)
- r9: (verifier) `finish` red while the workstream file stands (fixed — the
  retire commit is the last commit before the pull request opens)
- r10: (verifier) three gate behaviours asserted with no way to re-derive
  them, in the commit that deletes the Method block holding the probes
  (fixed — each bullet names the reader function or prints its own output)
- r11: (verifier) two verified facts dropped: a requirement named `README.md`
  gets silence, and the vocabulary IS documented, one hop away (fixed — both
  restored, the second as the reason the guard belongs earlier)

## Blockers

None.

## Where to look

- `.agents/docs/product/README.md` — Requirements section, where the
  answer landed.
- `.agents/docs/research/README.md`, Graduating — why-explanation, not a
  rule line alone.
- The deleted node holds F4 and F9, the two rejections, and its
  `## Graduates to` states the shape:
  `git log --diff-filter=D -- docs/research/capture-intent.md`, then
  `git show <commit>^:docs/research/capture-intent.md`.
