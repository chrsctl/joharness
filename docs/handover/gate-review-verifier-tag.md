---
workstream: gate-review-verifier-tag
status: in-progress
branch: claude/gate-review-verifier-tag
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01U5n5yq7MV37GaiAmj6szbx
agent: sonnet
updated: 2026-09-02
next: Retire this file, open the pull request, merge.
---

## Goal

Generate-work edge, `JOHARNESS_MODE=unsupervised`: no GitHub issue, no
unplanned requirement, no free plan (the queue's only plan,
`unsupervised-endurance`, is claimed by `origin/claude/gastown-review-owjgzg`
per the session-start hook). `./joharness.sh sources` reads NOT dry — 4
unmarked findings since the `FB_SINCE` baseline. This build turns one of
those four into a plan, per `.agents/docs/plans/README.md` ("At the edge"):
one finding, one plan, carrying `source:` and `evidence:`.

## Decisions

- **Picked r6 over the other three.** The sweep names four unmarked
  findings since `bcebb325e92f`. Three (`endurance-mode-flip.md` r2,
  `sweep-recursion-guard.md` r2, `plan-provenance.md` r5) are each written
  `(recorded — ...)` — deliberately not a marker per `joharness.sh:fb_marker`'s
  own comment, and each is closed reasoning about a decision already taken
  elsewhere, not an open defect. `unmarked-detector-baseline.md` r6 —
  "verifier round owed and NOT run" — names a live, checkable gap in the
  gate itself, is not `(recorded)`-shaped, and reproduces with a command a
  human can rerun.
- **Generate, don't implement.** Loop step 2: "decompose into plan first,
  decompose = the work." This branch writes and merges the plan; the fix to
  `review_report` is the plan's scope, for whichever session (this one or
  another) takes it next.
- **Immutable history, not a retroactive fix.** r6 sits in a merged,
  deleted workstream file. Nothing this branch does can add a `(verifier)`
  tag to that history — the plan targets the gate so this class of finding
  stops recurring, not r6 itself. (Also recorded in the plan's Out of
  scope.)

## Rejected

- **Folding all four findings into one plan.** The queue rule is explicit:
  one finding, one plan. A combined plan would bury r6's specific,
  actionable gap under three findings that are each just recorded reasoning
  with nothing left to build.
- **Marking r6 `(recorded)` somewhere on `main`.** There is no live file to
  write that into — the workstream file that carried it is gone by design
  (`.agents/docs/handover/README.md`, Graduation). The count only moves by
  advancing `FB_SINCE`, and that is PR 161's mechanism to invoke again
  later, not this branch's to reach for on one finding.

## Review

Round 1, sonnet, self.

- r1: confirmed the four unmarked findings by replaying `fb_workstream` /
  `fb_findings` by hand (`git log --full-history --name-only <base>..<merge>
  -- docs/handover`, then `git show <commit>:<path>` on the last surviving
  version) rather than trusting a paraphrase — the plan's `evidence:` cites
  the exact commit and path so this reproduces. (fixed — evidence line
  carries the reproducing `git show`)
- r2: this workstream itself owes the same verifier round the plan is
  about — noted here so it is not the second one in a row that skips it.
  (fixed — round 2 below is that verifier, spawned before this branch
  reaches the edge)

Round 2, sonnet, `.claude/agents/verifier.md` (tagged `(verifier)` per
`.agents/docs/agent-selection.md`). Reproduced the frontmatter `evidence:`
independently (`JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh sources`,
`git show 3ca4292...:docs/handover/unmarked-detector-baseline.md`) rather
than trusting the paraphrase, and cross-checked the plan's claims against
the real `joharness.sh` and `review.sh` at the commit reviewed
(`c6dc974`).

- r3: (verifier) commit `c6dc974` (the SHIPS-acceptance-bullet fix) landed
  on this branch with no matching bullet added to this section in the same
  commit — the exact silent-fix pattern this plan exists to gate against.
  (fixed — recorded here; `c6dc974` itself is already pushed and not
  rewritten, per Part 2's rule against rewriting a pushed commit's history
  for a cosmetic reorder — every fix from this point on gets its bullet in
  the same commit)
- r4: (verifier) the plan's Goal said PR 161's branch "recorded five
  self-review findings" before failing to spawn the verifier; the merged
  file actually carries six findings under one `Round 1, opus, self`
  heading, and r6 (the verifier-gap finding) is one of the six, not a
  seventh event outside the count. (fixed — Goal reworded to six, with r6
  named as one of them)
- r5: (verifier) the "Where to look" anchor
  `.agents/harness/selftest/review.sh:~130` used a line number rather than
  a symbol — the exact pattern `.agents/docs/plans/README.md` warns
  against, and the number was already stale (the real case starts at line
  136). (fixed — anchor dropped the line number, named the case instead)
- r6: (verifier) "Where to look" pointed at `review_count` as reusable for
  the new tag check; it only returns a bare count and never exposes finding
  text, and does not fold wrapped continuation lines the way `fb_findings`
  does — this repo's own selftest has a case for exactly why that fold
  matters. An implementer following the literal pointer risked a tag check
  that misses `(verifier)` on a wrapped line. (fixed — pointer moved to
  `fb_findings`, matching the hedge the Scope section already carried)

## Blockers

None.

## Where to look

- `docs/plans/gate-review-verifier-tag.md` — the generated plan.
- `joharness.sh:review_report` and `joharness.sh:fb_findings` — where the
  plan's fix lands.
- `git show 3ca42921fbe238f02a53c6935de3a328a570f06b:docs/handover/unmarked-detector-baseline.md`
  — r6, the finding this plan answers.
- `.agents/docs/plans/README.md`, "At the edge" — the generate-work rule
  this build follows.
