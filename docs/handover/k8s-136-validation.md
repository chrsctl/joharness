---
workstream: k8s-136-validation
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: k8s-136-validation
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: Provision env, run v1.36.3-k3s1 cluster-up + full smoke suite, record verdict
---

## Goal

Plan `docs/plans/k8s-136-validation.md`: v1.36.3-k3s1 measured Ready on this
cgroup v1 host (2026-08-21) but only node Ready — pod creation and smoke
suite unmeasured. Decide bump vs stay on v1.35.7, evidence either way.

## Decisions

- Branch reuses claude/backpass-usage-review-sbew6t (prior PR #89 merged;
  platform rule: same branch restarts from origin/main for follow-up work).

## Rejected

(none yet — plan's Out of scope carries the dead branch's measured
rejections: fail-cgroup-v1 flag does not exist, drop-in removal fatal)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh` — K3S_IMAGE/KUBECTL_VERSION pins,
  render_kubelet_dropin.
- `.agents/env/k8s/README.md` — constraint 2 = current measured story.
