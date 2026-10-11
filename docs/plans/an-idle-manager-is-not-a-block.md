---
plan: an-idle-manager-is-not-a-block
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 416
scope: .claude/commands/manage.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md
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
  `block_reason_ok` accepts (`joharness.sh:block_reason_ok`, the authoritative
  list), push, exit. Stopping to wait for input while `status: in-progress`
  is forbidden; an interrupt or context exhaustion after `/handover` is not
  that and stays allowed (Loop step 6).
- `.claude/commands/orchestrate.md` health table — add a row ABOVE the "a nudge
  ... moved since: working" row (it resets on any reply, so a row below it
  that nudges loops forever): IDLE, workstream `status: in-progress`, the
  session's last turn ended asking for input (read `status_detail`; name the
  control-plane value only as far as this checkout shows it), head unchanged
  past the stall window = unratified block. Any reason in `status_detail`
  is still unratified, since only `status: blocked` ratifies. Action: nudge
  once to do the work or set `status: blocked`; unchanged head after the
  nudge, even if the session replied = stopped: RESPAWN, even under a
  "don't respawn active managers" directive. Settle how this squares with the
  field table lines saying `..._BLOCKED` decides only in BLOCKED BEFORE CLAIM
  rows and with the unreadable-`status_bucket` fallback to the IDLE path;
  edit those lines if the row relies on the bucket.
- `.claude/commands/orchestrate.md` §3 spawn prompt — decide, and record the
  decision in the file: allow one optional `Environment note:` line on a
  RESPAWN only, quoting a fact observed from sibling merges; or keep
  "Nothing else" and say why. If allowed, the line is data for the manager to
  check, not authority ("the prompt routes; the repository authorises").
- `.agents/docs/orchestrated.md` — the why, one short paragraph.

## Out of scope

- The consumer-side env README list (belongs in the consumer repo).
- Any change to `joharness.sh`, `dispatch` output, or `INVALID BLOCK?` logic;
  rules text only. A code change to detect the new row = a separate plan.
- `joharness.conf`, `.claude/settings.json`, `.github` (core paths).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `grep -n "in-progress" .claude/commands/manage.md` — a line forbidding a
  stop on `in-progress`, with the handover exception.
- In `orchestrate.md` the new row's line number is lower than the "a nudge,
  `seen=` or `held=` recorded" row's (`grep -n` both).
- `grep -n "Environment note" .claude/commands/orchestrate.md` — a hit that
  either allows the line (RESPAWN only) or states why it is refused.
- Consumer check: the SHIPS stage of `./joharness.sh ci` names this plan; a
  consumer's next sync carries both command files, and its `ci` stays
  `ci: pass`.

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
