---
workstream: queue-drain-command
status: review
branch: claude/queue-drain-command
pr: none
plan: queue-drain-command
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-29
next: Open the pull request, then merge once checks are green
---

## Goal

The queue stops draining while it still holds work. Counted on `origin/main`
2026-08-29 over the last 120 merges: 5 of 119 gaps exceed three hours, the two
longest 32.2h and 24.0h, and the tree carried 18, 18, 19 and 11 plan files at
the four longest stalls' first commit. Idle holding a full queue — the failure
`.agents/docs/unsupervised.md` opens by naming. Human asked for a command that
works the queue until finished.

## Decisions

- The command supplies the LOOP; `JOHARNESS_MODE` supplies the STOPPING
  CONDITION it already defines. Requester's call, and it avoids inventing a
  third policy beside supervised and unsupervised.
- Width is not a knob. It is already the mode's — supervised drains serially,
  unsupervised carries the queue hook's existing fan-out order. A separate
  axis would let a repo ask for fan-out under supervised, which is the mode
  boundary the requirement calls byte-identical. Evidence: the reported
  failure is longitudinal and fan-out is lateral; it widens a generation
  without lengthening the chain.
- `drain` derives nothing. It runs the two hooks that already rank the queue
  and the in-flight edge, and reads their answers.
- Edge work is REPORTED, not stopped on. Stopping would spin forever on an
  edge branch owned by a live session, which is not this session's to merge
  (step 7). Flagged to the human as a reversible call.
- Fixed a red `main` first, as its own pull request (#130), rather than
  folding it into this branch.

## Rejected

- Parsing a fourth queue inside `joharness.sh`. `cmd_graph` and the graph lint
  already each derive blocked/free; a fourth would be the copy that rots.
- Making the banner print trailing slashes to satisfy the stale assertion in
  #130. `protocol_paths` is also consumed by `handover-guard.sh` for path
  matching; changing its output to fix a test is the tail wagging the dog.

## Review

opus, adversarial, separate lenses (correctness, then contract coupling, then
perf). Findings written before their fixes, committed with them.

- r1: `drain_next` used `s|...|` as its sed delimiter, which collides with
  BRE's `\|` alternation — the expression silently matched nothing and
  reported a full queue as DRAINED. The command's entire job, inverted, and
  quiet about it: a drain loop would have stopped on its first iteration
  every time. Delimiter changed to `#`. (fixed)
- r2: two assertions keyed on the bare word `DRAINED`, which is a substring
  of `NOT DRAINED` — so the supervised-drained test passed against r1, the
  exact bug it existed to catch. Both now assert the full line. (fixed)
- r3: the perf-row comment was written INSIDE the row list, which is one
  command's `\`-continued argument list — a leading `#` there is an argument,
  not a comment. It fed `printf` five junk rows and emptied the table for
  every filtered lookup; 5 perf tests red. Moved above the block. (fixed)
- r4: the new topic file was untracked, and the runner enumerates topics from
  `git ls-files` on purpose ("an interrupted edit is not a topic"). The suite
  refused to run rather than silently skipping — correct behaviour, recorded
  because the next topic author will hit it too: `git add` the file before
  the first run. (no change)
- r5: `drain` couples to two hooks by their output wording — the
  `FINISH BEFORE STARTING:` line and the queue's row format. That coupling is
  real and deliberate (the alternative is a fourth reader), and it is pinned:
  the fixture builds a real queue, so a reworded row breaks these tests rather
  than emptying `drain` in silence. (wontfix, tested)
- r6: no test covered a CLAIMED plan reaching `next:`, which would send a
  second session at work another session holds — the duplication
  claim-by-push exists to prevent. Two cases added; both go red with the
  filter removed. (fixed)
- r7: the `.claude/agents/verifier.md` subagent step 5 asks for was NOT
  spawned. This session runs under an instruction not to call the Agent tool
  unless the human asks. Same open finding as the previous workstream;
  recorded rather than skipped silently. (open)

## Blockers

None.

## Where to look

- `joharness.sh:drain_next` — the delimiter, and why it is not `|`.
- `joharness.sh:cmd_drain` — the mode branch, and why the edge is reported
  rather than returned on.
- `.agents/docs/unsupervised.md` — the two halves table.
