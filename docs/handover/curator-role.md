---
workstream: curator-role
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: none
plan: curator-role
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-11
next: Verifier running on the curator commit; fix what it returns, then this is ready for the human's review as a PR (SUPERVISED ONLY)
---

## Goal

A periodic role that checks the plan queue: repairs stale declarations,
declutters obsolete plans, and proposes ordering and decomposition. Plan:
`docs/plans/curator-role.md`. Second item on this branch — the first,
`rescope-held-plans`, is pushed and awaiting the human's merge (protocol
text), and both touch the same `cmd_dispatch` region, so a separate branch
would conflict for nothing.

## Decisions

- Name **curator** (`/curate`, `./joharness.sh curate`): verb-command plus
  `-or` role noun, matching the existing vocabulary. Rejected "worker" — a
  worker here is a claimless subagent that dies with its parent's turn, and
  this role needs a branch and a pull request. It is a second KIND of session
  at manager level, like the reporter, holding no slot.
- Requester's two calls, 2026-09-11: REPAIR and DECLUTTER act; ORDER and
  DECOMPOSE only propose. Orchestrator-driven cycle, no Routine.
- `urgency:` is never the curator's — ordering by priority is product
  direction, the stop-and-ask list. It orders by derived facts only and
  proposes the rest.
- Cadence state is derived from GIT, never stored: the last curate is the
  newest base-branch commit deleting a `docs/handover/curate-*.md`. The
  orchestrator's ledger dies with its run; git does not.
- `JOHARNESS_CURATE_HOURS` default 168 (weekly), matching `update.yml`'s sync
  cadence — the only hygiene cadence this repo already has. The number is the
  human's; 0 disables.

## Rejected

- A Routine driver. Would close the idle-queue gap; the requester chose
  orchestrator-driven only, so the gap is recorded in the plan's Goal, not
  closed.
- Letting the curator split plans. Decomposition is the opus-tier judgement
  every build rests on and it MULTIPLIES the queue — one plan into five and a
  session has grown its own backlog, which is the circularity the
  requirement ban exists to stop. It proposes instead.

## Review

Depth: opus tier, adversarial + one independent reader (verifier) on the
curator commit. Harness selftest **1822 passed, 0 failed**
(`.agents/harness/selftest.sh`, 2026-09-11).

**Can-fail, by injecting the defect into COPIES rather than reasoning** (the
tree is never edited while a job runs — ADR 0131 r18 / ADR 0145 r13). Each
injection reds its own assertion and leaves its neighbour intact, so each check
distinguishes its property from its absence. Fixture and runs 2026-09-11,
`bash <variant> curate` / `dispatch` over one scratch queue:

| assertion | clean | its injection | neighbour's injection |
| --- | --- | --- | --- |
| anchor not in tree | 1 | 0 | — |
| whole-directory claim | 1 | 0 | — |
| Scope path `scope:` misses | 1 | 0 | 1 (registry injection) |
| registry declared by 3, unmarked | 3 | 0 | 3 (coverage injection) |
| `curate DUE` tail | 1 | 0 | 0 at `JOHARNESS_CURATE_HOURS=0` |
| `NOTHING TO CURATE` | 1 on a clean queue | 0 on a dirty one | — |

**The refactor's blast radius, measured rather than argued.** `lint_anchors`
gates `ci` over every node in every consumer, so its extractor changing shape
is the worst defect available here. Old and new extraction compared over every
node file in this repo: **21 files, 24 anchor paths, 0 disagreements**
(2026-09-11). On synthetic edge cases the extracted LIST does differ — `./x`
becomes `x`, `x/` becomes `x`, and a bare `.` or `..` is dropped — and every
one of those is WARNING-neutral, because `[ -e ROOT/./x ]` and `[ -e ROOT/x ]`
agree, `[ -e x/ ]` and `[ -e x ]` agree for a directory, and `.`/`..` always
exist so dropping them warns no differently. ONE real change, in the forgiving
direction: an anchor written `joharness.sh/` (a file with a stray slash)
warned before and does not now — and stripping a trailing slash can never make
a missing path exist, so it cannot hide a genuine miss.

