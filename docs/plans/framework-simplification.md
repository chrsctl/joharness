---
plan: framework-simplification
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, joharness.conf, .github, .agents, .claude, AGENTS.md, README.md, docs/plans, docs/research
---

## Goal

Human ask (2026-10-10): "Simplify framework, remove unnecessary stuff. For
active usage / measurements check gx and current running orchestrator."
Measured the same day on both live orchestrators (gx, joharness) and six
finished managers. Callers in practice: orchestrators run `dispatch` (and
`authority`, constant verdict) and nothing else; managers run `ci`,
`finish`, `review`, `verify`, `feedback`, `protocol-paths`. Neither repo ever
ran `upstream`, `analysis`, `graph`, `scorecard`, `mutate`, `perf`,
`context` (bar one plan using `context` as its own metric), `upgrade`; both
leave their conf keys at default. Every joharness merge this week was the
harness patching itself. Remove what nobody uses, cut narrative from the
text sessions load, and fix the measured ceremony costs.

## Scope

Dead code (remove with selftests, commands, docs, conf keys, conf-keys.sh
rows, glossary/lint references):
- subcommands `graph`, `scorecard`, `mutate`, `perf`, `context`; conf keys
  `PERF_BUDGET_*`.
- roles (human decision after a per-role track-record check): janitor and
  curate repairs become `janitor --apply` / `curate --apply`; `/analyst` and
  `JOHARNESS_IDLE_ANALYSIS` removed (`analysis` stays a by-hand read);
  `/upstream-report` kept as a manual procedure, its auto-spawn
  (`JOHARNESS_UPSTREAM_FEEDBACK`) removed; clerk slimmed; scout kept.
- `upgrade` kept: the consumer's fallback when `update.yml` cannot sync.
- env layer `.agents/env/python-rust` (selected by no repo).
- obsolete `JOHARNESS_MODE` block in `joharness.conf` and `mode_*` code.

Text:
- `.agents/docs/orchestrated.md`: drop Runs, history, reading list, and the
  why-by-step that repeats `orchestrate.md`.
- `.claude/commands/orchestrate.md`: operative rules only.
- history narrative in other `.agents/docs/*.md`; incident-history comments
  in `joharness.sh` (keep one line of why where a rule needs it).

Behavior:
- Stop hook: no background-process nag (cost 10/10 orchestrator passes,
  stranded one gx manager).
- Workstream finding format (`- rN:` + verdict) checked by `ci` mid-build
  whenever a `## Review` exists, not first after the retire commit (red hit
  3 of 5 finished managers).
- `ci` / `finish` print failures and one verdict line; detail on request.
- orchestrator: no per-pass `authority`; ledger keeps in-flight items only.

## Out of scope

- `dispatch`, `finish`, `review`, `feedback`, `clerk`, `curate`, `janitor`,
  `scout` semantics beyond output trimming.
- k8s/docker layers' provisioning.
- Any gx change (gx picks this up by its normal sync).

## Acceptance

```bash
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

## Where to look

- `joharness.sh:main` — subcommand dispatch case.
- `.agents/scripts/conf-keys.sh` — key list sync and bootstrap read.
- `.agents/harness/handover-guard.sh` — Stop hook.

## Traps

- NEVER skip, disable or quarantine a test to get green — delete a test only
  with the feature it tests.
