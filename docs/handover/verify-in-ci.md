---
workstream: verify-in-ci
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: verify-in-ci
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Check does-it-reproduce lens against these fixes, then finish
---

## Goal

Requirement `docs/product/verify-in-ci.md` arrived unplanned (landed mid-session
from PR 82) and planning outranks the plan queue. Decomposed into
`docs/plans/verify-in-ci.md`, executed here. Requirement's only plan, so the
PR retires the requirement file too.

## Decisions

- Discovery by per-layer MARKER FILE, not a layer name in the workflow. The
  requirement left the mechanism to this session. Decisive argument:
  `ci.yml` is seeded verbatim into every consumer, so a layer name there
  becomes a job every consumer on another layer runs meaninglessly. A marker
  in the layer's own directory also keeps the contract's "nothing outside the
  layer may name it" intact — no carve-out needed.
- Registry unreachable or rate-limited = warn and pass, not red. Straight
  from the requirement's constraint ("a flaky red gate is worse than no
  gate"). A real check failure stays red; only the precondition is soft.
- No Docker Hub login: fork pull requests get no secrets, so a login-based
  gate would be exactly the sometimes-red gate the requirement rejects.

## Rejected

- Hardcoding the layer in `ci.yml` (simplest): breaks every consumer that
  selects another layer, and puts a layer name in a file the layer rule
  exists to keep clean.
- Marking `python-rust` too: its setup downloads a toolchain rather than
  starting an already-present daemon, so it is a different claim needing its
  own measurement. The marker design lets it opt in later.

## Review

Opus tier = adversarial, separate lenses; all three run 2026-08-28.
Correctness and doctrine converged independently on r1, r3, r5, r6 —
agreement across lenses, not one reviewer's hobby-horse. Seventeen findings;
the diff that went in is substantially not the diff that was reviewed.

- r1: the soft-pass made step 7 FALSE. Registry rate-limited = verify step
  skipped = job green, while step 7 said "the checks already did" — so a
  session skips its own verify and unverified harness code merges. The one
  place this diff WEAKENED a merge condition. (fixed: step 7 now says read
  the run, never infer from the marker; the skip prints "VERIFY SKIPPED ...
  proves NOTHING"; `ci.yml`'s own comment says a skipped layer is a green
  tick over an unproven layer)
- r2: every EXISTING consumer would have got the marker and the rescoped
  step-7 prose but never the job — `.agents/env/<selected>/` and
  `.agents/harness/` sync, `ci.yml` does not (consumer-own, seeded once by
  bootstrap). Same false rule, for every repo bootstrapped before today.
  (fixed: consumer-repos.md names the seeding gap in as many words)
- r3: "`ci` is the whole of what GitHub checks" became false in FOUR places
  (root AGENTS.md, harness AGENTS.md step 5, the ci.yml lint comment,
  joharness.sh) — a session would get green `ci`, a red PR, and be told to
  hunt a split bug that does not exist. (fixed: all four)
- r4: joharness.sh still asserted CI cannot run the smoke test, though the
  requirement named that file explicitly. My acceptance grep (`"CI cannot"`
  under AGENTS.md and .agents/) could not match the paraphrase. Lesson: an
  acceptance grep for a CLAIM must search for the claim's meaning, not one
  phrasing of it. (fixed: both paraphrases)
- r5: `ci.yml` hardcoded this layer's images — layer data in the file whose
  whole premise is layer-agnosticism. A second declaring layer got no
  pre-pull (hard red on the rate limit this exists to absorb), and one
  layer's registry failure suppressed every layer's verify. (fixed: `image:`
  lines are data in the layer's own marker, pulled and skipped per layer)
- r6: marker + non-executable smoke-test.sh was silently skipped, printing
  "nothing to verify" while a layer HAD declared — CI looser than
  `cmd_verify`, which keeps exactly that case fatal. (fixed: red. Scenario B
  exit 1)
- r7: discovery accepted names the entrypoint rejects. A layer dir
  `Ubuntu24` with a marker: `JOHARNESS_ENV` ignored, verify fell back to the
  empty layer, job GREEN claiming it verified. (fixed: same `valid_name`
  rule as joharness.sh, in the workflow. Scenario C exit 1)
- r8: the first failing layer aborted the loop, hiding the others' status.
  (fixed: every declaring layer runs, failures aggregate, exit 1 names them.
  Scenario E: both layers ran, exit 1)
- r9: the marker's promise list omitted that the smoke test fetches from
  raw.githubusercontent.com — an outage there reds the gate and the `image:`
  softening cannot reach it. (fixed as recorded, not silenced: the marker
  names it as a known soft spot. Changing what a smoke test checks is this
  plan's explicit out-of-scope; softening it is the layer's own work)
- r10: a green check named `verify` on a consumer that verified nothing is
  claim-shaped for a human scanning the checks list. (fixed: renamed
  `verify-declared-layers`)
- r11: `${{ steps.layers.outputs.names }}` interpolated into `run:` — no
  privilege escalation, but it broke on any layer name with a space.
  (fixed: one bash step, no interpolation anywhere)
- r12: clean on both lenses — layer rule intact in letter and spirit (no
  file outside a layer names one, no new carve-out); the marker reaches a
  consumer via the selected layer's directory; every requirement bullet
  about not overclaiming is stated in three places; caveman style holds.

- r13: (reproduce) all eight claims reproduced against the reviewed commit —
  layer verify green, `ci` green, discovery both ways, YAML parses, selection
  unchanged, the gate genuinely red on a failing layer, k8s untouched at 8
  checks. No claim of mine was refuted on the measurements themselves.
- r14: (reproduce) the retry slept AFTER the final attempt — 60s of dead
  wall-clock per unreachable image — and printed "retrying" before not
  retrying. (fixed: the attempt cap is checked before the sleep, so the
  message only appears when a retry actually follows)
- r15: (reproduce) NOTHING tested the gate's shell. `ci` stayed green through
  any regression in it, and r6 and r7 were both instances of exactly that.
  Fixed structurally, not locally: the logic moved out of the YAML block into
  `.agents/scripts/ci-verify-layers.sh`, where `ci` shellchecks it with every
  other harness script and `selftest.sh` drives it against fixture trees —
  13 cases covering every finding above (no declarer, green layer, missing
  exec bit, name the entrypoint rejects, registry down, one-of-two red).
  Shell in a workflow is shell nothing lints and nothing tests; that is what
  let the hole exist.
- r16: my own selftest block then tripped the layer rule — the registry
  client's name is also a layer's name, and `.agents/harness/` may write no
  layer name. `ci` caught it, I did not. (fixed: the script takes a
  `CI_VERIFY_PULL_BIN` hook and the test stubs through it, so no layer name
  is written and no second carve-out is needed)
- r17: SECOND SCOPE EXTENSION, decided alone, flagged: the plan's scope named
  neither `.agents/scripts/` nor `.agents/harness/selftest.sh`. r15 cannot be
  fixed inside the declared scope — the untested shell IS the workflow file.
  Leaving it would ship a merge gate with zero coverage.

Scenarios A-E were run against the workflow's real step, extracted from
`ci.yml` and executed with a stub registry: no marker (green, says so),
non-executable (red), invalid name (red), registry down (green, SKIPPED
loud), first-of-two layers red (both ran, red naming it).

## Blockers

None.

## Where to look

- `.agents/env/README.md:Contract` — the layer file contract the marker joins.
- `joharness.sh:cmd_verify` — `JOHARNESS_ENV` overrides the selected layer.
