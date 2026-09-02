---
workstream: queue-hides-supervised-only-plans
status: done
branch: claude/current-state-review-oxfb7f
pr: none
plan: queue-hides-supervised-only-plans
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Open the pull request and merge it; the work is done and verified
---

## Goal

The endurance retry of 2026-08-31 spent 55 minutes and $12.05 on
`marker-gate-needs-no-done`, a plan whose whole declared scope is protocol
text — which the unsupervised-mode Constraints forbid an unattended session
to commit. The session did everything right and could not finish. The queue
offered it as the top free item, and the disqualifying fact was in the
plan's own `scope:` frontmatter the whole time. Mark such a plan and stop
offering it to an unsupervised fleet.

## Decisions

- **Mode-gated, both the mark and the de-rank.** The plan's Acceptance says
  a supervised session sees the plan unchanged, and `queue-context.sh`
  already states the rule for itself: every mode-dependent line sits inside
  a branch `qc_mode` guards, so supervised output stays byte-identical.
  Supervised also pays zero extra forks, which keeps the perf row honest.
- **The protocol list comes from `joharness.sh protocol-paths`, one fork per
  hook run, not per plan.** Second copy is what issue #114 cost. Same call
  shape `handover-guard.sh` already uses.
- **Comparison is git pathspec semantics**, matching how the guard compares
  the same list: an entry is protocol when it equals a protocol path or sits
  under one at a slash boundary. `joharness.shX` therefore does not match
  `joharness.sh` — a Trap the plan names.
- **Classification is pure bash, no forks per plan.** A `tr`/`sed`/`grep`
  pipeline per plan is the fork-in-a-loop regression the perf budget exists
  to catch, in the file whose budget is tightest.
- **`scope:` is read in the row loop's existing `fields` call.** That call
  already reads six keys in one pass; a seventh costs nothing, and the rank
  is computed there.
- **De-rank is +2, the weight `claimed` carries** — listed, never leading.
  Not +4 (blocked): nothing is blocking it, and a supervised session should
  still see it as takeable work.
- **A plan with no `scope:` is UNKNOWN and is not marked SUPERVISED ONLY**,
  because guessing scope is out of the plan's scope. It gets its own
  unsupervised-only label instead, so absence is not silently read as clean.
- **`drain` reads the hook's answer, never re-derives it.** `drain_plan`
  filters the same string the hook prints, and `cmd_drain` names the
  supervised-only plans before deferring to the sweep — otherwise "queue
  empty" would print over a plan that is sitting right there, which is the
  DRAINED-over-a-requirement defect PR 157 fixed.

## Rejected

- **Marking in supervised mode too.** Reads as a useful warning; breaks the
  Acceptance line that says a supervised session cannot tell the feature
  shipped, and buys nothing — a supervised session may legitimately take the
  plan.
- **Blocking the session from taking it.** Explicitly out of scope: this
  marks and de-ranks, it does not forbid.

## Review

Depth is opus-adversarial (`./joharness.sh review`), plus a verifier that did
not write this diff.

- r1: **`drain` was reading a queue it never asked about.** `drain_hook` set
  `CLAUDE_PROJECT_DIR` and `HANDOVER_FETCH` and nothing else, so
  `queue-context.sh` fell back to `${JOHARNESS_RUN_MODE:-supervised}` and
  answered as supervised no matter what mode `drain` had just resolved and
  printed in its own banner. Every mode-dependent line in the hook was
  therefore invisible to `drain`, and the SUPERVISED ONLY row arrived here
  ranked free. Not a defect this change introduced — it predates it, and it
  means the session banner and `drain` have been describing different queues
  from one tree. Found because the new cases failed on a `next:` line that
  should have been filtered. (fixed — the resolved mode is passed to the
  child, exactly as `cmd_session_start` passes it; +2 external commands on
  the `drain` row, counted below)
