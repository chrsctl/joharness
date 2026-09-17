---
workstream: janitor-role
status: in-progress
branch: claude/worker-idle-detection-l3v9m3
pr: none
plan: janitor-role
issue: none
session: https://claude.ai/code/session_01TsLnukcKvuRKLXcJ34BLhg
agent: opus
updated: 2026-09-17
next: Retire this file and the plan in the last commit before the pull request opens
---

## Goal

Requester: a separate role that cleans up and unblocks plans, once every 12
hours. Logic already exists in pieces — the curate cycle's cadence shape,
`./joharness.sh cleanup`, issues #254 and #249 — and none of it releases a
claim held by a session that is gone. Eight branches on this repo carry
claims today, six of them pushed 11 days to 4 weeks ago.

## Decisions

Requester left the three design calls to this session ("decide what's best,
goal is clear"). Taken:

- **Release, do not delete.** The janitor writes `status: abandoned` into the
  claim's OWN workstream file on its own branch and records why under
  `## Blockers`. Deleting the file would destroy the record the whole protocol
  rests on, and a returning session can set it back. Precedent for writing to
  another session's branch: the orchestrator's kill handover
  (`.agents/docs/orchestrated.md`, The kill).
- **A new status word, not a reuse.** `blocked` means a human is owed an
  answer; an abandoned claim is owed nothing. The vocabulary has exactly five
  readers (`joharness.sh:lint_enum`, `queue-context.sh`'s claim filter,
  `cmd_dispatch`, `cmd_analysis`, the handover README), so the word is
  cheap to add and the alternative — overloading `blocked` — is the
  ambiguity #254 measured.
- **Liveness is proven, never inferred.** Push age is not liveness in either
  direction (`.agents/docs/handover/README.md`). The command prints
  candidates and the evidence to check; the SESSION reads the control plane
  and only `ARCHIVED` / not found / a confirmed failure releases anything.
- **An unowned block is a dead claim** (#254's own reasoning: nobody waits on
  that answer, nobody will act on it), but its `## Blockers` text is carried
  into the release note, never discarded.
- **Clock only, 12h.** The curate cycle needed a production trigger because
  plan churn is bursty; here the subject IS elapsed time. A pass with nothing
  to release still lands its retire commit, which is what dates the cycle.

## Rejected

- Adopt-and-finish the abandoned branch. That is a build, not a sweep, and it
  breaks one-item-per-session. Loop step 2 already routes a picking session to
  edge work; the janitor makes the claim visible instead.
- Deleting the branch. `git push --delete` is forbidden to a session
  (AGENTS.md step 7); the janitor lists merged and released branches for the
  human.
- Dead `needs:` / `research:` edges as a sweep target. `ci`'s graph lint
  already reds an edge naming a node that never existed, and a satisfied edge
  clears itself when the file is deleted on merge. Nothing to sweep.

## Review

- r1: dispatch's `ANALYSE?`-style row for a released claim was unreachable —
  dispatch's in-flight rows come from the hook's `claimed on` annotation, and
  a released claim no longer produces one. Dead code that reads like a rule;
  removed, and the plan now records that the row correctly vanishes (fixed)
- r2: the selftest fixture wrote into `docs/handover` after a checkout that
  had emptied it, so three cases read the previous state's output. `mkdir -p`
  after every checkout and every `git rm` (fixed)
- r3: (verifier) `janitor_branches` keyed on the FILENAME. Reproduced: a real
  sweep in `janitor2026-09-18.md` went unseen and `dispatch` printed both
  `janitor : DUE` and the spawn line — two janitors writing releases to the
  same branches. The curate reader's own comment says frontmatter decides and
  names the incident that bought it; now `workstream: janitor-<digit...>` plus
  `plan: none`, and a case that pins each half (fixed)
- r4: (verifier) the `drain` janitor block was mode-blind — the defect the
  curate block ten lines above carries its own post-mortem for (r27 there).
  Under orchestrated it told a manager to run a sweep that is the
  orchestrator's to spawn, beyond the cap. Same carve-out as curate now (fixed)
- r5: (verifier) `cycle_landed_sha janitor` dated the cycle off ANY
  `janitor-*.md` deletion, including THIS branch's own retire commit
  (`janitor-role.md`), which would have suppressed the first real sweep for
  12h. The glob carries the digit now; `curate-*` deliberately unchanged, and
  a case pins both directions (fixed)
- r6: (verifier) `printf '%b'` expanded backslash escapes out of a
  branch-controlled `workstream:` field, forging an extra row in both
  `janitor` and `dispatch` — the output an orchestrator spawns from. Fields
  are sanitised at the reader now, and a fixture carrying the escape pins it
  (fixed)
- r7: (verifier) `handover-context.sh:rank_of` had no `abandoned` case, so a
  released claim fell to rank 3 — or 2 with a `pr:` — and could LEAD the
  in-flight listing as `FINISH BEFORE STARTING`. Ranked 5, below blocked
  (fixed)
- r8: (verifier) a released claim still held its ISSUE: `claimed_issues` had
  no status filter, so the release freed the plan and held the issue, which
  Loop step 2 ranks ABOVE plans. #254's own failure one field over (fixed)
- r9: (verifier) `analysis` marked a released claim `STALL?` for ever — a
  clock nobody is watching on a branch that will never push again. It now
  carries no condition, and its verdict says the claim was released rather
  than "a manager at work" (fixed)
- r10: (verifier) `cmd_janitor` printed `IN FLIGHT, so none is due ... (of
  99999h)` — asserting a sweep was due while its own reader said not due. The
  walk is gated on `due`, as `drain` and `dispatch` already gate theirs
  (fixed)
- r11: (verifier) `janitor_branches` roughly doubled `drain`, which every
  session runs: 12.075s against 5.521s with the cycle off, `perf --live`
  counting 689 against 500 on main, over 142 refs (verifier, 2026-09-17). It
  now carries the curate reader's `--no-merged` and its `ls-tree | grep`
  prefilter, and `cmd_janitor` walks only when a sweep could be due.
  Re-counted after the fix, same checkout, 2026-09-17: `DRAIN_FETCH=0
  ./joharness.sh drain` 1827/1919/2133ms with the cycle on against
  1892/1855/1843ms with `JOHARNESS_JANITOR_HOURS=0` — indistinguishable;
  `perf` 292 against a budget of 308; `perf --live` 555 against the 500 the
  verifier counted on main, down from 689 (fixed)
- r12: (verifier) `cl_inflight` was called inside the leftovers loop rather
  than hoisted as `cmd_cleanup` hoists it — one full ref walk per leftover,
  ~2s each on this checkout (fixed)
- r13: (verifier) the case naming the digit guard did not pin it: its fixture
  also carried a real `plan:`, so the other half of the identity did the
  rejecting. Mutation-tested green with the guard deleted. The fixture now
  carries `plan: none` (fixed)
- r14: (verifier) no case reached the `since the last sweep` path at all — the
  whole dating parameterisation, including r5's defect, was untested. Two
  cases now land a sweep and retire it (fixed)
- r15: (verifier) two assertions searched for strings no code path produces
  (`gone:`, and `released` where the tail spells it `releases`). Replaced with
  ones that fail if the command ever states an outcome for a session it did
  not read (fixed)
- r16: (verifier) the plan claimed `holds :` would attribute the scope-overlap
  holds #254 asks for; what shipped names the claim's own plan. Narrowed in
  the plan rather than widened in the code: the overlap computation is
  `wave_split_hit`'s, and a second reader of it is the failure this repo keeps
  paying for (fixed)
- r17: (verifier) `.agents/harness/AGENTS.md` step 2 named `/curate` and not
  the sweep, so a session following it literally had no rule for a `plan:
  none` janitor item. One clause added beside the curate one (fixed)
- r18: (verifier) the same `printf '%b'` shape exists in the CURATE in-flight
  path, which this branch did not introduce and does not touch. Not fixed
  here: it is a defect in shipped code with its own blast radius, and a fix
  riding an unrelated diff is how a reviewer loses track of both. Reported to
  the human instead (wontfix — reported, not mine)
- r19: (verifier) the fixture's cadence assertions are wall-clock relative:
  `JOHARNESS_JANITOR_HOURS=99999` reads not-due only until the fixture's
  2026-01-01 base is 99999h old, around 2037. Left as is: pinning it would
  mean freezing `date`, which the runner does not do for any other topic
  (wontfix — dated, and the date is in this line)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:claims` — where a claim holds a plan.
- `joharness.sh:dispatch_curate_due` — the cadence shape this copies.
- `joharness.sh:cmd_cleanup` — the leftover sweep, already built.
