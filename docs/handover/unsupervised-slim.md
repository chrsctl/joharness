---
workstream: unsupervised-slim
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-02
next: Record the verifier findings under Review, fix or disposition each, retire this file, open the pull request.
---

## Goal

Unsupervised mode too bulky. Requester wants cuts. Also wanted survey:
research-agent orchestration that runs only in Claude containers, and how
joharness compares. This file = both, so next session starts from findings
not from zero. This session writes the plan for Decisions 1-3
(`docs/plans/unsupervised-drain-only.md`); 4 stays the human's.

## Decisions

- Unsupervised should DRAIN, never GENERATE. Every task runner in
  andyrewlee/awesome-agent-orchestrators (aeon, cyrus, sortie, symphony,
  open-swe, Factory) pulls from external queue, stops when empty. Work
  generation moves to supervised research tier that files plans via PR.
  Deletes: `cmd_sources` + `src_stop_condition` (459 lines, 4325-4783 on
  `main` 4cae61a, `sed -n | wc -l` 2026-09-02) and the detectors above
  `authority_commit` (105 more), `FB_SINCE` baseline, dry
  sweep, "manufactures own backlog" constraint, `qc_edge_unsupervised`.
  Termination becomes: no free plan = exit. Goal-bounded stop no longer
  needed.
- Fresh session per item, not long drain. ralphex, LoopTroop do this;
  neuralyzer exists only to fake it inside one session. `/drain` becomes
  claim one, run Loop, exit. Heartbeat re-seeds. Deletes: "re-read drain
  never remember", compaction-survival guidance, two-consecutive-failure
  rule. Cost: Routine hourly floor — see decision 4.
- Claim-then-detect replaces wave partition. swarm-protocol, wit, gnap claim
  by push and detect conflict at write/merge; gastown adds Bors-style merge
  queue. Repo already has claim-by-push + reconcile. `qc_scope_class`,
  `SUPERVISED ONLY`, `scope undeclared`, wave-1-only spawn = second copy of
  same guarantee. Delete.
- GitHub Actions as heartbeat AND authority source — HUMAN DECISION,
  credential. Rejection in `.agents/docs/unsupervised.md` rests on
  `GITHUB_TOKEN` PRs get no CI. aeon, gh-aw run unattended on Actions today
  via GitHub App or PAT. Buys: sub-hour cadence; `cmd_authority` (87 lines
  + `selftest/authority.sh` 136 — `wc -l`, same day) deleted, because session started by
  repo's own workflow on repo's own event has structural provenance, no
  prompt claims anything. gh-aw read-only-default + sanitized safe-outputs
  ≈ `protocol_paths` as workflow config not shell. Propose, do not do.
- Docs: rules and links only. `docs/product/unsupervised-mode.md` (408) and
  `.agents/docs/unsupervised.md` (300) carry dated run annotations,
  corrections of annotations, provenance-of-provenance. Crewplane, Archon
  keep run receipts as artifacts apart from spec. Move measurements to
  `docs/runs/` or handover history. Requirement = `Satisfied when`
  bullets, nothing else. NOT in the plan: own plan later, so the deletion
  plan stays reviewable as deletions.
- Survey verdict: no mature framework is both research-specific and locked
  to Claude containers. Only Managed Agents multiagent sessions (beta header
  `managed-agents-2026-04-01`) satisfy "Claude containers only":
  coordinator + worker threads, shared container/filesystem, isolated
  context per thread, threads persist. joharness = protocol layer inside
  that container with `.agents/env/none`. Research primitives (source
  registry, dedupe across threads, citation format, coordinator synthesis)
  = net-new, not in any listed tool.

Made this session, while writing the plan:

- Wave partition STAYS as a report. Decision 3 deletes the marking,
  the de-rank and the wave-1-only order; `scopes_overlap` and the
  "Waves —" listing print under supervised too and the ship-scope stage
  reads `scope:`. Deleting them changes supervised output, which the
  requirement calls byte-identical. Unsupervised fan-out = one session per
  free plan, all waves; a collision is the reconcile step 7 already
  requires.
