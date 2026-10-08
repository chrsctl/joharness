---
plan: protocol-boundary-core-only
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: none
scope: shared:joharness.sh, .github/CODEOWNERS, .agents/harness/queue-context.sh, .agents/harness/handover-guard.sh, .agents/harness/selftest/queue-context-supervised-only.sh, .agents/harness/selftest/handover-guard.sh, .agents/harness/selftest/protocol-boundary.sh, shared:.agents/harness/selftest.sh, shared:.agents/harness/AGENTS.md, shared:.agents/docs/unsupervised.md, shared:.agents/docs/orchestrated.md, .agents/docs/plans/README.md, shared:.claude/commands/manage.md, shared:.claude/commands/orchestrate.md
---

## Goal

Requester, 2026-10-08: "We want to remove most restrictions. Joharness
should be able to use its own framework." Today `unattended()` puts every
protocol path (`joharness.sh:protocol_paths`) off limits to an orchestrated
session. `./joharness.sh dispatch` on 2026-10-08 (canonical `main` 25733a6)
listed 9 of 9 queued plans under `NOT YOURS`, so the fleet cannot build
the harness it runs on. The requester decided what stays (2026-10-08,
answered in session): the step 7 merge gate, unchanged, and the CORE
paths: `joharness.conf` (mode, cap, the human's money) and
`.claude/settings.json` (hooks, permissions). `.github/` joins them, because
`.github/workflows/` IS the merge gate's checks and `.github/CODEOWNERS` is
the gate below. Everything else goes.

The core list lives in `joharness.sh`, and a manager may now edit that file
and self-merge it. A manager could therefore delete a core path from the
list and merge in one pull request, and `finish`, the stop guard and the
hook would all read the edited copy (verifier r1, 2026-10-08:
`main` has no branch protection and no CODEOWNERS). The local list is the
early warning. The guarantee has to be GitHub-side: CODEOWNERS names the
core paths, and a branch-protection rule requiring code-owner review stops
a merge touching them without the human's approval. A manager edits protocol text
and self-merges it like any other diff, and a session may write a
requirement.

## Scope

- `joharness.sh`:
  - `protocol_paths` returns ONLY `joharness.conf`,
    `.claude/settings.json` and `.github`. `joharness.sh` itself is NOT
    among them, by design: CODEOWNERS is the guarantee (see Goal). Rewrite its header comment: what each
    remaining entry protects, and that the rest was released on the
    requester's decision of 2026-10-08. Keep the function name: banner,
    guard, hook and `ci` already read it, so one edit moves all of them.
  - `lint_requirement_writes` and its `ci` stage — delete. Requirements may
    be written in every mode.
  - Banner text that says protocol text is off limits — say "never edit:
    <core paths>" instead.
  - Every comment or message saying "protocol text … SUPERVISED ONLY"
    should read as the core paths. Keep the marking word `SUPERVISED ONLY`
    for now: `orchestrated-only` renames it once supervised is gone.
- `.github/CODEOWNERS` — new. One owner, `@chrsctl`, on `/joharness.conf`,
  `/.claude/settings.json` and `/.github/`. The last entry covers the
  CODEOWNERS file itself.
- Operator action, the human's (repository settings, never a session): a
  branch-protection rule (or ruleset) on `main` with "Require review from
  Code Owners". It should block only pull requests touching owned paths,
  so set the required approval count to the lowest value GitHub accepts
  together with code-owner review. Verify that on a throwaway PR and
  record the result in the PR body. Until it is set, the PR body says the
  core paths are guarded locally only.
- `.agents/harness/queue-context.sh`, `.agents/harness/handover-guard.sh` —
  no logic change should be needed, because both read `protocol_paths`.
  Verify that, and fix any hard-coded path list found.
- Selftests: `.agents/harness/selftest/queue-context-supervised-only.sh` and
  `.agents/harness/selftest/handover-guard.sh` fixtures that use a
  non-core path (e.g. `.agents/harness/`) as the forbidden example — move
  them to a core path. New `.agents/harness/selftest/protocol-boundary.sh`,
  registered in `SELFTEST_TOPICS`: an unattended session's diff under
  `.claude/commands/` does not block the stop and its plan is free; a diff
  to `joharness.conf` still blocks and its plan is still marked; a
  requirement added on an unattended branch is green.
- `.claude/commands/manage.md`, `.claude/commands/orchestrate.md` — every
  sentence forbidding protocol edits or naming "protocol text" as a
  human-only blocker narrows to the core paths.
- `.agents/harness/AGENTS.md` — Loop step 2 ("Boundary holds in both: no
  commit to protocol text") and "Decide alone" ("protocol text" among
  blockers, if present): core paths only. Caveman style. Net size must not
  grow.
- `.agents/docs/unsupervised.md` Bounds (first and third bullets),
  `.agents/docs/orchestrated.md`, `.agents/docs/plans/README.md`
  (protocol path in `scope:` paragraph) — the new boundary, why, and the
  requester's date.

## Out of scope

- Removing modes. That is `orchestrated-only`, which needs this plan.
- Opening the core paths. No setting does it.
- Changing the step 7 gate or `finish` in any way.
- Consumers' "Harness upkeep" rule (`.agents/harness/AGENTS.md`). It is a
  sync rule, not a mode bound, and stays.

## Acceptance

- `./joharness.sh protocol-paths` → exactly three lines: `.github`,
  `joharness.conf`, `.claude/settings.json` (any order).
- On the branch, `JOHARNESS_MODE=orchestrated DISPATCH_FETCH=0 ./joharness.sh dispatch`
  → the `NOT YOURS` block is absent, or lists only plans whose `scope:`
  names a core path.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → 0 failed (the
  diff touches `joharness.sh` and `.agents/harness/`). `bash .agents/harness/selftest.sh` →
  `0 failed`, the `protocol-boundary` topic listed. Count from the run.
- Each new case fails with its fix reverted (Loop step 5).
- SHIPS: `joharness.sh` and `.agents/harness/` reach every consumer. The
  selftest's core-path case is the check a consumer runs.

## Where to look

- `joharness.sh:protocol_paths` — the list and its per-entry reasoning.
- `joharness.sh:unattended` — every bound's predicate. It stays as is until
  `orchestrated-only`.
- `joharness.sh:lint_requirement_writes` — the ban to delete.
- `joharness.sh:drain_supervised_only`, `joharness.sh:cmd_dispatch` — the
  `NOT YOURS` block.
- `.agents/harness/queue-context.sh:qc_scope_class` — the marking.

## Traps

- This plan IS protocol text. Build it with `JOHARNESS_MODE=supervised`
  exported and a human present. It is the last plan that needs that.
- `joharness.conf` is not in this plan's scope and stays untouched.
- Overlaps, to reconcile at finish: `fable-tier` (in flight) and
  `scout-cycle` on `joharness.sh`; `heartbeat-is-a-precondition`,
  `scout-command` and `fable-tier` on `orchestrate.md`/`orchestrated.md`;
  `orchestrated-only-docs` deletes `unsupervised.md` later and carries this
  plan's Bounds text into `orchestrated.md`.
- Never write "guarded" in the PR body unless code-owner review is
  measured on GitHub. A written rule is not a gate.
- Never skip, disable or quarantine a test to get green. Re-pin a fixture,
  never delete the case.
