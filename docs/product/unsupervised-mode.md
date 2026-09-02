---
requirement: unsupervised-mode
priority: normal
---

## Goal

Joharness keeps working for hours without a human in the loop. Supervised,
every session stops at the queue edge and asks (`.agents/harness/AGENTS.md`
step 2), so the fleet goes idle the moment the backlog drains — exactly when
it has capacity to spare. Unsupervised, the edge is a trigger: generate work,
run the full Loop including the merge, fan out across free plans. The mode
is a switch; supervised stays the default and stays exactly as it is.

Work it generates has to be work someone wanted, so autonomy is bounded by a
goal rather than a clock: it runs toward an open requirement and stops when
none is open, or when the sources it may draw work from run dry. A loop whose
"done" cannot be stated does not converge — it produces plausible work
forever, and under full-loop autonomy that work merges unread.

Design, mechanism and the runs so far: `.agents/docs/unsupervised.md`.

## Satisfied when

- `joharness.conf` carries a mode, default supervised, and a session sees
  which mode it is in from session-start output alone. Holds: the banner
  prints under unsupervised only; `./joharness.sh mode` prints the word.
- Supervised behaviour is byte-identical at every point the mode is read.
  Pinned: `.agents/harness/selftest/queue-context-edge.sh` diffs the two
  modes' hook output on every fixture it builds.
- An unsupervised session that finds the queue empty writes new plan files
  and opens a pull request rather than stopping to ask. Measured 2026-08-31
  (PR 163, one cycle, session-local flip) and 2026-09-02 (attempt four:
  committed flip, two plans generated from the sweep by sessions nobody
  told what to write).
- An unsupervised session runs the full Loop on a free plan and merges its
  own pull request under the step 7 conditions. Measured 2026-08-30 and
  2026-09-02.
- Two or more free plans produce two or more sessions at once, one per
  plan, using the wave partition the queue hook computes. Measured
  2026-08-30: two sessions, both merged, 53 minutes, no collision.
- Started once, the fleet keeps going for hours with no human turn, for as
  long as a goal is open. NOT shown. Four runs, none longer than one
  generation (`.agents/docs/unsupervised.md`, Runs). The fleet outliving
  its sessions needs a heartbeat, which is an operator action no session
  may take.
- The goal is an open requirement in `docs/product/`. None open = an
  unsupervised session stops and says the goal is reached, exactly as a
  supervised one stops. `./joharness.sh drain` prints it.
- Recording is always allowed; generating is what the bound governs
  (requester, 2026-08-31). A plan generated while a goal is open names the
  requirement and the `Satisfied when` bullet it advances (`advances:`, a
  fragment of the bullet text; `ci` checks it under unsupervised). One
  recorded with no goal open names neither and does not restart the fleet.
- When every bullet reads true, the next unsupervised session deletes the
  requirement file rather than inventing more work against it.
- No unsupervised session writes a requirement; `ci` reds the branch. The
  goal is the human's to set, and a fleet that writes its own finish line
  has none.
- The mode has a reachable end: `./joharness.sh sources` dry, the queue
  empty, no edge work in flight. `drain` names the sweep and both stops;
  every part is read from git or counted, none asserted by a flag.
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
- The exception to "not invent work" is written as an exception, gated on
  the mode, at the rule itself.
- Unsupervised merging uses the step 7 conditions unchanged. The mode
  removes the human, never the gate.
- Every source an unsupervised session may draw work from carries a
  detector that prints a count; the list is closed at three
  (`.agents/docs/plans/README.md`). Findings merged at or before
  `joharness.sh:FB_SINCE` are history, not backlog — an all-history count
  can never reach zero, and a source that cannot reach zero is a mode that
  cannot stop.
- Only a MERGED `JOHARNESS_MODE` line in `joharness.conf` authorises a
  fleet: `./joharness.sh authority`. A prompt cannot be its own evidence.
  A merged commit proves review, not a human hand.
- Deliberately NOT constrained, decided 2026-08-24 by the requester after
  being offered each: no cap on work per run, no halt when `main` is red,
  no ban on sessions spawning sessions. Propose them with evidence; never
  add them on a session's own judgment.