- r2: two of my own first-draft assertions were vacuous, both in the shapes
  this repo has already paid for. `refute ... "1 free plans"` named a line
  the hook only prints at two or more free plans, so it could never have
  matched; and the unreadable-boundary `refute` matched the explanatory note
  that itself contains the words "marked SUPERVISED ONLY". Caught by running
  them, not by reading them. (fixed — the first asserts on the tail line the
  hook does print, the second reads the plan ROW)
- r3: my ordering case asserted the marked plan leads under supervised, and
  it did not: both plans were committed within the same second, so `added`
  tied and `sort`'s last-resort whole-line comparison decided it on the
  filename. That is PR129 r3's tie, walked into while writing a case about
  ordering. (fixed — the free plan is named `ztakeable` so the tie-break
  gives the OPPOSITE answer, which makes the rank the only thing that can
  produce the result asserted)
- r4: `ci` is RED on this branch and red on `origin/main` in this same
  container. One selftest CASE fails — the `graph` row's — but FOUR perf rows
  are over, and the first draft of this bullet said "on one case" about both:
  `graph` 422/260, `session-start` 1179/700, `queue-context` 494/350,
  `drain` 1179/700, with `feedback`, `review` and `handover-guard` inside. It is the ref count, and that is now measured rather than called
  container-local: a `--single-branch` clone of this repo has 1
  remote-tracking ref and counts `graph` 31, `session-start` 86,
  `queue-context` 61, `drain` 83 — every row far inside budget. This
  container has 107, because 44 merged branches and their tracking refs are
  still standing (issue #167). The budgets were calibrated against a CI
  checkout, which fetches one branch. (wontfix on this branch — raising a
  literal to match an operator's ref count is what the row's own comment
  forbids, and the fix is deleting branches, which is human-only. Verified
  the other way instead: the whole suite is green in a single-ref clone.)
- r5: the change costs 0 external commands in the queue hook and +2 in
  `drain` — that row moved 1186 -> 1188 for r1's two `run_mode` calls, while
  `queue-context` and `session-start` did not move at all (497 -> 497,
  1188 -> 1188). Zero in the hook is the design and not luck: the boundary
  list is read once per run rather than per plan, `scope:` rides the
  `fields` call that was already there, and the classifier sets a global
  instead of being called in a `$( )` that would fork per plan. Measured on ONE tree by swapping only the two
  changed files, because these counts drift with repo state and a
  before/after taken across a commit is not a measurement of the code.
  (fixed — nothing to change; the design intent, counted)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh` — the row loop computes rank and label;
  `qc_mode` guards every mode-dependent line.
- `joharness.sh:protocol_paths` — the one list. `protocol-paths` is the
  subcommand.
- `joharness.sh:drain_plan` — the filter that keeps claimed and blocked rows
  out of `next:`.

### Verifier round (`.claude/agents/verifier.md`, opus, did not write this diff)

It confirmed the Acceptance line that would have sunk this: supervised output
is byte-identical, diffed over a queue carrying urgent, normal, blocked,
claimed, requirement-served, unplanned, a zero-byte plan and every scope
shape, under `supervised`, unset and a bogus mode. Then it found eight real
defects.

- r6 (verifier): **`sources` printed `queue empty : yes` over a marked plan,
  naming nothing.** `drain_hook` passing the mode reaches `cmd_sources` too,
  so the de-rank made the queue read empty in the ONE report that decides
  whether an unattended fleet may stop — the "status line reading nothing to
  do while work is right there" defect this change's own comment says it
  exists to prevent, reintroduced one function away. Reproduced: one goal,
  one all-protocol plan, `queue empty : yes` here against `no — next:` on
  `origin/main`'s code. (fixed — the same NOT YOURS naming, from one shared
  extractor `drain_supervised_only`, so the marking still has one reader)
- r7 (verifier): **`for entry in $raw` was unquoted, so a scope was
  pathname-expanded against the working tree.** `scope: joharness.*` marked
  the plan; creating an UNTRACKED `joharness.conf` beside it un-marked the
  same plan on the same ref. `handover-guard.sh` carries a paragraph about
  paying for this on this same list. (fixed — globbing off across the split,
  restored only if this shell had it on; a glob is now just a path that
  matches nothing)
- r8 (verifier): **a space in a path silently un-marked an all-protocol
  plan.** `scope: .agents/harness/two words.sh` split into two entries, the
  second not a protocol path, so the plan read `mixed` and went to the fleet
  as free work — the exact failure direction this change exists to stop.
  (fixed — split on the comma alone, then trim; the `shared:` prefix is
  stripped per entry rather than relying on the space to split it off)
- r9 (verifier): **`drain`'s list was capped at `QUEUE_MAX_ENTRIES`.** It
  parses the hook's DISPLAY table, which truncates at 10 for a human: 11
  marked plans listed as 10, with no count to notice the loss by. The same
  cap could hide a free plan at row 11 from `next:`. (fixed — `drain_hook`
  raises the cap for a reader that parses rather than displays, which fixes
  the `next:` case too)
- r10 (verifier): **the `queue-context` perf row measured the mode this
  change does not take.** Unpinned it inherited the repo's conf, so the new
  fork was unbudgeted: 494 supervised against 500 unsupervised on one tree.
  (fixed — the row pins the mode, exactly as the `handover-guard` row two
  lines below already does, and for the reason its comment gives)
- r11 (verifier): r4 above said `ci` is red "on one case" while four perf
  rows are over. (fixed — r4 now carries all four counted numbers)
- r12 (verifier): **`scope: NONE` read as a real path**, so the plan
  classified `mixed` and its row carried no label of either kind — checked
  and clean, which is what the plan's own Trap forbids. The `shared:` strip
  on the line above was case-blind and this was not. (fixed — case-blind,
  and the asymmetry is named in the code)
- r13 (verifier): **neither guard on the byte-identity property is pinned
  alone.** Removing the mode check leaves 38/38 green, and so does
  populating the array unconditionally; only removing both reds. (wontfix —
  the state where the two disagree cannot be built through this hook's
  interface, so no case can separate them, and a test asserting an
  unreachable state is worse than none. The redundancy is deliberate and now
  says so in the code, addressed to the refactor that would otherwise delete
  one on a NOTHING REDDED verdict.)
- r14 (verifier): **`refute "nor the second one"` in the drain cases could
  never fail** — the first plan is committed alone and precedes the second
  under every classification. (fixed — re-aimed at what is load-bearing:
  BOTH marked plans are named, including the one scoped to a protocol tree
  rather than the entrypoint file)
- r15 (verifier): **the trailing-slash normalisation was dead code and its
  comment claimed otherwise** — `case "$e" in "$p"/*` already matches a bare
  trailing slash because `*` matches the empty string, proved by a mutation
  that left the topic green. (fixed — loop removed, the case kept as an
  assertion about the `/*` arm, and the comment now says why no separate
  step is needed)
- r16 (verifier): the hook's own header lists the label vocabulary and did
  not carry the two new labels. (fixed)
- r17 (verifier): the drain fixture runs `git push --delete` against its own
  bare origin, and step 7 says a session never does that. (wontfix — the
  rule is about a real remote, and the same file already carried this call
  for `goalclaimer` before this branch; it is the fixture deleting its own
  scratch ref, not a session deleting anybody's branch)
- r18: two fixture bugs of my own, both in shapes this repo has already
  paid for. `sources.sh` wrote a plan into `docs/plans/` after a plain
  `git rm` had taken the last file there, so git had dropped the directory
  and five cases read the previous state — the trap `fixture_rm` exists for,
  reached by not using it. And the truncation case counted rows over the
  whole output, which now also carries the sweep's own list, so it asserted
  11 and got 21. (fixed — `mkdir -p` plus `fixture_rm`, and an assertion on
  the eleventh plan BY NAME with zero-padded names so the eleventh is the
  one a cap of ten drops)