- r1: (session, fixture) the first `curate` run on this repo's real queue
  reported a plan's own PROSE as an undeclared path: `. Before the verdict, a `
  named as a path of `rescope-held-plans`, and `./joharness.sh curate` as one
  of `curator-role`. The extractor read every backticked token on a bullet.
  (fixed before commit: `section_paths` reads only the FIRST backticked token
  of a bullet that STARTS with one — the rule `lint_anchors` already used,
  which is what separates a deliverable from a citation — and that is why the
  two now share one reader instead of having two that can disagree.)
- r2: (session, fixture) the dispatch-cadence case wrote its workstream file
  straight after `git checkout main`, where git had just removed
  `docs/handover` — the redirect failed and `commit_all` staged nothing, so the
  retire never happened and two cases read "still due". Same gotcha the rescope
  fixture hit. (fixed: `mkdir -p` before the write, with the reason on the
  line.)

**Verifier round 1 — 15 findings, and it overturned a measurement of mine.**
I had recorded the `lint_anchors` refactor as warning-neutral on the strength of
a fixture that carried `docs/adr/` but not a single-component `missingdir/`; r8
is that case and the refactor was NOT neutral. The lesson is the one this repo
already states: a fixture chosen to make the property easy to show is not a
fixture that can fail. Re-measured with every changed case present — 22 node
files, 0 disagreements, and the only synthetic differences now are `.` and `..`,
which warn identically either way.

