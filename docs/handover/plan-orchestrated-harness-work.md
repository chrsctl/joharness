---
workstream: plan-orchestrated-harness-work
status: in-progress
branch: claude/plan-orchestrated-harness-work
pr: none
plan: none
issue: 311
session: https://claude.ai/code/session_013Bg636JRhWFWgWW26RWefB
agent: opus
updated: 2026-10-08
next: Retire workstream file, PR, merge
---

## Goal

Requester, 2026-10-08: "Joharness should be able to be developed in
orchestrator mode which is forbidden, we need roles which convert issues to
docs/plans etc". Then: "We want to remove most restrictions. Joharness
should be able to use its own framework. Only orchestrator mode should be
left over." Decompose into plans; this branch writes plans only.

## Decisions

- Session ran attended (`JOHARNESS_MODE=supervised` exported): a human gave
  the ask in this session. Plans are not protocol paths either way.
- Requester answered in session (2026-10-08): orchestrated only,
  EVERYWHERE (consumers too, no fail-closed default); kept bounds = step 7
  merge gate + core paths `joharness.conf`, `.claude/settings.json`.
  Everything else released, incl. self-merge of protocol text and the
  requirement-writing ban.
- Four plans, a chain: protocol-boundary-core-only (supervised, last one
  that needs a human) -> orchestrated-only -> orchestrated-only-docs;
  issue-triager-role needs orchestrated-only (no drain/start routing).
- Superseded and deleted queued plans drop-unsupervised and
  drop-unsupervised-docs (kept supervised; requester now drops it). Their
  file lists were reused.

## Rejected

- Human merges protocol PRs (first draft, protocol-work-human-merge):
  requester chose self-merge with conf/settings kept instead.
- Drop everything incl. conf: rejected by requester; conf holds the cap.

## Review

Verifier ran on the first drafts (human-merge design), before the redesign.
- r1: (verifier) core-path guard lives in editable files; no branch protection or CODEOWNERS on main, so the fleet can unlock itself (fixed: .github core + CODEOWNERS + operator code-owner-review step in protocol-boundary-core-only)
- r2: (verifier) HUMAN MERGE row never fires after retire; slot held, respawn loop (wontfix: human-merge design deleted at requester's direction)
- r3: (verifier) "claims hold as for blocked" contradicts blocked code (wontfix: design deleted)
- r4: (verifier) protocol_work gated on unattended reaches unsupervised drain (wontfix: design deleted; orchestrated-only removes unsupervised)
- r5: (verifier) finish does not split core from human-merge diff (wontfix: design deleted)
- r6: (verifier) public repo: stranger's issue becomes self-merged code via triager (fixed: write-access author filter)
- r7: (verifier) triage-* glob dates cycle from builder file, as janitor once did (fixed: triage-[0-9]*)
- r8: (verifier) curate helpers hard-code kind; anchors unusable (fixed: cycle_landed_sha, janitor_due/branches)
- r9: (verifier) triage scope misses conf-keys, bootstrap, plans README, plan.md (fixed)
- r10: (verifier) PLANNED issues invisible to session-start hook (wontfix: needs orchestrated-only; no role takes issues directly after it)
- r11: (verifier) third copy of issue validator (fixed: extract and reuse)
- r12: (verifier) acceptance only passable post-merge; no verify (fixed in boundary plan: on-branch dispatch, verify added)
- r13: (verifier) queue-context re-derives predicate; env override unlocks (wontfix: design deleted)
- r14: (verifier) cross-plan overlaps unnamed in Traps (fixed: named; drop-unsupervised-docs superseded)
- r15: (verifier) #297 cited as rule; Closes #N with sibling plans (fixed: cited as proposal; Refs vs Closes)

## Blockers

None.

## Where to look

- `joharness.sh:protocol_paths`, `joharness.sh:unattended` — the bound.
- `.claude/commands/curate.md` — the shape a cadence role copies.
