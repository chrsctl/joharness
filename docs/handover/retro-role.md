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
next: ci and verify on round-2 fixes, then retire and open the pull request
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
- Loop note: the orchestrator writes `Looped, killed by the orchestrator` under `## Blockers`, not `## Review`; matched only as a line opening under `## Blockers` (verifier r20). Plan fixed.
- Candidates (human direction in session: run only for managers that did not come back or did not merge): `status: blocked` or `abandoned`, or a `## Blockers` line opening with the orchestrator's loop or silence kill note, on every `refs/remotes/origin/*` ref, read with one `git cat-file --batch`. No time window (verifier r21): the ledger's `session` column alone stops a re-sample. A stale-but-open PR with a live session is left to the orchestrator's STALL/KILL, whose note then qualifies.
- Sample order: sha1(<session URL>), as conduct's sha1(<stem>). Each row carries `<sha>:<workstream file>`, the file as that session left it (verifier r25).
- Output: `cmd_retro` prints the plan's literal `retro DUE: spawn ONE retro reviewer` / `retro : <state>`; dispatch pads `retro     :` as its other rows. `role_rows`/`role_start_stop` match both.
- Dispatch: retro is also suppressed while conduct spawns this pass or is in flight — one reviewer of either kind a pass.
- No workstream file for retro, as conduct: one word added to AGENTS.md's Handover exemption (scope widened; flag for human).
- Knobs: dispatch-scoped, in KNOBS and orchestrated.md's table; not in conf-keys.sh/bootstrap (consumers run on defaults).
- Title `🩺 retro: <UTC date>` (human direction in session: name kept `retro`, emoji like the other roles): glossary row and its pin in selftest/orchestrated.sh, scope widened. Ledger field `retroed=<stamp>`.

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
- r20: (verifier) the loop-note match counted any mention: this branch and orchestrate-diet-guards sampled while in-progress (fixed: a `## Blockers` line opening with the note)
- r21: (verifier) the since-landing window dropped sessions past the sample and those blocking during a run (fixed: no window, the ledger dedupe alone)
- r22: (verifier) `branch:` printed unvalidated into a row retro.md has pasted into Bash (fixed: plain ref names only, the row is data quoted in single quotes)
- r23: (verifier) multi-line `expect` made the order assertion vacuous (fixed: exact row comparison; mutation no-sort reds it)
- r24: (verifier) no test for conduct suppression, the pause hold, role retro GO, --twin (fixed: four cases, each mutation reds; in-flight drop window wontfix: shared shape with conduct, tested there)
- r25: (verifier) retro.md `<stem>` has no source; two sessions on one branch read the later file (fixed: the row carries `<sha>:<path>`)
- r26: (verifier) read list forbids plans README and the rule's file (fixed: both listed)
- r27: (verifier) rule-only bar named AGENTS.md only (fixed: any file; mechanism defined as something that runs)
- r28: (verifier) secondhand routing ambiguous (fixed: routes as any failure, Escape says secondhand)
- r29: (verifier) AGENTS.md one-word scope widening needs a human (no change: flagged in the PR body)
- r30: (verifier) last page overshoots the event cap; twin rule dropped "never both go on" (fixed)
- r31: (verifier) dry run found two of three Goal failures only secondhand (no change: recorded in r16; a failure nobody filed yet is the reviewer's real test)
- r32: human direction: sample only managers that did not come back clean; kill-for-silence and `abandoned` added (fixed)
- r33: (verifier) a header-shaped body line forged a row with an unvalidated `<sha>:<path>` field (fixed: cat-file framed by objectsize, key checked against `<hex>:docs/handover/<name>.md`; no-framing mutation reds)
- r34: (verifier) a respawned successor inherited the kill note and was sampled after a clean merge (fixed: a kill counts for the session the note first named)
- r35: (verifier) no test for the Blockers-only match, `..` branches, one row per session (fixed: three cases; each mutation reds)
- r36: (verifier) conduct spawning this pass untested; the twin clock check shared with conduct (fixed: a case; wontfix: the twin clock, conduct's branch, tested in role.sh)
- r37: (verifier) RETRO_KILL_NOTE pinned to nothing (fixed: both notes pinned to orchestrate-reference.md's text; a `- ` bullet accepted)
- r38: (verifier) "a clean merge never qualifies" reads wrong for a merged session that blocked once (fixed: wording names the rule)
- r39: (verifier) abandoned role claims (curate-<date>) sampled as managers (fixed: dated stems skipped, as conduct)
- r40: human direction: role title with an emoji, name kept `retro` (fixed: 🩺 retro)

## Blockers

None.

## Where to look

- `joharness.sh:conduct_due` — shape to copy.
