---
workstream: compact-reorient
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: compact-reorient
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Merge; r1 stays open — one live compaction with output pasted closes it
---

## Goal

Plan `docs/plans/compact-reorient.md`: three moments change what a session
knows; the harness hooks session start and turn end. Compaction is the third
and is unhooked — and the only one the session does not choose. It fires
mid-work and takes the orientation Loop step 1 established, leaving a session
still on a claimed branch, still editing, no longer holding the workstream
file it read at minute zero.

## Decisions

- The plan's open question is which event to hang this on, answered by
  evidence rather than guess. Evidence gathered BEFORE writing either line:
  see Hook contract below.

## Hook contract (the plan's acceptance asks for this explicitly)

- PROVEN, from this repo: Claude Code delivers JSON on a hook's stdin, and a
  harness hook already consumes it. `.agents/harness/handover-guard.sh:39`
  reads `input="$(cat 2>/dev/null || true)"` and branches on
  `stop_hook_active` from that payload. So the stdin channel is not a
  hypothesis here; only the SessionStart field names are.
- PROVEN, from this session's own transcript: this client fires SessionStart
  with a distinguishable source. The transcript carries both
  `SessionStart:startup hook success` and `SessionStart:resume hook success`
  for the same registered hook, so the client both re-fires the event and
  labels which kind of start it was.
- SETTLED from the Claude Code hook documentation: `SessionStart` delivers a
  `source` field whose values are `startup`, `resume`, `clear`, `compact`,
  `fork`, and its stdout reaches the model on exit 0. `PreCompact` exists but
  its stdout does NOT reach the model — it goes to the debug log — so a
  re-orientation message hung there would be written for nobody. Hence
  SessionStart, and hence NO new event and no `.claude/settings.json` change:
  the registered entry carries no matcher, so it already fires for every
  source including `compact`. The plan's scope said "one more hook entry",
  written before the question was answered; its own conditional ("if
  SessionStart already fires with source=compact, the fix belongs there and
  no new event is needed") is the branch the evidence took.
- Documented-versus-inferred, kept apart because the plan asks for it: the
  `source` values, the matcher syntax and SessionStart stdout reaching the
  model are documented guarantees; "PreCompact stdout is discarded" is
  inferred from its omission from the list of events whose stdout is
  injected, not from a sentence saying so.

## Rejected

- `PreCompact`. It fires at the right moment but its stdout never reaches the
  model, so the message would exist only in a debug log.
- A second `SessionStart` entry with `matcher: "compact"`. The existing entry
  has no matcher and so already fires on every source; adding a matched one
  would run BOTH on compaction and print the state twice. Branching inside
  the command keeps one output and matches the plan's "same git facts,
  different lead line".
- Reading stdin with a plain `cat`, the idiom the Stop guard uses. Correct
  there, wrong here: `cat` blocks until stdin closes, and a human running
  `./joharness.sh session-start` by hand has a terminal nobody closes — the
  hook meant to orient sessions would have hung them. Caught by a selftest
  run that never finished. Now bounded and skipped entirely for a TTY.

## Review

Opus tier = adversarial, separate lenses; both run 2026-08-28. They converged
on the same blocking finding, and it is the one I could NOT fully close.

- r1: OPEN, and both lenses called it the thing not to merge blind. The
  trigger is documentation-derived, never observed on this client: if the
  payload spells the field or value differently, `src` is empty forever,
  every branch takes its ordinary path, and nothing reports it — the tests
  synthesize the payload themselves, so `ci` stays green either way. I tried
  to close it by capturing one real payload from the Stop hook, which fires
  at every turn end; the permission classifier refused an edit to an
  auto-executing hook script and I did not work around it. What IS observed
  on this client: the Stop guard's one-shot behaviour depends on reading
  `stop_hook_active` out of that JSON and demonstrably works this session, so
  the envelope is real; and the client's own logs name SessionStart sources
  (`startup`, `resume` both seen). The `source` key for SessionStart stays
  documented, not observed. Fail-safe direction: an unrecognised payload is a
  silent ordinary start, so the feature can be DEAD but never WRONG. Closing
  it needs one compaction in a live session with the output pasted, which is
  the plan's acceptance bullet 2 and is left undone deliberately rather than
  quietly.
- r2: a layer with `setup.sh` and no `AGENTS.md` printed ZERO environment
  information on compact — the suppression was keyed on the banner, and with
  no rules pointer to carry the name, both carriers vanished together. The
  compacted session is exactly the one that no longer remembers which
  environment it is in. (fixed: nothing is suppressed at all)
- r3: `md=eager` plus compact dumped the layer's rules with no heading above
  them. (fixed by the same)
- r4: the message never named the workstream file the plan asked it to name,
  and on a branch with no workstream file it ordered a re-read of nothing
  while the state six lines below answered "No workstream file on this
  branch". (fixed: the notice moved into `handover-context.sh`, where the
  path is printed. The compaction line now sits under the header so a branch
  with no workstream file is still told, and the list lead becomes the
  re-read order naming the files under it)
- r5: it duplicated the "Read in full FIRST" line already six lines below —
  against "state each fact once". (fixed: it REPLACES that lead rather than
  adding a second one)
- r6: `JOHARNESS_SESSION_SOURCE` was exported and read by nothing, entering
  the environment of every child including a consumer's own `setup.sh`.
  (fixed: `handover-context.sh` consumes it, which is what the export is for)
- r7: `| head -1` was unnecessary after a `sed -n …p`, in a file that has
  already paid a finding for a pipeline whose status it did not need. (fixed)
- r8: `joharness.sh` is not in the plan's declared scope while
  `handover-context.sh` — the file the plan designated — was untouched.
  (fixed in substance: the message now lives in the designated file;
  `joharness.sh` keeps only the source detection, which has to run where the
  hook command runs. Recorded rather than silently widened)
- r9: the plan asked for a git-unreadable case for both sources and there was
  none. (fixed: both sources outside a repo, exit 0)
- r10: (correctness, clean) byte-identical cold start proven twice against
  main; no hang under a closed fd, a directory, /dev/null, /dev/zero,
  /dev/urandom, a TTY, a fifo held open, or a 1MB redirect; the sed
  extraction survives a `cwd` containing the literal text `"source":
  "compact"` because JSON escapes it; unrecognised, uppercase, hyphenated,
  null and absent values all fall through to the ordinary path.
- r11: (correctness, noted not fixed) partial-input-on-timeout is bash >= 4.0,
  so on macOS system bash 3.2 a writer holding stdin open past 1s would miss
  the source. Real hooks close stdin; recorded because the fallback is
  silence, which is r1's failure mode again.

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh:39` — the working hook-stdin idiom to reuse.
- `joharness.sh:cmd_session_start` — prints the environment banner before
  delegating; a compact-time run must not reprint a provisioning banner.
- `.agents/harness/handover-context.sh` header — "never fails a session".
