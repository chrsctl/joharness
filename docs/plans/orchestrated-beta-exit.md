---
plan: orchestrated-beta-exit
urgency: normal
agent: opus
effort: high
needs: orchestrated-run
requirement: orchestrated-mode
scope: joharness.sh, shared:joharness.conf, .agents/docs/orchestrated.md, .agents/docs/unsupervised.md, .agents/docs/product/README.md, .agents/harness, .claude/commands, .agents/scripts
---

## Goal

Requester, 2026-09-10: move orchestrated mode out of beta. The word is not
decoration — it is a claim about evidence. But this repo licenses it in
THREE places and they do not agree, one reads true today and one cannot be
discharged as written. So the strip is the second half of this plan. The
first half is deciding what the word meant, once, and that decision is the
work.

## The three licences — read before touching a file

Counted `git grep -n beta -- joharness.sh joharness.conf .agents .claude`
on this branch, 2026-09-10, hand-filtered to sites naming this mode.

**A. `.agents/docs/orchestrated.md:16`** — "this mode is the measured
alternative, and beta until a run shows **which** empties a queue faster."
Comparative. It needs two numbers. `.agents/docs/unsupervised.md` Runs
holds four peer-fleet runs, longest 60m, and says of all of them "Every
run measured how long ONE generation lasts. The bullet asks for hours, and
hours need the heartbeat below, which no run has had." **No peer-fleet
drain number exists, so this licence has no counterpart to compare against
and cannot be discharged by an orchestrated run alone.** Discharging it
needs either a peer-fleet drain measured too, or the sentence rewritten to
say what it actually waits for.

**B. `.agents/docs/product/README.md:202-211`** — "Until a run **is
counted** the peer fleet is the measured design and the orchestrator is
the hypothesis, which is what beta means here." Run 1 is counted, in
`.agents/docs/orchestrated.md` Runs, with wall-clock, managers, kills,
merges and cost. **Under this licence, read literally, the label is
already discharged.**

**C. `docs/product/orchestrated-mode.md`, last `Satisfied when`** —
started once over a stocked queue, every free plan merged, no human turn,
under the cap, numbers counted. Run 1 fails it in its own words: "Nothing
stopped it; the queue did not drain", 30 plans waiting, ended by a human
turn. **Not met.** Run 2 was in flight at one observation (2026-09-07) and
its row is unwritten.

The implementing session does NOT pick whichever it likes. Step one is to
put A, B and C in front of the human as they are written above and get one
answer: which condition governs, and does it read true. That is product
direction (`.agents/harness/AGENTS.md`, Decide alone) and the reason this
plan is `opus`. Record the answer and its date in the same commit as the
strip. Then make A and B say the SAME thing as each other — a mode whose
own docs define its beta three ways is the defect under this whole plan,
and stripping the labels without collapsing the definitions leaves it.

### What `needs:` does and does not buy

`needs: orchestrated-run` is NECESSARY, NOT SUFFICIENT, and the difference
matters. The edge releases when `docs/plans/orchestrated-run.md` is
DELETED (`.agents/docs/plans/README.md`: file existence IS the edge). That
plan's Acceptance asks for "one new row with every column counted" and
says "A human turn during the run ends the measurement there" — so a run
that ends early, counts its row and drains nothing satisfies it fully,
retires it, and unblocks THIS plan with C still false. Run 1's row is
already fully counted, so that plan is arguably retirable today.

**So the first Acceptance bullet below is a hard stop, and no DAG edge can
enforce it.** A session that finds the gate false stops, writes what it
found in its workstream file, and hands back. It does not strip.

## Scope

24 line-sites, 12 files. Named by their text, not their line number —
`lint_anchors` checks the path only, so a stale number stays green forever
and this plan is blocked for days by design. Re-run the grep above.

- `.agents/docs/orchestrated.md` — the title (`# Orchestrated mode
  (beta)`); **licence A**, which is rewritten, not deleted; "a beta mode
  the interview never offers"; "Revisit when the mode leaves beta", whose
  whole subject is this transition; "not a beta path" in the `authority`
  paragraph.
- `.agents/docs/product/README.md` — **licence B**, both lines: "exists as
  a beta, and the peer position stays the default" and "which is what beta
  means here". This file states the peer/lead position for the whole
  product; if the lead is no longer a hypothesis, this paragraph is the
  one that has to say so.
- `.agents/docs/unsupervised.md` — "A third value, `orchestrated` (beta)".
- `.agents/harness/AGENTS.md` — Loop step 2's `(beta)`.
- `.agents/harness/README.md` — the docs-index row for `orchestrated.md`.
- `.agents/harness/selftest/orchestrated.sh` — asserts the session-start
  banner string LITERALLY. Same commit as the banner or the suite reds.
- `joharness.sh` — the usage block; the `run_mode` comment (spelled
  `orchestrated (beta:` with a colon, which a `(beta)` grep misses); "else
  the beta default" in the knob comment; the session-start banner
  `== Mode: orchestrated (beta) ==`.
