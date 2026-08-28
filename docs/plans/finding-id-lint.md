---
plan: finding-id-lint
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh, .agents/docs/handover/TEMPLATE.md
---

## Goal

A third of recorded findings reach nothing. `./joharness.sh feedback` on
`origin/main` 2026-08-28: **343 findings, 122 carrying no `r1:` id** —
"counted here, but nothing links them to the files they landed on". The fix
map keys on `^\+- r[0-9]+:` (`joharness.sh:fb_fix_map`) and the disposition
classifier on `r[0-9] | r[0-9][0-9]` against `${line%%:*}`, so a bullet
without an id-then-COLON is invisible to the loop that serves findings back.

`.agents/docs/feedback.md` scores this: stage 4, Prevent, is "the only one
that changes an outcome", and it is exactly what an unattributable finding
cannot reach. Recurrence in the same run is 9/26 (34%) over the newest 8
edges, with `.agents/harness/selftest.sh` at 13 edges and `joharness.sh` at
10 — the repeats are real, and a third of the evidence about them is dark.

Measured on the sessions that wrote them, not assumed: the workstream file
retired in `ddc33b3` carries 14 findings under `## Review` and **0** match
`^- r[0-9]+:` — they were written `r1 `, `v1 `, `c1 `, id without colon and
two invented prefixes. The `TEMPLATE.md` prescribes the form; nothing
checks it, so a session that varies it never learns.

## Scope

- `joharness.sh` — a `ci` stage reading finding bullets under `## Review`
  in every workstream file the branch's diff touches, and reporting any
  that the fix map cannot key on. WARN first, never red: `churn` and
  `review` both earned their gates on a backtest and this has none, and a
  gate that reds a working branch is a gate sessions route around.
- `.agents/docs/handover/TEMPLATE.md` — state the form as a requirement
  with its reason (`- r<N>: text`), not as an example a reader may vary.
- `.agents/harness/selftest.sh` — a fixture whose `## Review` mixes valid
  and invalid bullets: the invalid ones are named, the valid ones are not,
  and a file with no `## Review` section is silent.

## Out of scope

- Rewriting existing findings in history. The 122 are in retired files and
  merged commits; rewriting records to satisfy a new lint is the falsified
  evidence this repo already paid for once (PR #99's sweep).
- Failing `ci`. Report first. A later plan gates it if the number falls and
  the gate is what held it.
- Changing the id scheme, or teaching the fix map new prefixes. The form is
  fine; nothing was checking it. Widening the parser to accept `v1`/`c1`
  spreads the vocabulary this fixes.
- Attribution for findings recorded with an id but no fix commit
  (deliberate `wontfix`). That is `feedback`'s documented blind spot and a
  different question.

## Acceptance

- `./joharness.sh feedback` before and after a branch that records findings
  in the prescribed form: the "carry no `r1:` id" count does not grow.
  Paste both.
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
- `joharness.sh:fb_disposition` — the `${line%%:*}` classifier and its
  `r[0-9]` case.
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
- Never rewrite a finding to satisfy the lint. Fix the form going forward.
