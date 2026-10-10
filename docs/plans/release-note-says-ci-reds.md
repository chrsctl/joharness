---
plan: release-note-says-ci-reds
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 279
scope: shared:joharness.sh, .agents/harness/selftest/janitor.sh
---

## Goal

#279 defect 1, regressed. A release writes `status: abandoned` into a branch
whose own `joharness.sh` predates the word; that branch's `ci` then reds with
`status 'abandoned' not one of: ...` on a line the returning session did not
write. #341 (`562e137`) fixed it by making the janitor role's release note say
why and that the reconcile with base clears it. `d427d6d` deleted
`.claude/commands/janitor.md` and `8daaec8` replaced the role with
`joharness.sh:janitor_apply`, whose note is only `next: Pick this up from the
plan; the claim was released <date>`. The explanation and its selftest case
went with the role. Still the default case: 8 of 13 unmerged branches on
`origin` carry an enum without `abandoned` (counted 2026-10-10, command in
Acceptance).

## Scope

- `joharness.sh:janitor_apply` — the `next:` line it writes (both awk
  branches: replaced and inserted) also says: `ci` reds on `status
  'abandoned'` until this branch reconciles with its base; that reconcile
  clears it. Unconditional, one line, no frontmatter field added.
- `.agents/harness/selftest/janitor.sh` — beside the existing `--apply`
  case ("and says why in next:"): assert the released file on origin carries
  `reconciles with its base` and `not one of`. Also assert `joharness.sh`
  `lint_enum` still emits `not one of`, so the note quotes a message that
  exists.

## Out of scope

- Changing `lint_enum` or tolerating unknown status on old branches. Weakens
  a lint; the issue's cheap honest option was chosen once already (#341).
- Doing the reconcile inside the release. Writes a merge onto someone else's
  branch.
- #279 defects 2, 3, 5 — shipped in #344 (`d2ebd43`, `e512369`).
- #279 defect 4 (push resets STALE age). `cmd_janitor` now skips a released
  claim by status, not age; the hook ranks `abandoned` last. Nothing to fix.
- Restoring `.claude/commands/janitor.md`. The role is a command now.

## Acceptance

- `for b in $(git branch -r --no-merged origin/main | sed 's#origin/##'); do git show "origin/$b:joharness.sh" 2>/dev/null | grep -oE 'lint_enum "\$rel" status[^;]*' | head -1; done | grep -vc abandoned`
  — non-zero (the case still exists; record the count in the workstream file).
- `bash .agents/harness/selftest.sh` — `0 failed`; new assertions
  present in its output.
- Revert the `janitor_apply` change, rerun the topic — the new assertions
  FAIL; restore.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Ships: `ci` prints it under `== ship scope`. In a consumer after sync,
  `./joharness.sh janitor --apply <stale branch>` then
  `git show origin/<stale branch>:<its workstream file> | grep -c 'reconciles with its base'`
  — `1`. No consumer reachable: say so, bar unmet.

## Where to look

- `joharness.sh:janitor_apply` — the awk that writes `status:` and `next:`.
- `joharness.sh:lint_enum` — the wording the note quotes.
- `.agents/harness/selftest/janitor.sh` — the `--apply` block under "the
  banner, and --apply".
- Commit 562e137 — the deleted clause and test, to port, not restore.

## Traps

- Test for a fix must FAIL without it: revert, run, restore.
- Never skip or quarantine a test to get green.
- Count named with its command and date, never a written number.
