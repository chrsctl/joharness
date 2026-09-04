---
workstream: consumer-mode-ask
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: consumer-mode-ask
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Requester asked for an automatic mode that drains the queue with no human turn
between items, then narrowed it: it must be a switch that is off by default,
and the copy into a child must ask for it. The mode exists; the ask does not.

## Decisions

- **The mode itself is not rebuilt.** `JOHARNESS_MODE=unsupervised` already
  does what was asked at the session level, and `run_mode` already fails
  closed. Only the child-side ask is missing.
- **Canonical stays supervised.** "Not enabled by default" is the requirement,
  and flipping this repo would be a separate operational act with the
  heartbeat's spend attached.
- **A single session looping over items was rejected** in favour of the
  existing fresh-session-per-item shape. The reason is measured, not
  stylistic: compaction preserves task state and drops the rules, violations
  move from 0% to 38% when the constraint is dropped from the summary, and the
  decay is 8.3x worse for soft organisational policy, which the Loop is
  (`.agents/docs/handover/README.md`, Compaction).
- **The whole-clone path forces the answer rather than inheriting it.**
  `JOHARNESS_ENV` is rewritten only when `--env` says so, because silently
  forcing `none` would strip a deliberate selection. The mode is the opposite
  case: inheriting canonical's autonomy is precisely the failure `run_mode`'s
  own comment names, a fleet working unattended in a repo that never asked.

## Rejected

- **Seeding the mode line and stopping there.** `seed()` never overwrites, so
  a target carrying its own conf silently kept whatever it already said while
  the run reported success. Review r1. One writer now serves both shapes.
- **A single session looping until the queue is empty**, which is the literal
  reading of the request. Rejected on the compaction measurement above, and
  because the harness already has the shape that survives it. Recorded here
  because the next person asked for automatic draining will reach for the loop
  first.
- **Creating the heartbeat Routine from the bootstrap.** It is what would make
  the answer do something, and it is recurring spend. The script says what to
  create and never creates it.

## Review

Sonnet depth: `/code-review` (high) on the full diff, plus the harness verifier
reading it cold. Twelve findings between them; the two readers found different
things and neither found the other's, which is the argument for running both.

- r1: (code-review) **Fresh mode dropped the answer it was given.** The seeded
  conf goes through `seed()`, which never overwrites, so a target that already
  carried a `joharness.conf` kept whatever autonomy line that file held —
  `--mode supervised` against a conf saying `unsupervised` exited 0, printed
  "ready", and left it unsupervised. The same fail-open the whole-clone branch
  was written to prevent, one shape over, and silent. No case covered it.
  (fixed: one `set_conf_mode` writer, used by both shapes; the fresh path
  records whether the conf pre-existed BEFORE the seed, since the seed is what
  makes the difference invisible afterwards)
- r2: (code-review) **The question went to stdout** while `log`, `warn` and
  `die` all use stderr, so `bootstrap-consumer.sh <dir> > log.txt` from a
  terminal blocked on `read` with a blank screen and the question sitting in
  the file. (fixed: the prompt is on stderr, and a pty case runs the script
  with stdout to `/dev/null` and requires the question to still appear)
- r3: (code-review) **The dry-run check sat above the terminal check**, so a
  dry run with no terminal promised "would ask for JOHARNESS_MODE" where the
  real run in that same context says "not a terminal". The selftest pinned the
  wrong sentence: `boot()` closes stdin, so the case asserting "would have
  asked" was asserting the bug. (fixed: terminal check first, the case now
  asserts the sentence the real run prints, and a pty dry run covers the other
  half)
- r4: (verifier) **The workstream file was not in the implementing commit** and
  its `## Review` was an unfilled placeholder while `next:` still described
  work already done. Step 5 and step 6 both require it in the SAME commit.
  (fixed: this section and the frontmatter land with the review fixes)
- r5: (verifier) **A dry run against a directory that does not exist yet never
  mentioned the mode.** That branch exits before the resolver ran, so the most
  ordinary preview of a new consumer reported every seed except the one this
  flag decides. Every existing dry-run case `mkdir -p`s the target first, so
  nothing covered it. (fixed: the resolver is defined earlier and made
  idempotent, that branch calls it, and the log names the mode; a case previews
  a genuinely missing directory)
- r6: (verifier) **The rewrite strips the edited line's `\r` in a CRLF conf**
  and leaves its neighbours CRLF, so the file ends mixed. (wontfix here, named
  in the code: `conf_get`'s capture stops at the carriage return — checked
  directly, `JOHARNESS_MODE=unsupervised\r\n` reads back as `unsupervised` —
  and the `JOHARNESS_ENV` rewrite three lines up has always done the same.
  Fixing it is one change for both keys and belongs to whoever does that one)
- r7: (verifier) **The substitution rewrites every matching line**, not the
  first, so a conf carrying the key twice has both rewritten. (no change
  needed: both land on the same resolved value, `conf_get` reads with
  `tail -1`, and `joharness.sh:conf_set` uses the identical idiom — matching
  the codebase is the right answer here)
- r9: (self, from the injection pass) **The case added for r5 passed for the
  wrong reason.** It previewed a missing directory with `--mode unsupervised`,
  and a given flag is already set at parse time, so the log named the mode
  whether or not the branch reached the resolver — `mutate` on that call site
  redded nothing. A case green both ways pins nothing, which is the rule that
  caught it. (fixed: the same preview without a flag, where the resolver is
  the only thing that speaks; the injection then reds exactly it)
- r8: (code-review) The header's "Exit: 1 refused with nothing written" list
  never gained the new invalid-`--mode` refusal. (fixed)

Checked and reported clean by the verifier, recorded because a later reader
should not re-derive them: `read -r ans || ans=''` survives a closed stdin
under `set -euo pipefail`; the resolver runs strictly after every refusal that
can `die`, so a run that is going to fail never stops to ask first; no other
caller of this script exists in the tree, so the selftest's `boot()` is the
only path that could have blocked; the whole-clone dry run is byte-identical
by checksum; and `AUTONOMY` is validated against two literals before it ever
reaches a `sed`, so the delimiter cannot be injected.

## Blockers

None.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh` — first contact; seeds a fresh conf
  inline and rewrites a whole clone's.
- `joharness.sh:run_mode` — the fail-closed reader of that conf.
