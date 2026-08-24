---
plan: compact-reorient
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .claude/settings.json, .agents/harness/handover-context.sh, .agents/harness/selftest.sh, .agents/scripts/sync-to-consumer.sh
---

## Goal

The handover protocol exists because context dies. Three moments change
what a session knows, and this harness hooks two of them: session start
(`SessionStart` runs `joharness.sh session-start`) and turn end (`Stop`
runs `handover-guard.sh`). Compaction is the third and is unhooked. It is
also the only one the session does not choose — it fires mid-work, hours
in, and takes with it the orientation Loop step 1 exists to establish. What
survives is a session still on a claimed branch, still editing, no longer
holding the workstream file it read at minute zero. `kitchen-engineer42/joharnessburg`
wires a `PreCompact` hook to snapshot workspace state for this reason; this
harness already owns the injector (`handover-context.sh`) and runs it once.
Make it run at the other moment too.

## Scope

- `.claude/settings.json` — one more hook entry. WHICH event it hangs on is
  the plan's open question, answered by evidence, not by guess: Claude Code
  fires `SessionStart` with a `source` field on stdin (`startup`, `resume`,
  `clear`, `compact`) and also exposes `PreCompact`. If `SessionStart`
  already fires with `source=compact`, the fix belongs there and no new
  event is needed. Verify against the running client before writing either
  line — record what stdin carried and whether the hook's stdout reached
  the model, in the workstream file, with the command that showed it.
- `.agents/harness/handover-context.sh` — a post-compaction run is not the
  same message as a cold start. Cold start says "here is the state". Post
  compaction must say what the session cannot know it lost: context was
  compacted, this branch's workstream file is `<path>`, re-read it whole
  before the next edit. Same git facts, different lead line.
- `.agents/harness/selftest.sh` — cover the branch: a compact-sourced run
  prints the re-read line, a startup-sourced run does not, and neither
  fails a session when git is unreadable (the script's standing contract,
  line 16).
- `.agents/scripts/sync-to-consumer.sh:114` — `.claude/settings.json` is
  already on the synced list, so consumers inherit the new hook. Confirm
  that is still true after the edit rather than assuming it.

## Out of scope

- The `PostToolUse` trace offload, John's other hook (large tool results
  written to `.john/trace/`, a digest pointer returned in their place).
  Same source, deliberately not stolen: John reads corpora and this repo
  reads shell scripts, and nobody here has measured context pressure. This
  repo's own bar is counted numbers — an offload built on an unmeasured
  need is a guess with a blast radius across every `Read` and `Bash`
  result. Measure first, in its own plan, if anyone wants it.
- Anything that infers liveness. `handover-context.sh:11` states why push
  time is not liveness and `/who` is; compaction changes nothing about
  that.
- Making the hook fail a session. It reports; it never blocks.

## Acceptance

- Hook contract recorded in the workstream file: the raw stdin JSON one of
  these events delivered, and whether its stdout reached the model. A plan
  that guessed here is a plan that shipped a hook nobody proved fires.
- Compaction in a live session prints the re-read line naming this
  branch's workstream file. Paste the output.
- `./joharness.sh session-start` on a cold start — output unchanged from
  today, byte for byte. Diff it against a pre-change capture.
- `./.agents/harness/selftest.sh` — passes, count higher than today's by
  the tests added.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.claude/settings.json` — both existing hooks, and the exact quoting of
  `"$CLAUDE_PROJECT_DIR"` that makes them work.
- `joharness.sh:720` — `cmd_session_start`, which prints the environment
  banner before delegating; a compact-time run should not re-print a
  provisioning banner that was already true.
- `.agents/harness/handover-context.sh:47` — `add()`, how output is
  accumulated, and `field()` below it.
- `.agents/harness/handover-context.sh:16` — "Never fails a session:
  anything unexpected exits 0 with no output." The new path inherits this.
- `.agents/docs/handover/README.md` — the protocol the re-read line points
  at.

## Traps

- `ci-scope-selftest` and `queue-shared-scope` also touch
  `.agents/harness/selftest.sh`; `ci-scope-selftest` also touches
  `joharness.sh`. Not a wave with either.
- `process-scorecard` and `harness-glossary` (this steal's siblings) touch
  `.agents/harness/selftest.sh` too. Whichever lands second rebases.
- Hook output is loaded every session, so it is paid repeatedly. Caveman
  applies (`.agents/docs/caveman.md`); a re-read line that runs four lines
  long is a tax on every compaction.
- No second copy of state. The hook derives from git at read time like
  every other view (`.agents/docs/graph.md`, Rules).
