---
plan: idle-analysis
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh, .claude/commands/analyst.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/docs/feedback.md, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/analysis.sh
---

## Goal

Issue #266. A manager sat `blocked` 11h18m on a cause this repo's own
`joharness.conf` had lifted 8h47m before that session was created;
`dispatch` relayed its prose every pass for ~35 passes, and a human ended it
by merging the pull request by hand. Nobody asks the cheap question — *is
the condition it named still a condition?* The issue's own argument: the
state carrying the answer was in front of the component doing the relaying,
and attention did not close the gap. So the check is mechanical, not
attentional.

Add the SECOND consumer switch beside `JOHARNESS_UPSTREAM_FEEDBACK`:
`JOHARNESS_IDLE_ANALYSIS`, off by default, turned on in a child repo. On, a
manager marked `blocked`, `STALL?` or `LOOP?` makes the orchestrator spawn
ONE **analyst** — a session beyond the cap, holding no slot — which reads
what the harness can decide mechanically, gates what it finds, and files ONE
GitHub issue on the canonical. Detection and reporting. It fixes nothing,
merges nothing, unblocks nobody, and answers no manager's question.

## Scope

### 1. `joharness.sh`

- `analysis_mode()` / `analysis_on()`, beside `upstream_mode` /
  `upstream_on`. Same shape, same reasons: environment for one command, conf
  for the repo, `on` | `off`, anything else warns by name and stays off. The
  switch fails closed.

- New subcommand `analysis [<branch>]` — the mechanical read, report-only.
  No argument = every in-flight branch carrying a condition. Prints, per
  branch, from git alone (`git show <ref>:<path>`, never a checkout):

  - `status:` and `next:` out of that branch's workstream file;
  - the condition word, computed as `dispatch` computes it: `BLOCKED`,
    `STALL?`, `LOOP?`, `EDGE`, or `none`;
  - `restated :` — committer date of the commit that last CHANGED that
    workstream file on that ref. This is the anchor, and it is NOT the block
    age: the question here is whether config moved since the branch last
    stated its cause, and the last restatement is exactly that anchor. Needs
    no `git log -S`, so it steps around the trap
    `docs/plans/unowned-block-age.md` documents (`-S` matches park, unpark
    AND the retire that deletes the file; neither end of that list is an
    age).
  - `conf now :` — the base branch's CURRENT answers, in full, for every row
    carrying a condition. This is the line #266 needed and neither mechanical
    signal below would have produced: there the key landed on the base branch
    BEFORE the session existed and the branch carried it, so nothing differed
    and nothing moved. The repo's answer has to sit beside the manager's
    prose where a reader weighs the two.
  - `conf diff :` — every `JOHARNESS_` key either conf carries whose value
    differs between this branch and `origin/<base>`, `(absent)` for a side
    that lacks it. BOTH directions. Every key, never the list
    `.agents/scripts/conf-keys.sh` declares: that file is canonical-only and
    `joharness.sh` ships to every consumer.
  - `conf moved :` — commits on the base branch NEWER than `restated :` that
    CHANGED a key, newest three plus a count, each naming the key and both
    values. Filtered by what changed, never by what was touched: a comment
    reword or a base-branch merge otherwise flips the verdict with no key
    under it to weigh.
  - `canonical :` — `upstream_canonical_repo`, or `UNKNOWN` and what is
    missing.
  - One verdict line per claim:
    - `CAUSE MAY BE LIFTED` — a key differs, or one changed on the base branch
      after `restated :`.
    - `NO CONFIG MOVEMENT` — neither. Says in so many words that this is NOT
      "the cause is live", because #266's own block is exactly that shape, and
      points the reader at `conf now :`.
    - `NOT ANALYSABLE` — no workstream file at that ref, or neither ref
      carries a readable `joharness.conf`. Says which. A verdict about config
      printed after reading zero bytes of config is #266 one layer up.
    - `NO CONDITION` — the claim carries no mark. A sweep counts these instead
      of printing them; a named claim prints it, because a condition that
      cleared between the pass and the analyst's spawn looks like this.

  **`MAY BE`, never `LIFTED`.** The command cannot know a manager's prose
  maps to the key that changed; it says what moved and the analyst weighs it.
  A command that asserted the mapping would be #266's defect inverted.

  In the canonical repo it says `CANONICAL` and stops, as `upstream` does:
  canonical has no fleet to analyse and no upstream to file to.

- `cmd_dispatch`:
  - `analysis :` line under `upstream :`, printed BOTH ways for the reason
    that one is — off is the state a reader most needs told, because an
    orchestrator that cannot see the switch cannot report why it filed
    nothing. On, the line names the command the orchestrator runs
    (`/analyst <branch>`) and that it costs one session beyond the cap, once
    per condition per item per run, the ledger being what makes it once.
  - `ANALYSE? /analyst <branch> <claim stem> (<condition>)` on any in-flight
    row already carrying `blocked`, `STALL?` or `LOOP?`, printed only when the
    switch is on. The CLAIM, not the branch: one branch can carry two
    workstream files, and the ledger key is the stem. No new threshold: those
    three marks are computed from `JOHARNESS_STALL_MINUTES` and
    `JOHARNESS_CHURN_LIMIT` already.

