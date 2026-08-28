---
workstream: env-docker-default
status: review
branch: claude/minify-optimize-workflow-kcq2r3
pr: none
plan: env-docker-default
session: https://claude.ai/code/session_014ojqiTtBebzJWwiVSApHTe
agent: opus
updated: 2026-08-28
next: Retire the plan and this file, open the pull request
---

## Goal

Human: "Instead of using k8s for this env can we use a faster environment",
then chose this as its own change after PR 111 merged rather than folded into
it. Select `docker` instead of `k8s`, and fix the one instruction that the
switch makes false.

## Decisions

- **Speed is the smaller half of the case, and the raw comparison is not
  lopsided.** Counted here 2026-08-28: k8s cold 49s / warm 7s / 8 checks;
  docker 4-9s depending on whether dockerd is already up / 6 checks. WARM,
  k8s is faster. The whole difference is one cluster creation per session.
- **The reason that decides it is `ci-verify`.** `docker` carries the marker,
  `k8s` cannot. GitHub's `verify-declared-layers` job already runs docker's
  smoke test on every pull request — read from PR 111's job log, 6 passed,
  ~4s. Step 7 says `verify` is the session's to run "unless THIS head's
  checks actually verified the selected layer: read the run". With k8s
  selected that clause was permanently dead here; with docker it is
  reachable.
- **The second reason is flakiness, not speed.** `.agents/env/k8s/AGENTS.md`
  says a first verify after a cold `cluster-up` can fail and that the failures
  MOVE between runs. A gate that reddens for reasons unrelated to the diff
  teaches sessions to re-run reds — the habit every other rule here fights.
- **The layer is deselected, not retired.** Canonical carries every layer by
  contract. `.agents/env/k8s/` is untouched, still linted by `ci`, and still
  one command away — proven, not assumed: `JOHARNESS_ENV=k8s ./joharness.sh
  verify` = 8 passed after the switch.
- **`./joharness.sh env docker`, never a hand edit of the conf.** The
  entrypoint validates the name; canonical refuses an unknown one.

## Rejected

- **`none`.** Fastest possible and buys it by removing the check. A layer that
  verifies nothing makes `verify` a no-op that still appears in step 7.
- **`python-rust`.** No `ci-verify` marker either, so it loses the reason that
  decides this, and installs a toolchain this repo does not use.
- **Adding `ci-verify` to `k8s`.** It needs Docker-in-Docker, the egress proxy
  and a cgroup v1 kernel. The marker would claim something a stock runner
  cannot honour, and `.agents/env/README.md` says such a layer leaves it out.
- **Deleting the sandbox sentence from AGENTS.md without replacing it.** It
  would have left a session knowing the old rule was gone and not what
  replaced it. The block now states the positive — the read-the-run clause is
  reachable here — and keeps the warning that a SKIPPED layer is a green tick
  over nothing.

## Review

Opus tier (escalated from the plan's sonnet), adversarial, three lenses.

- r1 (checked, no change): grepped every `*.md` for another claim that this
  repo's layer is k8s or needs the sandbox. AGENTS.md carried the only one.
  The remaining mentions are the `selftest-split` plan talking about the
  carve-out FILE (still correct — the carve-out is about which layer a harness
  file may name, not which layer is selected), an example line in
  `.agents/env/README.md`, and `dl.k8s.io`/`registry.k8s.io` hostnames in the
  docker layer's own README. Nothing else went stale.
- r2 (fixed): first draft of the AGENTS.md edit removed the false sentence and
  stopped there. Deleting a claim is not the same as replacing the guidance —
  see Rejected. Rewritten to say what a session should now do.
- r3 (accepted): the perf counts moved — `session-start` 591 here against
  595-608 on the previous branch. Cause is repo state plus the hook reading a
  different layer's pointer, not a regression; all five stay inside budget.
  This is the drift class the perf workstream recorded as its own r9, showing
  up on the first branch after it merged, which is the expected behaviour and
  not a new finding.
- r4 (checked, no change): the structure test that `.agents/harness/` names no
  environment layer stays green, and the carve-out is still exactly one.
  Nothing in this diff goes near `.agents/harness/`.

Green: `./joharness.sh ci` = `ci: pass`. `./joharness.sh verify` = 6 passed,
0 failed — docker's count, which is the acceptance check that the switch took
(reading 8 would have meant it did not).

## Blockers

None.

## Where to look

- `joharness.conf` — one line, per-repo, NOT synced to consumers.
- `AGENTS.md` — the verify block; the sentence that had to change with the
  selection.
- `.agents/env/README.md` — the `ci-verify` contract and why k8s cannot carry
  the marker.
