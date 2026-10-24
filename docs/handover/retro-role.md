---
workstream: retro-role
status: in-progress
branch: manage/retro-role
pr: none
plan: retro-role
issue: none
session: https://claude.ai/code/session_01Lcrz8PYtM5Xk7gcHyMkGGH
agent: opus
updated: 2026-10-24
next: Run ci and verify, fix reds, then the verifier at opus
---

## Goal

A retro reviewer role: reads transcripts of managers that ended badly
(blocked, or a loop note), traces each failure to the check that should have
caught it, files plans preferring a mechanism over a rule. Never fixes.

## Decisions

- A1: confirmed — `list_events` on session_01GjKnsgJV4qubTD63CuMiH7 returned its events from this session.
- A2: confirmed — `.claude/settings.json` holds no `permissions` key; this manager called `list_events` with no prompt.
- A3: confirmed — TEMPLATE.md `session: https://claude.ai/code/session_...`; the candidate scan skips that placeholder.
- A4: confirmed — retro reuses `conduct_sha1`, `cycle_unreadable`, `cycle_repo_age_h` and copies the rest; conduct's code unchanged.
- Loop note: the orchestrator writes `Looped, killed by the orchestrator` under `## Blockers`, not `## Review`; matched anywhere outside the frontmatter. Plan fixed.
- Candidate window: workstream commits with committer time after the ledger's first-parent landing, on every `refs/remotes/origin/*` ref (merged or not), read with one `git cat-file --batch`. Dedupe by session URL; the ledger carries a `session` column so a re-sampled session is skipped.
- Sample order: sha1(<session URL>), as conduct's sha1(<stem>).
- Output: `cmd_retro` prints the plan's literal `retro DUE: spawn ONE retro reviewer` / `retro : <state>`; dispatch pads `retro     :` as its other rows. `role_rows`/`role_start_stop` match both.
- Dispatch: retro is also suppressed while conduct spawns this pass or is in flight — one reviewer of either kind a pass.
- No workstream file for retro, as conduct: one word added to AGENTS.md's Handover exemption (scope widened; flag for human).
- Knobs: dispatch-scoped, in KNOBS and orchestrated.md's table; not in conf-keys.sh/bootstrap (consumers run on defaults).
- Title `retro: <UTC date>`, no emoji, as scout's: the glossary row is pinned by selftest/orchestrated.sh, outside scope. Ledger field `retroed=<stamp>`.

## Rejected

- Reading the transcript tail-first with a 200-event cap: the dry run missed the early failures, so retro.md takes them secondhand from the workstream file and the plans that name the branch.

## Review

- r1: (plan-checker) dispatch acceptance passes before the build (plan's own branch row matches `retro`) (fixed: acceptance names `retro     :`)
- r2: (plan-checker) loop note lives under `## Blockers`, not `## Review` (fixed: plan and scan)
- r3: (plan-checker) a role with no workstream file breaks AGENTS.md's Handover exemption list (fixed: one word added, scope widened)
- r4: (plan-checker) ledger outcome cannot name a plan stem (fixed: `refs: <#n or plan stem>`)
- r5: (plan-checker) dry run undefined; Refs vs rule-broken order unstated (fixed: dry run = §2–§3 only; Refs checked first)
- r6: (plan-checker) "plan-only pull request" contradicts the ledger rows (fixed: plans plus `docs/retro-log.md`)
- r7: (plan-checker) orchestrate-reference.md spawn table not in scope (fixed)
- r8: (plan-checker) glossary role-title registry not in scope (fixed: emoji-less title as scout's, glossary untouched)
- r9: (plan-checker) knob registries: orchestrated.md table not asked; conf-keys.sh, bootstrap absent (fixed: table rows; wontfix: conf-keys.sh and bootstrap, dispatch-scoped defaults apply)
- r10: (plan-checker) selftest/role.sh role list not in scope (fixed)
- r11: (plan-checker) output shapes unpinned (fixed: every state line named in the plan)
- r12: (plan-checker) A2 had readable evidence (fixed)
- r13: (plan-checker) acceptance lines state no failure (fixed: each names its failure)
- r14: (plan-checker) dry run cost and PR fate unstated (fixed: read-only, no ledger, no PR)
- r15: (plan-checker) new topic against the fixed git-exec budget (no change: measured by ci below)
- r16: dry run (sonnet, 195 events): F1 missed FAIL line in window, refs ci-red-legible; F2 edit under ci and F3 pkill self-kill outside the window, secondhand from plan Goals, refs ci-red-legible and guard-one-shot-self-kill; F4 refs selftest-git-budget-per-case, #603. All three Goal failures named, three plans Refs'd, no new plan (no change)
- r17: dry run: page of 100 overruns tool output; `git show` of the retire commit fails; out-of-window failures need a rule (fixed: retro.md limit 30, `$sha^`, secondhand rule)
- r18: selftest second alpha commit was a no-op, so the ledger-dedupe refute passed vacuously (fixed: distinct body)
- r19: shellcheck SC1010 on the fixture's bare `done` argument (fixed: quoted)

## Blockers

None.

## Where to look

- `joharness.sh:conduct_due` — shape to copy.
