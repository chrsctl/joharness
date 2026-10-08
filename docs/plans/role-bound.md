---
plan: role-bound
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: none
scope: joharness.sh, .agents/harness/handover-guard.sh, .agents/harness/queue-context.sh, .agents/harness/selftest, shared:.agents/harness/selftest.sh, .claude/commands/orchestrate.md, .claude/commands/manage.md, .github/workflows/ci.yml, joharness.conf, .agents/docs/handover/TEMPLATE.md
---

## Goal

Requester, 2026-10-08: "Supervised is orchestrated, we want to drop single
drain start, unsupervised is unnecessary, clean up." One mode will remain:
orchestrated. Today the unattended bounds (no protocol-text edits, no added
requirement, SUPERVISED ONLY plans) key on the MODE, so with one mode every
session is bound — including the human-driven one that does harness work,
which in this repo is the product. Move the bounds from the mode to the
ROLE: a spawned session (manager, curator, janitor, surveyor, analyst,
reporter) is bound; a session a human talks to directly is not. Decided
alone by the implementing session after the requester declined the
question; flagged in the PR body so the requester can veto.
This plan lands FIRST: it is what lets the other two be built at all.

## Scope

- `.agents/docs/handover/TEMPLATE.md` — new frontmatter field `role:`
  (`manager` | `curator` | `janitor` | `surveyor` | `analyst` | `reporter`,
  absent = human-driven). Document: spawned sessions MUST write it.
- `.claude/commands/orchestrate.md` — every spawn prompt tells the child to
  write `role: <its role>` in its workstream file at claim.
- `.claude/commands/manage.md` (and the other spawned roles' commands it
  names) — write `role:` at claim (step 1).
- `joharness.sh` — new predicate `bound` (this branch's workstream file
  carries a `role:`), read from the DIFF against the merge base, never the
  tree (Loop step 4). Every caller of `unattended` that guards a bound
  switches to it: `lint_requirement_writes`, `cmd_authority`'s claim, the
  SUPERVISED ONLY collection in `cmd_drain`/`cmd_dispatch`. Rename the
  marking `SUPERVISED ONLY` → `HUMAN ONLY` (a plan only a human-driven
  session may build), everywhere it prints.
- `.agents/harness/handover-guard.sh` — protocol-text check fires on a
  `role:` branch, not on mode.
- `.agents/harness/queue-context.sh` — HUMAN ONLY marking stays in the
  orchestrator's view (dispatch never spawns them); a human-driven session
  sees them as free.
- `.github/workflows/ci.yml` — drop the canonical-marker
  `JOHARNESS_MODE=supervised` export (PR #306); `ci` reads the branch now.
- `joharness.conf` — drop the comment telling humans to export supervised.
- Selftests for each of the above, under `.agents/harness/selftest/`.

## Out of scope

- Removing `supervised`/`unsupervised` values, `/drain`, `cmd_drain`, the
  interview: plan `one-mode`. This plan leaves `run_mode` alone.
- Docs rewrite beyond the files named: plan `one-mode-docs`.
- Any tamper-proofing of `role:` beyond today's env-var level — a spawned
  session that deletes its own `role:` line is the same trust gap the env
  override is now. Name it in the PR, build nothing for it.

## Acceptance

- Selftest: a branch whose workstream file says `role: manager` and touches
  `joharness.sh` → `handover-guard.sh` blocks; same branch without `role:` → no
  block, under `JOHARNESS_MODE=orchestrated`. Each case fails with the fix
  reverted (Loop step 5).
- Selftest: `role: manager` branch adding `docs/product/x.md` → `ci` red;
  no `role:` → green, under orchestrated, no env override.
- `./joharness.sh dispatch` — protocol-path plans listed `HUMAN ONLY`.
- `./joharness.sh ci` — `ci: pass` WITHOUT `JOHARNESS_MODE` exported.
- `./joharness.sh verify` — 0 failed.
- Plan `ci` calls SHIPS: a consumer's `ci` on a no-role branch stays green.

## Where to look

- `joharness.sh:unattended` — the one predicate; every bound reads it.
- `joharness.sh:lint_requirement_writes` — requirement bound.
- `joharness.sh:cmd_authority` — the claim check.
- `.agents/harness/handover-guard.sh` — protocol-text boundary at Stop.
- `.agents/harness/queue-context.sh` — SUPERVISED ONLY marking.
- `.claude/commands/orchestrate.md` — spawn prompt block.
- `.agents/docs/unsupervised.md` — Bounds, the three rules being re-keyed.

## Traps

- Ownership from the DIFF against merge base, never the tree: a branch
  inherits every workstream file its base carries.
- Protocol text: build from a human-driven session with
  `JOHARNESS_MODE=supervised` exported until this merges (the conf says so).
- Never skip, disable or quarantine a test to get green.
