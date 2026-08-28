---
workstream: smoke-helm-coverage
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: smoke-helm-coverage
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Finish — delete plan + workstream, PR, merge
---

## Goal

Plan `docs/plans/smoke-helm-coverage.md`: environment installs helm, smoke
suite never exercises it — only manual checks ever did (2026-08-21). Close
the gap so the suite covers every tool the environment installs.

## Decisions

- Session runs opus, plan wants sonnet: escalation, allowed. Review depth
  follows the SESSION tier — adversarial, separate lenses
  (`.agents/docs/agent-selection.md`).
- Branch restarts from origin/main again (PR #90 merged).
- Real install over `--dry-run` (plan allowed either): renders, rolls out to
  Ready, uninstalls — proves the release lifecycle, not just templating.
  `image.tag=alpine` reuses the image check 6 already pulled, so the check
  measures helm and not the registry twice.
- Check proven to fail, not just pass: same script with a bad image tag
  reports FAIL, `7 passed, 1 failed`, exit 1, and prints `STATUS: failed`.
- Best-effort `helm uninstall --ignore-not-found` before install: NOT for a
  `--keep` run (this check uninstalls before cleanup sees `--keep` — review
  r2 measured that and killed the original rationale), but for a previous
  run that failed or was interrupted, stranding the release in `failed` or
  `pending-install`. Both states measured as recovered. Matches the
  `|| true` re-run idiom the namespace and deployment steps already use.
- SCOPE EXTENSION, decided alone, flagged for human: seven OTHER plan files
  wrote `verify — 7 passed, 0 failed` as acceptance for unrelated work. This
  branch moves that count, so each would have shipped stale. Rewritten
  count-neutral ("all checks pass, 0 failed") — same requirement, immune to
  the next count change. Intent preserved, no plan's meaning altered. This
  is the PR85 r4 failure (a moved count orphaning another plan's bullet)
  caught before merge rather than after.

## Rejected

- Public chart repo (bitnami etc.): plan's Out of scope — egress allowlist
  has no chart repos, adds network flake to a deterministic suite.
- Rewriting the cold-verify story's `7/7` to `8/8` in env AGENTS.md: that is
  a past measurement, not a current total. Falsifying it to match today's
  count is worse than the confusion it fixes; marked "the suite was 7 checks
  then" instead.
- Fixing the suite's re-run brittleness generally: pre-existing, belongs to
  plan `smoke-rerun-safety`. Measured on origin/main's own script — a re-run
  over a KEPT namespace fails 2 checks (5 and 7) on main and the same 2 here,
  helm passing both times. Back-to-back without `--keep` is a different,
  already-red scenario: the namespace is still `Terminating` (cleanup deletes
  with `--wait=false`, untouched by this diff) and check 8 becomes one more
  red — see review r7, recorded rather than papered over.

## Review

Opus tier = adversarial, separate lenses (`./joharness.sh review` prints the
recipe). All three run 2026-08-28: correctness, security, does-it-reproduce.
The third re-measured the other two's claims and corrected this file twice
(r6, r7) — which is the argument for separate lenses.

- r1: (correctness) `CHART_ROOT="$(mktemp -d)"` unguarded under `set -e` —
  the only check in the file that turns a broken tool into a bare abort
  instead of a counted FAIL. `TMPDIR=/nonexistent` killed the run after
  check 7 with NO summary line and no counted failure, contradicting the
  header's "one line per counted check". (fixed: `elif ! CHART_ROOT=...`
  counts it; re-measured `7 passed, 1 failed`, exit 1)
- r2: (correctness) comment and this file both claimed the pre-install
  uninstall covers a `--keep` leftover; measured false — check 8 uninstalls
  before cleanup ever sees `--keep`, so `helm list --all` is empty after a
  kept run. The guard is still load bearing, for a previous FAILED or
  INTERRUPTED run (`failed` / `pending-install`, both measured recovered).
  (fixed: rationale corrected in both places — a right guard for a wrong
  stated reason is a comment that will be deleted by the next reader)
- r3: (correctness, minor) on a fast re-run the namespace is `Terminating`,
  and check 8's diagnostic pointed at `helm status` — fingering helm when
  helm was never the cause. (fixed: message names namespace state first)
- r4: (security) clean pass. Verified: `rm -rf "$CHART_ROOT"` cannot turn
  destructive (initialized before the trap installs, so `set -u` cannot
  fire; quoted, `-n` guarded, only ever a fresh 0700 `mktemp -d`); no
  injection from `SMOKE_NAMESPACE`/`SMOKE_HELM_RELEASE`/`DEVENV_CLUSTER_NAME`
  (argv only, no eval, fixed printf format); nothing cluster-scoped created;
  no new network fetch (no repo configured, `helm create` is offline, only
  image is check 6's `nginx:alpine`); scaffolded `busybox` test pod is
  `helm.sh/hook: test` and never runs here.
- r5: (correctness) recorded because the negative result is the finding:
  the `h status | grep -q` pipeline under `pipefail` was the prime
  false-red candidate; 200 consecutive runs gave 0 nonzero results (615-byte
  single write, no SIGPIPE race). Not reachable, left as is.
- r6: (does-it-reproduce) this file claimed "3 checks fail on origin/main's
  re-run over a kept namespace"; independently measured 2, stably, twice —
  the 3 came from a back-to-back run and was attributed to the `--keep` one.
  A written number wrong in the file whose own rule is "trust counted
  numbers". (fixed: corrected to 2, with the scenario it belongs to)
- r7: (does-it-reproduce) "re-run brittleness not introduced by this diff"
  holds for `--keep` (helm passes; same 2 checks fail on both arms) but NOT
  back-to-back: there the namespace is `Terminating` and check 8 adds a
  fourth red (main `5 passed, 2 failed`, this diff `4 passed, 4 failed`).
  (fixed as recorded, no code change: the run is already red, the cause is
  pre-existing `--wait=false` cleanup owned by `smoke-rerun-safety`, and the
  extra FAIL is honest — helm truly cannot install into a dying namespace.
  r3 already stopped it from blaming helm. Narrowing the claim beats
  widening the diff into another plan's scope.)
- r8: (does-it-reproduce) this branch's OWN plan file still says
  `.agents/env/k8s/AGENTS.md` holds `7 passed, 0 failed` — false at HEAD.
  The seven-file sweep was accurate but this eighth occurrence went
  unremarked. (fixed by the finish commit, which deletes the plan file)

## Blockers

None.

## Where to look

- `.agents/env/k8s/smoke-test.sh` — header check list, PASS/FAIL counters,
  summary line, cleanup trap.
- `.agents/env/k8s/AGENTS.md` — written pass total moves with the count.
