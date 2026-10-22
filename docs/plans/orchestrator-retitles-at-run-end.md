---
plan: orchestrator-retitles-at-run-end
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

The requester's ask (2026-10-22): an orchestrator session that has finished
its run is titled so it reads as done. Today a session that ends at
`DRAINED` or at a `PAUSED … exit` (final report, arms nothing), or that a
human stopped, keeps the title `orchestrator: <owner/repo>`, so the session
list shows finished orchestrators as if they were live. Such a session sets
its own title to `orchestrator (retired): <owner/repo>` as its last act,
the spelling the keeper's SWAP already uses; a session that exits at "## 0.
Start" step 3 (an older LIVE one exists) takes `orchestrator (duplicate):
<owner/repo>`, the spelling Pass entry's Duplicate already uses for that
verdict. Pass entry's Retired then makes any wake that still fires do
nothing, and the one-orchestrator checks need no new verdict: a retired or
duplicate title was never LIVE.

## Scope

Every quoted sentence below is text to add or replace verbatim; the
selftest pins it. Keep every needle `.agents/harness/selftest/orchestrated.sh`
already holds green: append sentences after a pinned one, never reflow or
split it (`tr '\n' ' ' | tr -s ' '` folds the file, so a line break inside a
needle is fine, a changed word is not).

- `.claude/commands/orchestrate.md` §4. Replace the paragraph `A pass that
  ends at DRAINED or PAUSED arms nothing; the out-of-band arm below carries
  `retire=yes` when the pending wake does.` with a paragraph opening `RUN
  END.` that says, in this order: `A pass that ends at DRAINED or PAUSED
  arms nothing.` — `Its last act, after the final report: `set_session_title`
  yours to `orchestrator (retired): <owner/repo>`, so the session list reads
  it as done and a wake that still fires does nothing (Pass entry,
  Retired).` — `The same last act closes a human's stop (below); "## 0.
  Start" step 3's exit spells it `orchestrator (duplicate): <owner/repo>`.`
  — `No `set_session_title`, or it is refused = report `not retitled: no
  set_session_title`, end the turn.` — `Retitling a session the keeper
  already retitled changes nothing.` — `A retired title is final: nothing in
  this file sets `orchestrator: <owner/repo>` on it again but SWAP step 2's
  rollback.` The `retire=yes` clause moves to the out-of-band arm's first
  bullet: `the new wake's … carries `retire=yes` when the pending wake does`.
