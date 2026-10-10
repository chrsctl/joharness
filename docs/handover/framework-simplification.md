---
workstream: framework-simplification
status: in-progress
branch: claude/framework-simplification
pr: none
plan: framework-simplification
issue: none
session: https://claude.ai/code/session_01L9iNPTvrJVyW4LvgqxyHn7
agent: opus
updated: 2026-10-10
next: ci + verify on head, retire, open PR, merge; then follow-up PR removing JOHARNESS_CHURN_LIMIT=0
---

## Goal

Human: "Simplify framework, remove unnecessary stuff." Measured usage on gx
and the live orchestrators first; plan lists what goes.

## Decisions

- Human chose full scope (dead code + doc trim + behavior) in one PR, allowed
  core-path edits (conf, .github), and paused the joharness orchestrator
  (triggers trig_0145ikh1mc8PfwtmBuQWanBM, trig_01Kq7h4j4qrqRu1vfqx5iP3W
  disabled 13:25Z; running managers allowed to finish). gx untouched.
- Two workers split by file ownership: code (joharness.sh, selftests,
  scripts, conf, .github, env, hooks) and text (.agents/docs, .claude,
  AGENTS.md, README).

- Role audit (gx clerk/janitor/curator 13:13Z, joharness janitor/curator):
  janitor becomes `janitor --apply` (no session; joharness run: 45 min, empty
  PR); curate repairs scripted + `ci` gate on plans a branch edits (gx clerk
  plan re-raised curate 0->10 within 2 min); clerk kept, slimmed, never
  writes core-only plans; role sessions count against the cap together.

- Human: verify roles before removing. Verification done (per-role track
  record); ALL role changes (janitor/curate/clerk/scout/analyst/upstream)
  decided by human: janitor->script, curate->script+ci gate, clerk kept slim,
  upstream-report kept manual (auto-spawn removed), analyst removed, scout KEPT. Workers told to keep any role commit
  separate. Proposal: janitor->script, curate->script+ci gate, clerk and
  upstream-report kept (slim), scout+analyst removed.

## Rejected

- Keeping `context`/`perf` as reporting-only: they run inside every `ci`
  and lengthen its output, which managers measurably mis-read.

## Review

- r1: (verifier) high — heredoc strip let a body bash actually runs past the guard: `tee f <<EOF | bash`, `cat <<EOF | bash` after any `>`, `/bin/bash <<EOF >log`, `bash --norc`, `2>/dev/null` counted as a write, a second heredoc's redirect exempting the first, write-then-run. Strip only `cat`/`tee`-led, pipe-free, real-write lines; strip nothing when the rest runs a shell or script; 8 deny cases added. (fixed)
- r2: (verifier) high — the README's prescribed `- r1: clean pass, …` line read unmarked, so a clean review turned ci red mid-build. fb_marker reads `clean pass` as no change; selftest asserts it. (fixed)
- r3: (verifier) core-only plan gate redded a human's own branch building its held core-path plan. Held plan exempt from that check too. (fixed)
- r4: (verifier) plan gate ran every curate repair on plans a branch merely edits, redding a surveyor for anchors it did not write. Gate now covers ADDED plans only. (fixed)
- r5: (verifier) quiet ci hid pass-with-report output (edge report, SHIPS, churn warning, shallow not-measurable, lint_warn). run_check prints a passing check whose output carries a report about this branch or checkout (incl. shallow-degraded graph reds); plain warnings about other plans stay quiet, as ci-output pins. (fixed)
- r6: (verifier) local finish hid "Not covered here" / SHALLOW. Same run_check fix. (fixed)
- r7: (verifier) orchestrator could respawn a gone manager and janitor-release its claim in one pass. janitor line skips branches respawned this pass. (fixed)
- r8: (verifier) "@new with item gone → done" dropped a live surveyor (`rescope-<key>` has no item file). Rule limited to plan/research/requirement entries. (fixed)
- r9: (verifier) AGENTS.md named a `janitor : DUE` line dispatch never prints and a bare `--apply` that dies. Reworded: prove gone, pass branches. (fixed)
- r10: (verifier) plan text still listed upstream/analysis as removed; bootstrap `--mode` now hard-failed. Plan text matches the human's decision; `--mode` warns and is ignored again. (fixed)
- r11: churn ceiling — joharness.sh in 10 commits on this branch. Deliberate large rework, not patch churn: JOHARNESS_CHURN_LIMIT=0 in joharness.conf for this PR only, removed by a follow-up PR right after merge. (wontfix: the gate's own documented override)

## Blockers

None.

## Where to look

- `docs/plans/framework-simplification.md` — measured evidence and scope.