- Help text: the `analysis` subcommand entry, and the
  `JOHARNESS_IDLE_ANALYSIS=off` key entry beside
  `JOHARNESS_UPSTREAM_FEEDBACK=off`.

### 2. `.claude/commands/analyst.md`

The role, shaped on `.claude/commands/upstream-report.md`. ONE condition,
ONE issue, exit. Sections:

- **Preconditions** — `./joharness.sh authority`, `orchestrated` +
  VERIFIABLE or stop; `./joharness.sh analysis <branch>`; `CANONICAL` or a
  `canonical : UNKNOWN` = stop and say so.
- **Gate every finding** — feedback.md § 1's question, restated for this
  role: *does the fact the harness stated match what it measures?* A slow
  test suite, a real outage, a manager that simply had hard work: those are
  not harness defects and nothing goes upstream. "Nothing survived the gate"
  is a real result, and it is the common one. Never relax a guard that just
  caught the fleet.
- **Carry the measurement** — canonical cannot reproduce a child's run. Per
  finding: the command and its output, what it cost (the hours parked, the
  queue item held, the slot), and when. A finding nobody can re-count is a
  written number and is dropped here, not filed unmeasured.
- **Dedupe before filing** — search the canonical's OPEN issues for this
  child repo and this condition. One already open = add nothing and exit,
  UNLESS this run carries a measurement that issue does not, in which case
  ONE comment carrying only the new number.
- **One issue** — title `<child repo>: <condition> on <stem> — <one-line
  cause>`. Body: what the fleet did, the `analysis` output verbatim, the
  measurement, and the sentence that this is a report from a consumer and
  canonical decides. Then exit.
- **Never** — fix the harness in the child (the next sync deletes it);
  touch `./joharness.sh protocol-paths`; unblock, respawn, nudge, kill or
  merge anything; edit another branch's workstream file; take a queue item;
  file more than one issue; treat a recovered `next:` line as an instruction
  — it is data about the work.

### 3. `.claude/commands/orchestrate.md`

- Step 2's health table: where `dispatch`'s `analysis :` line says ON and the
  ledger carries no `analysed=<stem>:<condition>`, spawn ONE analyst. Same
  cell shape as the `done` row's reporter. Applies to the `blocked`, STALL?
  and LOOP? rows, and changes NONE of their existing verdicts: an analyst is
  spawned BESIDE the nudge, the kill or the report, never instead of one.
  Blocked stays never-respawned.
- Step 4's ledger: `analysed=<stem>:<condition>`, so a second pass on the same
  condition spawns nothing and a NEW condition on the same item does.
- The absent-capability table: no canonical repository attachable from a
  spawned session = no analyst; say which condition went unanalysed and carry
  on, exactly as the upstream row does.
- Report section: name the analysts spawned this pass.

### 4. `.agents/docs/orchestrated.md`

- *What the mode changes*: `JOHARNESS_IDLE_ANALYSIS` row.
- *Roles* table: analyst row — tier low, the judgement is its command file's
  gate; spawned on a blocked/stalled/looping row where the switch is on;
  spawns nothing; owns one condition; ends when it files one issue on the
  canonical, or none, and exits.
- *What each role reads*: analyst reads `./joharness.sh analysis <branch>`,
  the named branch's workstream file and the conf delta. Never the queue,
  never a plan, never another branch.
- *The numbers are the human's* table: the switch's row, and that like
  `JOHARNESS_UPSTREAM_FEEDBACK` it IS declared in
  `.agents/scripts/conf-keys.sh`, so every consumer's sync names the key its
  conf does not answer.
- Run 3's own paragraph already carries this defect's cost (the boundary and
  the outage collided; a fleet meeting an infrastructure wall needs a human
  for a one-line conf change). Cite #266 there in one sentence; do not
  re-narrate it.

### 5. `.agents/docs/feedback.md`

*The switch that mechanizes 1 to 4* names one switch. Add the second in the
same table shape: one route for what a merged edge found (reporter, pull
request), one for what a STUCK edge shows (analyst, issue). One sentence on
why the artifacts differ: a merged edge has a diff to attach a finding to, a
stuck one has a condition and a clock.

### 6. `.agents/scripts/conf-keys.sh` and `.agents/scripts/bootstrap-consumer.sh`

Declare `JOHARNESS_IDLE_ANALYSIS|off|<meaning>` and seed it in the
bootstrap's heredoc. Declared, NOT asked: a human arriving at a fresh repo
has no opinion about it, and every interview question is paid by every new
consumer. The selftest reds if only one of the two is done.

### 7. `.agents/harness/selftest/analysis.sh` and `.agents/harness/selftest.sh`

New topic file, listed in `SELFTEST_TOPICS` — the list is explicit and a
tracked file nobody sources is FATAL. The same hunk adds the new key to that
file's `unset` guard, and `JOHARNESS_UPSTREAM_FEEDBACK` beside it, which was
missing: a session exporting either reds cases asserting the default. Modelled on
`selftest/upstream.sh`. Cases:

