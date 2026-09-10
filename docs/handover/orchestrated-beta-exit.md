---
workstream: orchestrated-beta-exit
status: review
branch: claude/orchestration-mode-default-pfoxba
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01WAiSQMsrpscFUK9Qx63jZ2
agent: opus
updated: 2026-09-10
next: Open the pull request and merge it (step 7); retire commit deletes this file
---

## Goal

Requester, 2026-09-10, two asks in one session: first "make orchestration
mode default" (asked, denied, nothing changed), then "move orchestrated
mode out of beta". This branch carries the decomposition of the second:
nothing builds unplanned, and a direct ask becomes a plan before code
(Loop step 2).

## Decisions

- **The label is not stripped here, and the reason changed under review.**
  The first draft said one gate blocked it. The verifier found three, in
  disagreement: `.agents/docs/orchestrated.md:16` (comparative — "which
  empties a queue faster"), `.agents/docs/product/README.md:202-211`
  ("until a run **is counted**", which run 1 satisfies), and the
  requirement's last bullet (drain, no human turn — not met). A mode whose
  own docs define its beta three ways is the defect; the plan's first half
  is now collapsing them, not stripping labels.
- **Licence A may be undischargeable as written.** It is comparative, and
  `.agents/docs/unsupervised.md` Runs holds no peer-fleet drain to compare
  against — four runs, longest 60m, "Every run measured how long ONE
  generation lasts." An orchestrated drain alone cannot answer "which is
  faster". Recorded in the plan so the next session does not go looking
  for a number that was never taken.
- **`needs: orchestrated-run` is necessary, not sufficient.** The edge
  releases on that file being DELETED, and its Acceptance is satisfiable
  by a run that counts a row and drains nothing — run 1's row is already
  fully counted, so it is arguably retirable today. The real gate is the
  plan's first Acceptance bullet, and no DAG edge can enforce it. Said in
  the plan in those words.
- **Tier raised sonnet → opus.** Escalation is allowed, downgrade never.
  The work is no longer a text substitution: it decides which licence
  governs, which is product direction and the human's.
- `plan: none` here, deliberately. This workstream WROTE
  `orchestrated-beta-exit`; it does not implement it. Claiming it would
  mark a blocked plan taken and hide it from the session that runs it.
- The branch name says `orchestration-mode-default` and the work is the
  de-beta plan. The branch was designated before the second ask arrived;
  renaming orphans the designated push target.

## Rejected

- **Stripping the label now and noting the gap.** The label and the
  sentence licensing it sit eight lines apart in one file, so a reader
  hitting the strip reads the licence too. Half the change is worse than
  neither half.
- **Picking the licence myself.** Three readings, one already true — a
  session choosing the strictest and calling it "the gate" is deciding
  product direction quietly. The plan puts all three to the human as
  written.
- **Folding the strip into `orchestrated-run.md`.** That plan is scoped
  `docs/product, joharness.conf` and exists to measure. Adding 12 files
  across seven protocol paths makes one plan two.
- **Waiting on run 2 before writing anything.** The run is another plan's
  work; the decomposition is complete now and the DAG edge carries the
  wait.

## Review

Depth: opus, adversarial (`./joharness.sh review`). Independent reader:
`.claude/agents/verifier.md` at opus, which did not write the diff.
`JOHARNESS_REVIEW=off`, so the gate is report-only — the record is not.

- r1: (verifier) `needs: orchestrated-run` does not encode the gate the
  plan claimed. The edge releases on file deletion, and that plan's
  Acceptance is met by a run ending on a human turn with a counted row —
  so the plan could unblock with the gate still false. (fixed: gate moved
  to a hard first Acceptance bullet; "necessary, not sufficient" stated in
  its own subsection and again in Traps.)
- r2: (verifier) licence A is COMPARATIVE ("which empties a queue
  faster"); the draft silently substituted the requirement's absolute
  drain bullet and called them one gate. No peer-fleet drain number
  exists, so A has no counterpart. (fixed: all three licences quoted
  verbatim with locations; A's missing counterpart named.)
- r3: (verifier) the draft said the claim was "written once". Second
  licence at `.agents/docs/product/README.md:202-211` reads TRUE today
  under its own wording, and appeared in no section of the plan. (fixed:
  licence B quoted; that file added to `scope:` and to Scope.)
- r4: (verifier) site inventory incomplete and the count wrong three ways
  — 14 bullets over 17 line-sites, and 7 genuine sites missing
  (`orchestrated.md:286/291/338`, `product/README.md:202/211`,
  `orchestrate.md:55`, `bootstrap-consumer.sh:142`). The provenance grep
  did not reproduce its own list: `joharness.sh:268` spells it
  `orchestrated (beta:` with a colon and `(beta)` cannot match it.
  (fixed: recounted by hand from an unfiltered grep — 24 line-sites, 12
  files; Acceptance now says to READ the grep, not filter it.)
- r5: (verifier) the SHIPS Acceptance bullet was false. `.agents/scripts`
  is in `sync-to-consumer.sh:CANONICAL_ONLY_DIRS` and never ships, so
  `conf-keys.sh` and `bootstrap-consumer.sh` reach no consumer — `ci`'s
  own ship-scope line already omitted `.agents/scripts` and I had quoted
  it without reading it. (fixed: bullet rewritten to name what does ship
  and a check a consumer actually runs.)
- r6: (verifier) `joharness.conf:54` missing entirely — a protocol path,
  invisible to the Acceptance grep's pathspec, and colliding with
  `orchestrated-run.md`'s declared `joharness.conf` scope. (fixed: added
  as `shared:joharness.conf`, reconcile named as expected cost.)
- r7: (verifier) `joharness.sh:5868` was in Scope while
  `selftest/dispatch.sh:801` was in Out of scope — the two halves of ONE
  quotation of a rejected draft. Following Scope would destroy half the
  record. (fixed: both halves out of scope, as one entry.)
- r8: (verifier) "eleven protocol-path files" in this file was the total
  file count relabelled; 11 files, 7 of them protocol paths. (fixed:
  rewritten as "12 files across seven protocol paths".)
- r9: (verifier) Scope pinned 17 line numbers into a 6600-line file for a
  plan blocked by design for days. `lint_anchors` checks the path only, so
  a stale number stays green forever. (fixed: sites named by their text.)
- r10: (verifier) the draft's only `## Review` bullet was prose about
  process, which `TEMPLATE.md` says explicitly does not count as a
  finding. (fixed: this section.)
- r11: (verifier) after `orchestrated-run.md` deletes the requirement
  file, this plan's `requirement:` and one `Where to look` anchor dangle.
  Verified it is `lint_warn`, not red (`joharness.sh` requirement lint and
  `lint_anchors`). (wontfix: a warning on `main` is the correct signal
  that a plan outlived its requirement; suppressing it would need a second
  spelling for "satisfied". Recorded so the next session does not
  re-investigate.)
- r12: no prompt injection in either file; the verifier re-ran its own
  greps rather than executing the plan's text, and reported that both the
  count and the SHIPS claim failed under independent recount. (fixed via
  r4 and r5.)

## Blockers

None for this branch. The plan it writes is blocked by design on
`docs/plans/orchestrated-run.md` — and, as r1 records, on a gate that file
cannot enforce.

## Where to look

- `docs/plans/orchestrated-beta-exit.md` — the deliverable.
- `.agents/docs/orchestrated.md` — licence A, and the Runs table.
- `.agents/docs/product/README.md` — licence B, the peer/lead position.
- `.agents/docs/unsupervised.md` — the four peer runs A would compare to.
