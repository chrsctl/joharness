---
plan: finding-id-lint
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest/review.sh, .agents/docs/handover/TEMPLATE.md
---

## Goal

A third of recorded findings reach nothing. `./joharness.sh feedback` on
`origin/main` 2026-08-28, default window (`JOHARNESS_FEEDBACK_EDGES=50`, the
newest 50 of 107 edges, 38 carrying a workstream file): **343 findings, 122
carrying no `r1:` id** —
"counted here, but nothing links them to the files they landed on". The fix
map keys on `^\+- r[0-9]+:` (`joharness.sh:fb_fix_map`) and the disposition
classifier on `r[0-9] | r[0-9][0-9]` against `${line%%:*}`, so a bullet
without an id-then-COLON is invisible to the loop that serves findings back.

`.agents/docs/feedback.md` scores this: stage 4, Prevent, is "the only one
that changes an outcome", and it is exactly what an unattributable finding
cannot reach. Recurrence in the same run is 9/26 (34%) over the newest 8
edges, with `.agents/harness/selftest.sh` at 13 edges and `joharness.sh` at
10 — the repeats are real, and a third of the evidence about them is dark.

Measured on the sessions that wrote them. Two files, counted separately
because an earlier draft of this paragraph merged them and got the shape of
the defect wrong:

```
git show ddc33b3^:docs/handover/review-verifier-subagent.md \
  | grep -oE '^- [a-z]+[0-9]+' | sed 's/[0-9]\+/N/' | sort | uniq -c
```

- `ddc33b3`'s file: 14 findings, all `rN` — the right prefix, no colon. 0
  match `^- r[0-9]+:`.
- the `backpass-remove` file, same command: 10 `vN`, 3 `cN`, 2 `rN`. Two
  prefixes that exist nowhere in the protocol.

So the defect has two shapes, not one: the colon dropped from the
prescribed form, and prefixes invented per review round. Both land in the
122. `TEMPLATE.md` prescribes `- r1:`; nothing checks it, so a session that
varies it never learns.

## Scope

- `joharness.sh` — a `ci` stage reading finding bullets under `## Review`
  in every workstream file the branch's diff touches, and reporting any
  that the fix map cannot key on. WARN first, never red: `churn` and
  `review` both earned their gates on a backtest and this has none, and a
  gate that reds a working branch is a gate sessions route around.
- `.agents/docs/handover/TEMPLATE.md` — state the form as a requirement
  with its reason (`- r<N>: text`), not as an example a reader may vary.
- `.agents/harness/selftest/review.sh` — a fixture whose `## Review` mixes valid
  and invalid bullets: the invalid ones are named, the valid ones are not,
  and a file with no `## Review` section is silent.

## Out of scope

- Rewriting existing findings in history. The 122 are in retired files and
  merged commits, and a record edited to satisfy a later rule stops being a
  record. The nearest precedent is PR #99, whose glossary sweep rewrote a
  research node's measured wording and a plan's own figures before review
  caught it and restored them — findings were not what it rewrote, so read
  it as the same class rather than the same event.
- Failing `ci`. Report first. A later plan gates it if the number falls and
  the gate is what held it.
- Changing the id scheme, or teaching the fix map new prefixes. The form is
  fine; nothing was checking it. Widening the parser to accept `v1`/`c1`
  spreads the vocabulary this fixes.
- Attribution for findings recorded with an id but no fix commit
  (deliberate `wontfix`). That is `feedback`'s documented blind spot and a
  different question.

## Acceptance

- The stage's own output on a fixture, not `feedback`'s count. `feedback`
  reads MERGED edges only — its footer says "an open branch has recorded
  nothing yet" — so before and after are equal by construction on the
  implementing branch, and post-merge the number moves with a 50-edge
  window the branch does not control. Assert the stage instead.
- The stage names an invalid bullet by file and by the bullet's own text,
  and says what the valid form is. Paste it.
- A workstream file with a well-formed `## Review` produces no output from
  the stage.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`, and green on a branch whose findings are
  malformed (warn, not red).

## Where to look

- `joharness.sh:fb_fix_map` — the `^\+- r[0-9]+:` match that decides
  attribution.
- `joharness.sh:fb_collect` — the `${line%%:*}` id classifier is INLINE
  there, with the `r[0-9] | r[0-9][0-9]` case. There is no
  `fb_disposition`; `fb_marker` reads prose dispositions, not ids.
- `joharness.sh:review_count` — the hook and gate count bullets with a
  looser rule (`^- `), which is why a malformed finding still counts as a
  recorded review. Do not tighten that: the review gate asks whether a
  review happened, this asks whether it can be served back.
- `.agents/docs/feedback.md`, "What this cannot see" — the blind spot this
  closes is already written down there.

## Traps

- Two counters, two questions. `review_count` says a review happened;
  attribution says it can be reached later. Conflating them turns a
  formatting slip into "no review recorded" and reds a compliant branch.
- The stage reads the DIFF's workstream files, never the tree — a branch
  inherits every file its base carries (`.agents/harness/AGENTS.md` step 4).
  `review_report` next door enumerates with `lint_nodes docs/handover`, a
  `find` over the tree. That is the pattern this Trap forbids and it is NOT
  this plan's to change: leave it alone, and do not copy it.
- Never rewrite a finding to satisfy the lint. Fix the form going forward.