- `joharness.conf` — "Orchestrated (beta):" above the knob block. A
  protocol path, and marked `shared:` because `orchestrated-run.md`
  declares `joharness.conf` too: it flips the mode for the run and back.
  Expect a reconcile there, not a collision.
- `.claude/commands/orchestrate.md` — the role header, and "The beta run
  flips the mode", which names a specific run and may become false rather
  than merely unlabelled.
- `.claude/commands/manage.md`, `upstream-report.md` — role headers.
- `.agents/scripts/conf-keys.sh` — the `JOHARNESS_MODE` gloss.
- `.agents/scripts/bootstrap-consumer.sh` — "an off-by-default beta
  mechanism" (the comment explaining why the interview asks nothing),
  "orchestrated (beta), is set by hand after reading", and the
  `--help` line "Any value but unsupervised or orchestrated (beta)".

## Out of scope

- **The quoted rejected draft, BOTH halves.** `joharness.sh` ("An earlier
  draft reported anyway \"for a human running / the beta loop by hand\"")
  and `.agents/harness/selftest/dispatch.sh:801` are the same quotation,
  split across two files. It is a record of a wording this repo REJECTED.
  Editing either half destroys what it exists to keep. Neither is a label.
- `.agents/harness/selftest/orchestrated.sh`'s bad-value list, which
  carries the literal string `orchestrated-beta` as a value that must fail
  closed. Stripping it deletes a test case.
- `docs/product/orchestrated-mode.md`'s `(beta)`: inside the requester's
  transcribed words, a record of what was asked. A session writes no
  requirement of its own and does not edit one to read better.
- Deleting `docs/product/orchestrated-mode.md` — `orchestrated-run.md`
  owns that when every bullet reads true.
- Making orchestrated the DEFAULT anywhere: not the conf's value, not
  `run_mode`'s fail-closed fallback, not the consumer bootstrap. Out of
  beta is a claim about evidence; default is a separate decision, asked
  2026-09-10 and not answered.
- Changing behaviour. This plan moves words and rewrites two paragraphs.
  A code change found necessary is a finding and a new plan.

## Acceptance

- **Gate first, and it is a stop.** The human's answer to A/B/C is
  recorded in the diff with its date, and the condition it names reads
  true. False, or unanswered: this plan does not proceed, and the session
  says so in its workstream file. Nothing below is reachable without this.
- `git grep -n beta -- joharness.sh joharness.conf .agents .claude`
  returns no hit naming this mode except the quoted rejected draft (two
  halves) and the bad-value fixture. Read the output, do not pipe it
  through a filter that hides what it did not expect — the count above was
  wrong once already for exactly that reason.
- `.agents/docs/orchestrated.md` and `.agents/docs/product/README.md`
  agree, in one sentence each, on what discharged the label and when. Two
  files, one claim, no third spelling.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed. The diff touches non-`*.md` files
  under `joharness.sh`, `.agents/harness/` and `.agents/scripts/`, so step
  7 requires it.
- `.agents/harness/selftest/orchestrated.sh` green on the new banner and
  RED against the old: revert the banner alone, run the suite, put it
  back. Green both ways = the assertion pins nothing.
- **Consumer-side.** `ci` calls this plan SHIPS. `.agents/scripts/` is in
  `sync-to-consumer.sh:CANONICAL_ONLY_DIRS` and never leaves this repo, so
  `conf-keys.sh` and `bootstrap-consumer.sh` are NOT how consumers learn
  this. What ships is `.agents/docs/`, `.agents/harness/`, `.claude/` and
  `joharness.sh`. Verify in a consumer: sync, then
  `JOHARNESS_MODE=orchestrated ./joharness.sh session-start` prints a
  banner with no "beta", and `./joharness.sh ci` passes there.

## Where to look

- `.agents/docs/orchestrated.md:Runs` — run 1's numbers, run 2 unwritten.
- `.agents/docs/unsupervised.md:Runs` — the four peer runs, and why
  licence A has no counterpart number.
- `docs/product/orchestrated-mode.md:Satisfied when` — licence C.
- `docs/plans/orchestrated-run.md:Acceptance` — what actually retires it,
  which is weaker than licence C.
- `joharness.sh:run_mode` — the fail-closed switch. Unchanged here.
- `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS` — why two
  scoped files reach no consumer.

## Traps

- Protocol paths are in `scope`, so this plan is `SUPERVISED ONLY`: a
  session running unattended may not commit it
  (`./joharness.sh protocol-paths`).
- `needs:` releases on a file being deleted, not on a queue being drained.
  The gate is the first Acceptance bullet and nothing enforces it but the
  session reading it.
- Banner and its assertion in one commit. Split, and the suite reds on a
  commit that is correct.
- Stripping the label while any governing licence reads false makes this
  repo assert something it measured false. That is the failure this plan
  exists to avoid, not a formality.
- Trust counted numbers, never written numbers — including the 24 and the
  12 in this file. Re-run the grep.
