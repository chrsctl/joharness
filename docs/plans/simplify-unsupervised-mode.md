---
plan: simplify-unsupervised-mode
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, joharness.conf, .gitignore, .agents/harness, .agents/docs, .claude/commands/drain.md, docs/product/unsupervised-mode.md
---

## Goal

Direct ask, 2026-09-02: "Simplify joharness, especially unsupervised mode."
Same-session plan; retired by the pull request that does the work.

Unsupervised mode grew by accretion — four endurance runs, each adding a
mechanism for the wall it hit. The result: three mode sources, two commands
that each print a stop rule, a stop condition with two parts nothing can
count, a sweep that runs `ci` and needed a recursion guard, and 600 lines
of requirement and design prose. Cut it to one switch, one boundary, one
reader of the queue that orders, two stops.

## Scope

- `joharness.conf` — mode back to `supervised` (attempt four ended; its
  branch reverts the same line), comment block cut to what a reader needs.
- `joharness.sh` — mode has two sources (conf, `$JOHARNESS_MODE`); the
  session-local marker, `mode <value>` and `mode default` go. `authority`
  reports mode, source, setting commit, merged verdict — nothing else.
  `sources` prints three counts and one verdict; no flags, no stop block,
  no recursion guard. `drain` owns both stops and the fan-out order and
  never runs the sweep. Banner points at `drain`. Help header follows.
- `.gitignore` — marker entry goes.
- `.agents/harness/queue-context.sh` — REPORTS in both modes. Keeps the
  SUPERVISED ONLY marking and rank; loses the edge order, the goal stop and
  the fan-out order (now `drain`'s).
- `.agents/harness/selftest/*` — topics follow: autonomy-mode, authority,
  sources, drain, queue-context-edge, queue-context-fanout,
  queue-context-supervised-only, and `selftest.sh`'s list and leak note.
- `.agents/harness/AGENTS.md` step 2 exception; `.claude/commands/drain.md`;
  `.agents/docs/plans/README.md` sources section; `.agents/docs/unsupervised.md`
  and `docs/product/unsupervised-mode.md` rewritten to the current state.

## Out of scope

- Removing the mode. The requester asked for simpler, not gone.
- The protocol boundary (`protocol_paths`, guard, marking). Attempt two
  paid 55 minutes for its absence; it stays whole.
- The goal bound and `lint_requirement_writes` / `lint_plan_advances`.
  Cheap, ratified twice, and the only thing that makes "done" statable.
- `docs/plans/unsupervised-endurance.md` — claimed on a live branch that
  retires it. Not touched.
- Anything outside unsupervised mode. Other simplifications get their own
  plan.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `JOHARNESS_MODE=unsupervised ./joharness.sh drain` on a clone with an
  open goal and no free plan — names the sweep and both stops, runs no `ci`.
- `./joharness.sh sources` — three counts, one verdict line, exit 0.
- `./joharness.sh mode unsupervised` — unknown subcommand.
- Plan `ci` calls SHIPS: `joharness.sh` and `.agents/harness/` sync to
  every consumer. Consumer check: `./joharness.sh mode` prints one word and
  `./joharness.sh drain` under supervised is unchanged.

## Where to look

- `joharness.sh:cmd_drain` — the one place the mode orders anything.
- `joharness.sh:cmd_sources` — counts and a verdict, nothing else.
- `joharness.sh:cmd_authority` — provenance of the conf line.
- `.agents/harness/queue-context.sh:qc_scope_class` — the marking that stays.

## Traps

- Protocol text: this plan edits it, so it is supervised work. Direct human
  ask = supervised; conf flips to say so in the first commit.
- Supervised output stays byte-identical at every mode read.
- Never skip a test to get green; a case that asserts deleted behaviour is
  deleted with the behaviour, not disabled.