- `/drain` = one item, then exit, in BOTH modes. A mode-split loop is the
  second copy decision 3 removes elsewhere. Supervised cost: the human
  re-invokes per item; that session is attended, so the stall the loop
  fixed is the heartbeat's job now, not a command's.
- Goal bound goes with generation. It existed to bound what a session
  invents; a session that invents nothing is bounded by the queue.
  `lint_requirement_writes` stays — cheap, and still true.
- Correction to the earlier line under decision 4: `selftest/autonomy-mode.sh`
  (330) tests `run_mode`, the marker and the conf — the switch, which stays.
  `grep -c authority` on it = 0. The file decision 4 deletes is
  `selftest/authority.sh` (136). Fixed above.
- The plan's pull request is the human's to merge. It reverses the
  requirement's thesis ("an idle session should instead generate its own
  work") = product direction. Review record and retire commit land before
  the ask, per step 7.

## Rejected

- Ruflo as replacement. 250k+ LOC TS + Rust/WASM, benchmarks self-reported,
  not container-locked, coding-oriented. Opposite direction from "slimmer".
- Keeping generate-at-edge with better detectors. Constraint bullet already
  proved it: uncountable source never reaches zero; 62 of 155 unmarked
  findings carried no `rN:` id (the requirement's own Constraints, counted
  for PR 161; `./joharness.sh feedback` 2026-09-02 on `main` 4cae61a: 266
  findings, 50 without id); sweep never dry. Fix was baseline, still 459 lines.
  Structural fix is not generating.
- Tuning spawn prompt until sessions stop refusing. `unsupervised.md`
  already says no; 2026-08-31 refusals correct. Only structural provenance
  (decision 4) removes the class.
- Caps on fleet. Requester declined 2026-08-24, stands. Not re-proposed.
- Deleting the wave partition whole. See Decisions: supervised reads it.

## Review

Round 1, self, adversarial (correctness, does-it-reproduce):

- r1: acceptance grep listed `docs/product/*.md`, and the endurance
  annotation the plan keeps byte-for-byte quotes `SUPERVISED ONLY` three
  times — the bar failed the plan's own Out of scope. (fixed: requirement
  dropped from that grep; own check on the deleted bullets' first lines,
  each measured to hit only its bullet)
- r2: `cmd_session_start`'s unsupervised banner orders "generate work" and
  the plan named it nowhere — the one copy of the order outside the hook,
  left standing by a literal implementer. (fixed: scoped, anchored)
- r3: "Delete the wave-1 paragraph and ... stays" read as one instruction
  with two verbs. (fixed)

Round 2, verifier at opus, 16 findings:

- r4: (verifier) `qc_goal_reached` has THREE guarded callers, the plan named
  two; the top-level one fires in any tree with plans and no requirement —
  every consumer — and deleting `qc_mode` with it left under `set -u`
  aborts the hook in supervised too. (fixed: third arm named, variable
  goes last, `qc_mode` in the acceptance grep)
- r5: (verifier) acceptance grep hit the kept annotations — same as r1,
  read on the commit before r1's fix. (fixed in r1; annotations that name
  `./joharness.sh sources` are dated history, Traps say leave them)
- r6: (verifier) "459 lines" for `cmd_sources` reproduced from no command;
  `cmd_drain` 144 and `cmd_authority` 87 also off by a few. (fixed:
  459 = `cmd_sources` + `src_stop_condition` 4325-4783, detectors 105
  more; 140; 86 — command and date beside each)
- r7: (verifier) `feedback | grep -c 'counted since'` is 0 before the
  change — `feedback` never printed it, `sources` did. Green both ways.
  (fixed: bullet replaced by the surviving volume line and a
  `JOHARNESS_FEEDBACK_SINCE` no-op check)