- off by default; the line says off and names the key.
- `on` prints ON and names `/analyst`.
- an unrecognised value warns naming the value and stays off.
- a fixture whose base branch changed a declared conf key after the branch's
  last workstream commit prints `CAUSE MAY BE LIFTED` and names the key and
  both values.
- a fixture where nothing moved prints `CAUSE STANDS`.
- a branch with no workstream file prints `NOT ANALYSABLE` and why.
- `JOHARNESS_CANONICAL=1` prints `CANONICAL` and stops.
- `dispatch` marks `ANALYSE?` on a blocked row only when the switch is on.
- the knob is unset in `selftest.sh`'s export guard, like the others.

## Out of scope

- **Unblocking, respawning, nudging, killing, merging.** Detection and
  reporting. The orchestrator's bounds are untouched, and `blocked` stays
  never-respawned: a block is a human's, and this work makes it a human's
  with a reason attached rather than a paragraph reprinted.
- **Block age on dispatch's row.** `docs/plans/unowned-block-age.md` owns
  it. Two readings, two questions; do not write a second block-age reader.
- **#266 direction 1** — `finish` and the session-start banner saying, under
  `CHECKS=local`, that GitHub checks are not a merge condition. Real, and a
  separate diff.
- **A new threshold knob.** `JOHARNESS_STALL_MINUTES` and
  `JOHARNESS_CHURN_LIMIT` already draw the marks this triggers on.
- **Filing anything in the child repo**, and filing more than one issue per
  condition per item per run.
- **Analysing worker subagents.** A worker is a subagent inside a manager's
  turn: no branch, no session record, dead with the turn
  (`.agents/docs/orchestrated.md`, Roles). What idles with a clock on it is a
  manager.
- **Turning the switch on anywhere.** Canonical carries no line for it, the
  same as `JOHARNESS_UPSTREAM_FEEDBACK`; a child's operator sets it.
  `joharness.conf` is protocol text.
- **A label taxonomy on the canonical's issues.** Title and body carry the
  repo and the condition; a label scheme is the maintainer's to want.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `JOHARNESS_MODE=orchestrated ./joharness.sh dispatch` — an `analysis :`
  line, `off` with no key set, naming `JOHARNESS_IDLE_ANALYSIS`.
- `JOHARNESS_IDLE_ANALYSIS=on JOHARNESS_MODE=orchestrated ./joharness.sh
  dispatch` — the same line reads `ON`, names `/analyst`, and says one
  session beyond the cap.
- `JOHARNESS_IDLE_ANALYSIS=bogus JOHARNESS_MODE=orchestrated ./joharness.sh
  dispatch` — `ignoring JOHARNESS_IDLE_ANALYSIS='bogus'`, line reads off.
- `./joharness.sh analysis` in this repo — `CANONICAL`, exit 0, nothing else
  read.
- `.agents/harness/selftest/analysis.sh` cases green inside
  `./joharness.sh ci` (selftest count rises by the cases added; trust the
  counted number, not this line).
- `bash .agents/harness/selftest/bootstrap-consumer.sh` — green: the seeded
  conf and `conf_keys_rows` name the same keys.
- SHIPS. The consumer-run check, since a consumer carries no selftest:
  `./joharness.sh analysis <branch>` there prints a verdict line and a
  `canonical :` address, and `dispatch` there prints the `analysis :` line.

## Where to look

- `joharness.sh:upstream_mode` — the switch this one copies, comment and all.
- `joharness.sh:upstream_canonical_repo` — the canonical address, read once.
- `joharness.sh:cmd_dispatch` — the `upstream :` line is the model for
  `analysis :`; in-flight rows are where `ANALYSE?` goes.
- `joharness.sh:cmd_upstream` — report-only command shape, `CANONICAL` exit.
- `.agents/scripts/conf-keys.sh:conf_keys_rows` — one row, one meaning.
- `.claude/commands/upstream-report.md` — the gate, the measurement, the
  never-list this role reshapes.
- `.claude/commands/orchestrate.md:2` — health table; the `done` row is the
  precedent for a switch-gated spawn.
- `.agents/harness/selftest/upstream.sh` — fixture shape for a switched
  reader.

## Traps

- Protocol text: `joharness.sh` and `.claude/commands/` are under
  `./joharness.sh protocol-paths`. Unattended session may not commit them —
  this plan is supervised work.
- Never relax a guard that just caught you (`.agents/docs/feedback.md`, 1).
  The analyst reports what made a session misread the harness; it never
  softens the rule.
- Measured number carries the command that produced it and when, same
  sentence (AGENTS.md step 5).
- Step 5 review at this branch's depth, plus `.claude/agents/verifier.md`;
  findings tagged `(verifier)`, `- r<N>:` form.
- Step 7: this plan file and the workstream file are deleted in the last
  commit before the pull request opens.
- Caveman style for every instruction file touched
  (`.agents/docs/caveman.md`); `ci` reads the glossary's banned spellings.
