---
workstream: k8s-136-validation
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: k8s-136-validation
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: Edge review, then finish (delete plan + workstream, PR, merge)
---

## Goal

Plan `docs/plans/k8s-136-validation.md`: v1.36.3-k3s1 measured Ready on this
cgroup v1 host (2026-08-21) but only node Ready — pod creation and smoke
suite unmeasured. Decide bump vs stay on v1.35.7, evidence either way.

## Decisions

- Branch reuses claude/backpass-usage-review-sbew6t (prior PR #89 merged;
  platform rule: same branch restarts from origin/main for follow-up work).
- Verdict: BUMP. v1.36.3-k3s1 on this cgroup v1 host, same failCgroupV1
  drop-in: full smoke suite 7 passed 0 failed (2026-08-28), server reports
  v1.36.3+k3s1. Cold-path proof: cluster-down then verify under the new
  default pin, 7/7 first run (known cold-verify flake did not fire).
- kubectl v1.36.4 = dl.k8s.io stable-1.36.txt; sha256 from publisher's
  kubectl.sha256, proven by fresh install (verify_download dies on
  mismatch). Skew server v1.36.3 / client v1.36.4 within ±1 minor.

## Rejected

(none yet — plan's Out of scope carries the dead branch's measured
rejections: fail-cgroup-v1 flag does not exist, drop-in removal fatal)

## Review

/code-review high, full branch diff vs main, 2026-08-28. Reviewer
independently re-fetched the publisher kubectl.sha256 (matches pin),
audited removed caveats for surviving invariants, checked pin/README/
smoke-count consistency — all clean. One finding:

- r1: `.agents/env/k8s/AGENTS.md` trip-wire still said the drop-in "lets
  pinned v1.35 run" while the diff pins v1.36.3 — session-injected rules
  describing a pin that no longer exists invites a future session to
  "correct" the bump. (fixed: wording version-neutral, "lets the pinned
  version run")

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh` — K3S_IMAGE/KUBECTL_VERSION pins,
  render_kubelet_dropin.
- `.agents/env/k8s/README.md` — constraint 2 = current measured story.