- r8: (verifier) "62 of 155" carries no command and today's `feedback`
  says 266 / 50. (fixed: attributed to the requirement's PR 161 count,
  today's number beside it)
- r9: (verifier) `JOHARNESS_MODE=unsupervised ./joharness.sh ci` red on
  this branch — the plan names a requirement and no `advances:`. (fixed:
  `advances:` names the endurance bullet's surviving text; Traps say why)
- r10: (verifier) `queue-context-scope-waves.sh` has zero unsupervised
  cases; the plan told an implementer to cut some. (fixed: STAYS whole,
  named so; only `queue-context-fanout.sh` is cut, its count given)
- r11: (verifier) before/after `drain` diff not controlled — detached
  worktree changes the in-flight block, not the verdict. (fixed: compare
  from the verdict line down, reason stated)
- r12: (verifier) "same DRAINED line" would print "this repo is not in
  it" to an unsupervised session. (fixed: sub-lines supervised-only,
  unsupervised gets its one line)
- r13: (verifier) acceptance grep omitted ten names Scope deletes;
  `perf_count`'s `JOHARNESS_IN_SWEEP` export and comment not in Scope.
  (fixed: names added, `perf_count` scoped and anchored)
- r14: (verifier) deleting `drain.md` "Limits" whole drops "fleet
  outliving sessions is the heartbeat's job" and "stop when the human says
  stop". (fixed: those two lines stay)
- r15: (verifier) `review.sh` is edited by this plan and by
  `gate-review-verifier-tag`, which Out of scope called unrelated. (fixed:
  named as a wave split with a reconcile expected)
- r16: (verifier) the DRAINED acceptance is unreachable on this repo's
  tree — the requirement is unplanned again after the retire. (fixed:
  fixture stated, the selftest case named as the runnable form)
- r17: (verifier) README section has two subsections, not three. (fixed)
- r18: (verifier) `perf_rows` runs the queue-context row under
  `JOHARNESS_RUN_MODE=unsupervised`, a path that no longer differs after
  decision 3. (fixed: drop the prefix, budgets untouched)
- r19: (verifier) `## Review` read "None yet." — not the `- rN:` form.
  (fixed before this round landed; this section is the record)

## Blockers

Decision 4 needs human: PAT or GitHub App secret in repo. Without it,
heartbeat stays Routine at 1h floor and `cmd_authority` stays.

## Where to look

- `joharness.sh:cmd_sources` — with `src_stop_condition` 459 lines, largest
  unsupervised cost, goes with decision 1.
- `joharness.sh:cmd_drain` — 140 lines, rewrite to claim-one-exit.
- `joharness.sh:cmd_authority` — 86 lines, goes with decision 4.
- `.agents/harness/queue-context.sh:qc_scope_class` — wave partition
  marking, decision 3.
- `.agents/harness/queue-context.sh:qc_edge_unsupervised` — edge
  generation, decision 1.
- `.agents/harness/selftest/sources.sh` — with `drain.sh`,
  `queue-context-edge.sh`, `queue-context-fanout.sh`,
  `queue-context-supervised-only.sh`: the selftests decisions 1-3 delete
  or cut. `queue-context-scope-waves.sh` has no unsupervised case and
  stays.
- `.agents/docs/unsupervised.md` — heartbeat mechanism + GH Actions
  rejection; rewrite under decision 4.
- `docs/product/unsupervised-mode.md` — Constraints: "not invent work
  exception" and detector constraint; both vanish under decision 1.
- Sizes measured 2026-09-02, `main` 4cae61a, `wc -l`: `joharness.sh` 6019,
  selftests 10129 lines / 45 files, `queue-context.sh` 1016,
  `handover-context.sh` 787.
- Sources: https://github.com/andyrewlee/awesome-agent-orchestrators,
  https://platform.claude.com/docs/en/managed-agents/multi-agent,
  https://platform.claude.com/docs/en/agent-sdk/hosting
