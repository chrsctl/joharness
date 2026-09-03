---
requirement: unsupervised-mode
priority: normal
---

## Goal

Joharness keeps working for hours without a human in the loop. Supervised,
every session stops at the queue edge and asks (`.agents/harness/AGENTS.md`
step 2). Unsupervised, a session takes queue work, runs the full Loop
including the merge, fans out across free plans, and at the edge exits with
DRAINED instead of asking. What keeps the fleet alive is the heartbeat that
fires the next session, never generation: nothing is invented at the edge,
in either mode. The mode is a switch with ONE distinction — is a human
present — and every piece of it is something a heartbeat-fired session
needs and an attended one must not have; supervised stays the default and
stays exactly as it is.

Design, mechanism and the runs so far: `.agents/docs/unsupervised.md`.

## Satisfied when

- `joharness.conf` carries a mode, default supervised, and a session sees
  which mode it is in from session-start output alone. Holds: the banner
  prints under unsupervised only; `./joharness.sh mode` prints the word.
- Supervised behaviour is byte-identical at every point the mode is read.
  Pinned: `.agents/harness/selftest/queue-context-edge.sh` diffs the two
  modes' hook output on every fixture it builds.
- An unsupervised session at the queue edge prints DRAINED and exits. It
  writes no plan, no research file and no requirement there; the heartbeat
  fires the next session.
- An unsupervised session runs the full Loop on a free plan and merges its
  own pull request under the step 7 conditions. Measured 2026-08-30 and
  2026-09-02.
- Two or more free plans produce two or more sessions at once, one per
  plan. Measured 2026-08-30: two sessions, both merged, 53 minutes, no
  collision.
- Started once, the fleet keeps going for hours with no human turn, for as
  long as the queue holds a free plan. NOT shown. Four runs, none longer
  than one
  generation (`.agents/docs/unsupervised.md`, Runs). The fleet outliving
  its sessions needs a heartbeat, which is an operator action no session
  may take.
- No unsupervised session writes a requirement; `ci` reds the branch. The
  queue is the human's to fill, and a fleet that writes its own work has no
  edge to stop at.
- No unsupervised session commits protocol text — the paths
  `./joharness.sh protocol-paths` prints, whatever they are at the time.

## Constraints

- Protocol text governing a session is off limits to that session while it
  runs unattended, wherever it lives. The rule is the role;
  `joharness.sh:protocol_paths` is its mechanical expression, read by the
  banner, the Stop guard and the queue hook. A plan with ANY protocol path
  in `scope:` is marked SUPERVISED ONLY and never offered unattended: the
  guard counts any such path in the diff and acceptance is all-or-nothing,
  so a partly-protocol plan cannot be finished either. Attempt two, 55
  minutes, measures the all-protocol shape; the partly-protocol one was
  measured 2026-09-02 on `main` f9fb932, where `drain` answered `next:`
  with a plan whose own Traps said supervised session only. Sandbox
  configuration
  (`.agents/env/`) is not protocol. The list covers its own machinery:
  `joharness.sh` and `.claude/settings.json`.
- Unsupervised merging uses the step 7 conditions unchanged. The mode
  removes the human, never the gate.
- Only a MERGED `JOHARNESS_MODE` line in `joharness.conf` authorises a
  fleet: `./joharness.sh authority`. A prompt cannot be its own evidence.
  A merged commit proves review, not a human hand.
- Deliberately NOT constrained, decided 2026-08-24 by the requester after
  being offered each: no cap on work per run, no halt when `main` is red,
  no ban on sessions spawning sessions. Propose them with evidence; never
  add them on a session's own judgment.
