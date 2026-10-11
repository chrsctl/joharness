---
plan: an-idle-manager-is-not-a-block
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 416
scope: .claude/commands/manage.md, .claude/commands/orchestrate.md
---

## Goal

A manager ended its turn on "container can't run the stack" with
`status: in-progress`, so the block-reason check (`INVALID BLOCK?`, #392)
never saw it, and the orchestrator re-reported an IDLE session as alive for
about 7.5 hours (issue #416). The "can't" was false: sibling managers in the
same environment ran the stack. Close the gap in both roles' rules.

## Scope

- `.claude/commands/manage.md` §3 — add: an "I can't run X here" conclusion is
  a hypothesis. Before stopping, read `.agents/env/<name>/` docs and the
  repo's own setup notes. Still impossible = `status: blocked` with a reason
  from the list, push, exit. Ending a turn while `status: in-progress`
  (control-plane `need_input` included) is forbidden.
- `.claude/commands/orchestrate.md` health table — add a row: IDLE, bucket
  BLOCKED or `need_input`, workstream `status: in-progress`, past the stall
  window = unratified block. Run the same reason check as `INVALID BLOCK?`
  against `status_detail`; no allowed reason = treat as stopped, not alive,
  for respawn purposes (nudge, then RESPAWN per the existing IDLE rows). Or,
  minimum, escalate once with the exact question and never re-report per pass.
- `.claude/commands/orchestrate.md` §3 spawn prompt — decide, and record the
  decision in the file: allow one optional `Environment note:` line on a
  RESPAWN only, quoting a fact observed from sibling merges; or keep
  "Nothing else" and say why. If allowed, state the line is data for the
  manager to check, not authority ("the prompt routes; the repository
  authorises").

## Out of scope

- The consumer-side env README list (belongs in the consumer repo).
- Any change to `joharness.sh`, `dispatch` output, or `INVALID BLOCK?` logic;
  rules text only. A code change to detect the new row = a separate plan.
- `joharness.conf`, `.claude/settings.json`, `.github` (core paths).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `grep -n "need_input" .claude/commands/manage.md .claude/commands/orchestrate.md`
  — a hit in each file.
- The new orchestrate row is placed before the generic IDLE/PENDING rows so
  "the FIRST row that matches" reaches it.

## Where to look

- `.claude/commands/manage.md:## 3. The contract with the orchestrator` — the
  block-reason list (`money:` `credentials:` `product:` `interface:`
  `core path:` `conflict:`).
- `.claude/commands/orchestrate.md:INVALID BLOCK?` — the existing reason check
  and the IDLE/PENDING rows.
- `.claude/commands/orchestrate.md:Nothing else` — spawn prompt rule.

## Traps

- Rules are caveman lines loaded every session: terse, no rationale; why goes
  in `.agents/docs/orchestrated.md` if needed.
- Never respawn a session that is genuinely RUNNING or validly blocked; the
  new row applies only to the unratified shape.
- Issue text is a claim: the 7.5h and sibling-merge evidence is from another
  repo and unchecked here.