- r3: (verifier, correctness, every consumer's `ci`) the heading test became
  `$0 == want` where it had been the prefix regex `/^## Where to look/`, so a
  heading with a trailing space silently turned the whole section off — a plan
  with `## Where to look ` drew no anchor warning at all, and `## Scope ` yielded
  no paths for REPAIR while still counting bullets for PROPOSE. Reproduced
  differentially. (fixed: `index($0, want) == 1`; `## Out of scope` does not
  start with `## Scope`, so the two plan headings stay distinct.)
- r8: (verifier, correctness, every consumer's `ci`) the new `p="${p%/}"` took
  the only slash off a single-component anchor, which then failed the path-shape
  test and was skipped — `missingdir/` stopped warning while `docs/gone/` kept
  warning, which is why my fixture read it as neutral. Reproduced. (fixed: no
  trailing-slash strip in the shared reader; `curate_covered`'s `"$s"/*` pattern
  matches a trailing slash anyway.)
- r1: (verifier, correctness — the cycle could never fire) `--diff-filter=D`
  without `--full-history` cannot see the curator's retire: the workstream file
  is added AND deleted inside its own branch, so the merge is TREESAME for that
  path and default simplification never walks it. Every pass read "none has ever
  landed" and spawned a curator, forever, with `JOHARNESS_CURATE_HOURS` dead.
  Measured on this repo, `docs/handover/*.md`: 13 deletions simplified against
  195 with the flag, newest 2026-08-26 against 2026-09-10. (fixed: `--full-history`.)
- r2: (verifier, the test pinned nothing) the case that would have caught r1
  committed the workstream file and its removal straight on `main` — linear
  history, the one shape simplification cannot hide — so it was green over the
  bug and its sibling "one is due" was satisfied BY the bug. ADR 0145's
  "the FIXTURE was fiction", in a new place. (fixed: the case retires on the
  branch and merges it, and a new arm asserts the fixture still discriminates —
  simplified history finds nothing where `--full-history` finds the retire.)
- r4: (verifier, the repair is absent exactly when it matters) the registry count
  was built from FREE plans only, so a held plan's declaration dropped out and
  the count fell below threshold BECAUSE a branch was in flight on that
  registry — the overlap the repair exists to pre-empt. Reproduced. (fixed:
  counted over every plan; findings still emitted for free plans only.)
- r5: (verifier, false DELETE candidate) the peer count grepped the raw
  `requirement:` text, so a plan naming its requirement by path matched nothing
  and one naming it by stem counted only itself: two plans serving one
  requirement were each offered for deletion, and the stem went unescaped into
  an ERE. Reproduced. (fixed: counted through `lint_stem` and the same reader the
  edge lint uses.)
- r6, r7: (verifier, false findings from one space and one capital)
  `${s#shared:}` trimmed no whitespace and was case-sensitive, where the hook is
  deliberately both — `shared: src` and `Shared:reg/index.py` produced phantom
  paths and false DELETE candidates. Reproduced. (fixed: the prefix is
  normalized in `curate_scope_list`, so every consumer tests one spelling; the
  docstring's claim of agreement with `scope_lines` is now true.)
- r9: (verifier, a repair that inverts the author) `scope: none` is the
  TEMPLATE's documented default — the plan joins no wave on purpose — and drew
  one repair per Scope bullet telling the curator to add them. Reproduced.
  (fixed: scope-derived repairs skip an unscoped plan; the anchor repair still
  applies, being about the body.)
- r10: (verifier, the suite reds in the operator's own shell) the three new knobs
  were absent from `selftest.sh`'s `unset` list, whose comment names this exact
  hazard with its measurement — `JOHARNESS_CURATE_HOURS=0` exported gave 7
  failures. (fixed: all three unset.)
- r12: (verifier, cost paid even when off) the curate-branch scan walked every
  remote ref a second time and sat ABOVE the off switch: +30% on this checkout's
  132 refs (6749/6827/6753 ms against 5227/5197/5169, three runs each,
  2026-09-11), and `JOHARNESS_CURATE_HOURS=0` saved none of it. (fixed: the knob
  and the age are read first; off scans nothing, and not-due scans nothing
  because a curator in flight cannot make a not-due pass due.)
- r13: (verifier, a verdict asserting what it did not check) an all-held queue
  printed `NOTHING TO CURATE — every declaration reads true`, which
  `curate.md` reads as "stop and say so". Reproduced. (fixed: `NOTHING READ`,
  with its own case.)
- r14: (verifier, output) `${label##*claimed on }` kept the label's closing
  bracket, so a HELD row printed `origin/mgr-h]`. (fixed, and the case now
  asserts the branch rather than only the section header — which is how this
  survived.)
- r15: (verifier, knob semantics) at 0 or 1 every exclusive declaration became a
  registry repair AND the PROPOSE window `>= 2 && < regthr` inverted to empty,
  so the overlap class vanished; `0` also means "off" for the hours knob.
  (fixed: floored at 2, with the reason on the line.)
- r11: (verifier, assertions that pass with the feature removed) the DECLUTTER
  case left "no OTHER plan serves it" unpinned; the HELD case asserted only a
  section header; and `refute "big: scope:"` could not fail for the reason its
  label gave. Uncovered branches were where r6 and r7 lived. (fixed: cases for
  both `shared:` spellings WITH a positive control proving the fixture can
  speak, both requirement spellings, the last-plan-serving-it case, `scope:
  none`, DECLUTTER signal 2, and `NOTHING READ`. One of my own new refutes named
  a plan the fixture never creates — the same unmatched-needle class — and was
  corrected before the run.)
- note: (verifier, clean) `dispatch_curate_branches` and the header loop both
  follow the collected-refs + `</dev/null` pattern, so the stdin-consumption
  race from the rescope edge does not recur; `curate_covered` is quoted so a
  glob char in a scope path matches literally; an in-flight curate branch is
  double-counted as neither a manager nor a leftover edge. (no change needed.)

## Blockers

None.

## Where to look

- `joharness.sh:lint_nodes` — the whole-queue plan walk to reuse.
- `joharness.sh:dispatch_rescope_branches` — the stateless in-flight scan to copy.
