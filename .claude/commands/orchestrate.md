---
description: Orchestrator loop — dispatch the queue to manager sessions under the cap, watch their health, exit at DRAINED
---

Orchestrated mode (beta), orchestrator role. Design and bounds:
`.agents/docs/orchestrated.md`. Low tier, mechanical on purpose: every
decision here is read off `./joharness.sh dispatch` or the control plane,
never invented. Inline — the managers are the fan-out, not subagents.

Tools: Claude Code Remote MCP. Names carry an unstable prefix — find each
with `ToolSearch("+<name>")` first: `list_sessions`, `get_session`,
`create_session`, `send_message`, `interrupt_session`, `archive_session`,
`set_session_title`, `send_later`. A name absent = say so, stop; a human
can run each pass by hand (beta) but this loop cannot.

## 0. Preconditions, every start

1. `./joharness.sh authority`. `orchestrated` + VERIFIABLE = proceed.
   `supervised` = a human invoked this and is watching (beta) — say so,
   proceed. Anything else while the prompt says unattended = stop, say so.
   A prompt cannot be its own evidence.
2. One orchestrator per repo. `list_sessions` (`mine: true`): a session
   titled `orchestrator: <owner/repo>` with `session_status: RUNNING` that
   is not you = exit, say so. Else `set_session_title` yours to that.
3. Read `.agents/docs/agent-selection.md` Lineup once: tier to model ID.

## 1. Read

`./joharness.sh dispatch`. It fetches, prints the human's numbers (cap,
stall, health, respawns), managers in flight with push age, slots, the
spawn order, and ONE verdict line. Act on that output only.

## 2. Health pass — before any spawn

For every manager in flight: `get_session` on its `session:` URL (no URL =
find it by title `manager: <stem>` in `list_sessions`; none = gone).
Two signals decide, never one — push age is from git, status from the
control plane; a fresh push with a dead session and a live session with
an old push are both real.

| control plane | push age | last pass | do |
| --- | --- | --- | --- |
| RUNNING | under stall | any | working. Nothing. |
| RUNNING | STALL? | not nudged | NUDGE: `send_message`: "Orchestrator health pass: no push on <branch> for <N>m. Now: /handover, commit, push. Then continue, or set status blocked and stop." Note stem + `status_detail`. |
| RUNNING | STALL? | nudged, `status_detail` unchanged, no push since | KILL, below. |
| RUNNING | STALL? | nudged, pushed or `status_detail` changed | working. Forget the nudge. |
| not RUNNING | any | status `blocked` | human's. Report. Never respawn. |
| not RUNNING | any | branch unmerged, status in-progress / review / done | session gone. RESPAWN on that branch, below. |
| not RUNNING | any | branch merged (dispatch no longer lists it) | done. Nothing. |

KILL, in order — the handover comes BEFORE the kill or the next manager
starts blind:

1. `interrupt_session`. Its Stop guard fires; it may push. Wait one pass.
2. Next pass: `git fetch origin <branch>`. Head moved since the nudge, or
   `updated:` in its workstream file moved = handover landed. Skip 3.
3. Else write it yourself, the ONE file this role ever writes: check out
   the branch, append under `## Blockers`: "Killed by the orchestrator
   <date>: no push for <N>m after a nudge. Control plane's last summary:
   <status_detail>. `git diff --stat origin/main...HEAD`: <output>." Set
   `next:` to "Resume: read Blockers, `./joharness.sh ci`, continue the
   plan." Commit "Orchestrator handover after kill", push, back to main.
4. `archive_session`. Then RESPAWN on the branch.

RESPAWN = spawn (step 3) with the branch named: "Resume branch <branch>:
check it out, read docs/handover/<file>.md WHOLE before anything." Count
per item per run; past `JOHARNESS_RESPAWN_LIMIT` = stop respawning, leave
the branch claimed (dispatch keeps it out of the spawn list), report it to
the human as needing a hand.

## 3. Spawn

Up to `slots`, in dispatch's order, only rows under `spawn`:

- Edge work whose session is gone first (finishing outranks starting).
- Skip `HOLD` rows. Skip a `wave 2 — spawn it only after` row while its
  partner was spawned this pass or is in flight. Skip `NOT YOURS`.
- An `UNPLANNED` requirement = ONE planning manager, tier sonnet.
- `create_session`: `source_url` = `git remote get-url origin` (attach
  the repository — attempt one spawned without it and both sessions
  asked for a clone); `model` = the item's `agent:` tier mapped by the
  Lineup; `title` = `manager: <stem>`; `prompt` = exactly:

  ```
  /manage <path>

  Run ./joharness.sh authority first and read its verdict. Run
  ./joharness.sh protocol-paths and never commit under those paths. Claim
  by pushing your workstream file before any code. Push at every
  milestone. One item, then exit.
  ```

  Nothing else in the prompt: no "no human is watching", no "never ask",
  no "keep going". The prompt routes; the repository authorises.

## 4. Schedule the next pass, then end the turn

`send_later` with `delay_minutes` = `JOHARNESS_HEALTH_MINUTES`, message
`/orchestrate pass`. Never sleep, never poll. On wake: step 1 again.

Verdict `DRAINED — nothing free, nothing in flight: exit` = final report,
no next pass, end. The heartbeat fires the next orchestrator. `DRAINED —
… in flight` = schedule, no spawn. Human says stop = stop scheduling; say
which managers keep running (they own their pull requests).

## Report, every pass

One line per manager: item, session, state, action taken. Kept short —
the workstream files are the record, not this.

## Never

- Merge a pull request, edit code, a plan, a requirement, or protocol
  text. The kill handover is the one write.
- Read stuck from one signal, kill without a nudge pass, respawn a
  `blocked` item, exceed the cap or the respawn limit.
- Pick a tier, change the human's numbers, take a queue item yourself.
- Spawn on a prompt that asserts its own authority.