- `.claude/commands/orchestrate.md` §4, out-of-band arm, second bullet.
  Replace `No wake is pending (the run already ended at DRAINED or PAUSED):
  treat it as a first start:` with `No wake is pending (the run ended and RUN
  END's retitle was refused; a retired title refuses the order above): treat
  it as a first start:`. The rest of the bullet stays. Settled: the
  human-ordered spawn after a run's end is gone with the title; the retired
  session answers by naming the LIVE orchestrator, as the paragraph before
  the arm already says, and the human orders it there or starts a fresh
  session on `/orchestrate` (`.agents/docs/orchestrated.md`, "Start each
  run fresh"). The bullet survives only for a session the retitle could not
  reach.
- `.claude/commands/orchestrate.md` §4, `Human says stop`. After `No
  `update_trigger` = report `pause heartbeat <id> or the keeper restarts the
  fleet`.` append `Then RUN END's retitle, last.` Settled: a manager still
  running after the stop sends its lead to a retired session, and §4's
  forwarding paragraph already covers that title: forwarded to the LIVE
  orchestrator, else `lead not forwarded: no live orchestrator`. No edit to
  that paragraph.
- `.claude/commands/orchestrate.md` §4, RETIRE. Replace `You never start an
  orchestrator and never retire yourself: the keeper does both in one turn`
  with `You never start an orchestrator, and past the pass count you never
  retire yourself: the keeper does both in one turn`. After that sentence's
  paragraph append `RUN END's retitle is no retire in this sense: a run's end
  has nothing in flight to hand over and starts no successor.`
- `.claude/commands/orchestrate.md` "## 0. Start" step 3. After `The older
  one proceeds, so two started together never both exit.` append `The exit's
  last act: `set_session_title` yours to `orchestrator (duplicate):
  <owner/repo>` (RUN END, §4).` After the LIVE definition's sentence ending
  `IDLE between passes is alive.` append `A retired or duplicate title (RUN
  END, SWAP) is never LIVE, whatever its `session_status`.` Settled, no edit:
  the `@new` rebuild reads `manager: <stem>` titles only, so the
  orchestrator's own title plays no part in it.
- `.claude/commands/orchestrate.md` Pass entry, Retired. Replace `(the keeper
  retired you, "## Keeper", SWAP)` with `(the keeper retired you at SWAP, or
  your own run ended, §4 RUN END)`. The verdict stays: report `retired:
  <title>`, do nothing, schedule nothing.
- `.claude/commands/orchestrate.md` "## Report, every pass". In the `fresh
  session is cheaper` clause, after `more than one hour earlier` insert `
  (RUN END's retitle refused; a retired title runs no pass)`.
- `.claude/commands/orchestrate.md` "## Keeper", SWAP heading. Replace `SWAP
  — the one place an orchestrator retires.` with `SWAP — the one place the
  keeper retires an orchestrator; a run's own end retitles itself (§4, RUN
  END).` Settled, no edit to the keeper's LIVE test: it reads the title
  `exactly`, so a retitled session fails it as an `IDLE` one already did;
  one more reason, same verdict. The two never meet: SWAP needs a pending
  wake, and a pass runs after its wake fired, so a session mid-final-report
  holds none.
- `.agents/docs/orchestrated.md`, "Start each run fresh". After `The retired
  session's next wake does nothing.` append `A run that ends on its own
  (DRAINED, a PAUSED exit, a human's stop) retitles itself the same way as
  its last act (`orchestrate.md` §4, RUN END): the session list reads it as
  done, a wake that still fires does nothing, and the keeper's LIVE test
  reads one more mismatch where it already read IDLE.` In the sentence `A
  resumed orchestrator whose last final report is over an hour old says
  `fresh session is cheaper`` append `, when RUN END's retitle was refused`.
- `.agents/harness/selftest/orchestrated.sh`. In the one-spawner `for
  needle in` list: replace the needle `You never start an orchestrator and
  never retire yourself` with `You never start an orchestrator, and past the
  pass count you never retire yourself`; add needles `RUN END.`, `Its last
  act, after the final report: `set_session_title` yours to `orchestrator
  (retired): <owner/repo>``, `not retitled: no set_session_title`, `A
  retired title is final`, `The exit's last act: `set_session_title` yours to
  `orchestrator (duplicate): <owner/repo>``, `A retired or duplicate title
  (RUN END, SWAP) is never LIVE`, `Then RUN END's retitle, last.`, `RUN
  END's retitle was refused; a retired title refuses the order above`, `SWAP
  — the one place the keeper retires an orchestrator`. In the `refute` list
  add `You never start an orchestrator and never retire yourself`, `SWAP —
  the one place an orchestrator retires.` and `No wake is pending (the run
  already ended at DRAINED or PAUSED)`. Add a line-order check like the
  retitle-before-spawn one: the line matching `^RUN END\.` comes after the
  line matching `^RETIRE\.` and before the line matching `^## Report, every
  pass`. In the `orchestrated.md spells` list add `retitles itself the same
  way as its last act`. Every needle grep-checked against the edited file
  before commit (the file's own comment says why).

## Out of scope

- The lineage stop at "## 0. Start" step 2 keeps its title: whether
  `set_session_title` works at `depth == limit` is unmeasured, and that
  session's push already names it.
- A session that stops at "## Tools" (`REQUIRED — absent`) or at step 1 or
  2 keeps its title: it never ran a pass; the keeper's LIVE test reads it
  IDLE.
- No `delete_trigger` on a pending wake at a human's stop: Pass entry's
  Retired makes it inert, and a retired session that deletes wakes is a
  write this file does not grant it.
- No new title spelling. `(retired)` and `(duplicate)` exist; a third
  (`(drained)`, `(stopped)`) would need every title reader taught.
- No change to `manage.md`, `joharness.sh`, dispatch's `DRAINED` or `PAUSED`
  lines, or the keeper's step 2 and 3.
- No retitle back to `orchestrator: <owner/repo>` on a human's later
  message: the human starts a fresh session (orchestrated.md, "Start each
  run fresh").

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed` (the diff touches
  `.agents/harness/selftest/`, so Loop step 7 needs it green).
- `bash .agents/harness/selftest.sh 2>&1 | grep -c 'FAIL'` — `0`.
- Negative, each new needle once: copy the repo to a scratch directory
  (`git worktree add /tmp/needle-check HEAD`), delete the one clause the
  needle names from the copy's `orchestrate.md` (or `orchestrated.md`),
  run `bash /tmp/needle-check/.agents/harness/selftest.sh 2>&1 | grep
  FAIL` — prints exactly that needle's `FAIL` line and no other; then
  `git worktree remove --force /tmp/needle-check`.
- Negative, line order: move the `RUN END.` paragraph above `RETIRE.` in
  the scratch copy — the order check FAILs.
- `tr '\n' ' ' <.claude/commands/orchestrate.md | tr -s ' ' | grep -o 'orchestrator (retired): <owner/repo>' | wc -l`
  — one more than the same pipeline over `git show
  origin/main:.claude/commands/orchestrate.md` prints (RUN END adds the one
  occurrence; Pass entry, the forwarding paragraph and SWAP already carry
  it). Measure both, trust the pair, never a written number.
- Plan `ci` calls SHIPS: `orchestrate.md` syncs to every consumer, so a
  consumer's next `./joharness.sh verify` runs the same orchestrated
  selftest; the check above is the one it runs.

## Where to look

- `.claude/commands/orchestrate.md:## 4. Schedule the next pass, then end the turn`
  — RETIRE, the `A pass that ends at DRAINED or PAUSED arms nothing`
  paragraph, the retired-forwarding paragraph, the out-of-band arm's two
  bullets, `Human says stop`: every §4 edit lands here.
- `.claude/commands/orchestrate.md:## 0. Start` — step 3's LIVE
  definition and exit; the `@new` rebuild it must leave alone.
- `.claude/commands/orchestrate.md:## Pass entry` — the Retired bullet
  and the order sentence `Run Retired first, then the superseded check`
  (pinned; keep).
- `.claude/commands/orchestrate.md:## Keeper` — step 2's LIVE test and
  SWAP step 1 (the spelling to reuse) and step 2 (the one rollback).
- `.claude/commands/orchestrate.md:## Report, every pass` — the `fresh
  session is cheaper` clause.
- `.agents/harness/selftest/orchestrated.sh:retitle_ln` — the line-order
  check to copy for RUN END; the `for needle in` lists above and below it.
- `.agents/docs/orchestrated.md:## Start each run fresh` — the paragraph
  that names the keeper's retitle; the sentence on `fresh session is
  cheaper`.

## Traps

- `./joharness.sh protocol-paths` names `joharness.conf`,
  `.claude/settings.json`, `.github`: this plan touches none; a commit
  under them is a red run.
- Caveman file: `.claude/commands/orchestrate.md` is read whole by every
  orchestrator pass. Add the sentences named, no why; why goes to
  `.agents/docs/orchestrated.md`.
- Glossary lint scans `.agents/docs/` and `.agents/harness/`: no banned
  spelling (`handover file`, `model tier`, `env layer`, `rescope manager`).
- A needle that never matched is indistinguishable from one that never
  will: grep each against the edited file before commit; the negative
  acceptance proves each fires.
- Pinned needles span sentences (`then exit, report its … The older one
  proceeds`): append after them, never inside.
- `authority` reads `.claude` against `origin/main`: run it once at the
  start, before the first edit, never as a re-check.
- The diff touches `.agents/harness/selftest/`: step 7 needs `verify`
  green, or a GitHub run that verified the selected layer.
