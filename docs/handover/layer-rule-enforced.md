---
workstream: layer-rule-enforced
status: review
branch: claude/layer-rule-enforced
pr: none
plan: layer-rule-enforced
session: https://claude.ai/code/session_013gbMpgGTeYzxsBa7RfW4ch
agent: opus
updated: 2026-08-25
next: Merge PR 76 then the graph PR (this branch is stacked on both), then delete this file and the plan file, open the pull request and merge per Loop step 7
---

## Goal

`docs/plans/layer-rule-enforced.md`. Three files stated the layering rule as
an absolute; `selftest.sh` broke it six times, deliberately, with the reason
in a code comment; nothing checked it. Tier escalated sonnet → opus.

## Decisions

- **The rule was wrong, not just unenforced, and the check found out why.**
  `none` appears in four harness files — `handover-context.sh`,
  `queue-context.sh`, `AGENTS.md`, `selftest.sh` — every one of them
  legitimately. It is not an environment; it is the harness's own word for
  having none, returned by `resolve_env`. So the honest rule has two
  exemptions, and only one of them is an exception: `none` by definition,
  and the k8s regression test by carve-out. Stating "must never" was never
  true of this repo and could not have been.
- **The carve-out is spelled once, in the check.** `LAYER_CARVE_OUT_FILE` /
  `LAYER_CARVE_OUT_NAME` in `selftest.sh`. The three prose statements now
  point at it rather than each re-spelling which file and which layer — the
  drift that produced this finding is the same drift three copies would
  produce again.
- **The scan takes its roots as arguments.** That is what makes the fixture
  possible, and the fixture is the point: a structural check only ever run
  against a clean tree is a check nobody has tested.
- **The k8s test stays exactly where it is.** The plan's Out of scope, and
  worth repeating here: it guards a hostile cluster name executing when the
  env file is sourced, and a layer's own `smoke-test.sh` needs the sandbox
  CI does not have.

## Rejected

- **A general "no cross-layer reference" lint.** Would forbid the harness
  naming `.agents/env/README.md`, which ships and must be referenced. The
  rule is about layer NAMES; the plan's Traps called this exact widening.
- **Exempting `selftest.sh` wholesale** because it is canonical-only and
  never ships. Then "selftest.sh may name anything" passes, and the file that
  drew the finding becomes the one file the rule cannot see. The carve-out is
  one file for one layer, and there is a case proving the second half.

## Review

- r1: **the check failed the real tree on its first run — because of the
  fixture I had just written.** The planted violation used `docker`, a live
  layer name, inside `selftest.sh`. The scan is parameterised, so the fixture
  never needed a real name; it now invents `zzfixture`. Test data naming a
  layer is precisely the coupling being forbidden, and it would have been the
  only violation left in the repo. (fixed)
- r2: the rewrite of that comment was the second violation — a sentence
  naming the layer in order to explain that the layer must not be named still
  names it. Reworded to describe rather than name. Recorded because it is the
  clearest evidence the check is worth having: two violations in code written
  by someone actively thinking about the rule. (fixed)
- r3: `none` was going to be a false positive on four harness files. Checked
  which layer names actually appear before writing the scan, rather than
  discovering it from a red run — `docker` and `python-rust` are clean, `k8s`
  is the carve-out, `none` is everywhere and legitimate. That measurement is
  what turned the rule from "must never" into the two-exemption form. (fixed)
- r4: the fixture proves each arm separately — clean file silent, `none`
  silent, planted layer caught, and the carve-out file still caught for a
  layer that is not its own. Without the last, a blanket exemption passes.
  (fixed)
- r5: **CI caught a defect in the sibling branch's tests that this machine
  could not.** Windows: `chmod -x` does not stick on NTFS under Git Bash, so
  `verify`'s non-executable case asserted against a state that was never
  built. My test, not the code — I had guarded the executable case and left
  its mirror unguarded. The repo already had the idiom twice; matched it.
  Fixed on `claude/verify-none-layer` and merged up this stack. (fixed)
- r6: read `feedback .agents/harness/selftest.sh` (10 edges) before touching
  it, per step 5. PR54 r5 (fixture shellcheck stub) still holds — this check
  reads no shellcheck output. PR72 r7 (suite isolation) is why the fixture
  writes under `$TMP` and never the real tree. (no change needed)
- r7: stacked on two branches because all three plans conflict on
  `joharness.sh` / `selftest.sh` — the queue's wave analysis puts them in
  waves 10, 9 and 12 for that reason. Merge order: 76, then graph, then this.
  (no change needed — deliberate)

## Blockers

None. Ordering only.

## Where to look

- `.agents/harness/selftest.sh`, `layer_rule_scan` and
  `step "structure: .agents/harness/ names no environment layer"` — the check,
  the single carve-out declaration, and the fixture that proves each arm.
- `.agents/harness/README.md`, `.agents/env/README.md`, root `AGENTS.md` —
  the three statements, now agreeing with the check and pointing at it rather
  than re-spelling it.
