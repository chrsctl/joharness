---
plan: unsupervised-sources
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: unsupervised-mode
scope: joharness.sh, .agents/docs/plans/README.md, .agents/harness/selftest.sh
---

## Goal

Unsupervised mode has no state it can be finished in. The requirement now
names one — the source sweep goes dry — and nothing computes it. This plan
builds the thing that does: `./joharness.sh sources`, a read-only sweep
over the sources an unsupervised session may draw work from, printing a
count per source and one verdict line.

Counting is what makes the end reachable. Measured 2026-08-25 against the
closed list in `unsupervised-edge-work`, three of its five sources had a
command that returns a number and two did not; an uncountable source never
reaches zero, so a mode drawing on one runs forever whatever else it is
told. `churn`, the graph lint and `feedback` already establish the shape
here: derive from git and the tree at read time, store nothing, report
counted numbers rather than adjectives.

## Scope

- `joharness.sh` — a `sources` subcommand beside `feedback` (`cmd_feedback`),
  registered in the dispatch `case` block and in `usage`. Read-only, exit 0
  always, derived at read time. One line per source: its name, the command
  that counts it, the count. Then one verdict line — `sweep dry` when every
  count is zero, otherwise the sources still carrying findings. Every count
  prints, including the zeroes: a source that prints nothing when it finds
  nothing is indistinguishable from one that ran and found work.
- The detector set, three sources with a command each. Take the counts from
  the tree, not from a written figure: failing or skipped checks
  (`selftest.sh`'s own fail and SKIP counters, plus `ci`'s exit status);
  merged review findings never acted on (`cmd_feedback` already walks the
  edges and separates fixed, wontfix, no-change and unmarked — unmarked is
  the count this wants); known-gap comments in tracked non-docs code
  (`git grep` for the marker set, which is `1` on this repo today).
- `.agents/docs/plans/README.md` — what a source is, and the rule that one
  without a detector is not one. The generated plan's `source:` and
  `evidence:` frontmatter, so a human re-runs the command and sees the same
  finding. Shape only; the reasoning lives in the requirement.
- `.agents/harness/selftest.sh` — scratch repos per the file's fixture
  style: a repo where every detector is zero prints `sweep dry`, a repo
  with one planted finding per source prints that source and no other, and
  a repo where the sweep cannot run (no merge base, shallow checkout) exits
  0 saying so rather than printing a wrong zero.

## Out of scope

- Acting on what the sweep finds. This plan counts; `unsupervised-edge-work`
  decides what an unsupervised session does with a non-zero count, and the
  normal Loop implements the plans that result. A counter that also
  generates work is two failure modes in one command.
- The two uncountable sources — "a documented rule with no test", "drift
  between an instruction file and the code". They leave the closed list
  under the requirement's new constraint. Either earns its place back by
  arriving with a detector, in its own plan; `lint_anchors` extended to
  catch the drift it currently misses is the obvious candidate and is not
  this plan's work.
- Failing `ci` on any source count. `churn` earned its ceiling with a
  backtest over every merge on main; this has none yet. Report first.
- A stored sweep. `.agents/docs/graph.md` Rules: no second copy, derived at
  read time or not at all.
- Sources outside this checkout — upstream releases, advisories, the web.
  Every detector must be re-runnable by a human on the same clone, which is
  what makes a generated plan auditable.

## Acceptance

- `./joharness.sh sources` on `main` — runs, exits 0, prints one line per
  source with its command and count, then the verdict. Paste the output.
- Every count reproduced by hand from the command printed beside it. Trust
  counted numbers: that includes these.
- A repo with all detectors at zero prints `sweep dry`; adding one known-gap
  comment flips it, and the verdict names that source alone.
- `./joharness.sh sources` in a repo with no merge base — exits 0, says it
  could not compute, prints no number.
- `./.agents/harness/selftest.sh` — passes, count higher than today's by the
  tests added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed. Required: touches a
  non-`*.md` file under `joharness.sh`.

## Where to look

- `joharness.sh:cmd_cleanup` — the closest precedent, landed 2026-08-25: a
  read-only subcommand that counts one class of repo debt, prints every
  count including the zeroes, and names the command that acts on it. Match
  its shape rather than inventing one.
- `joharness.sh:cmd_feedback` — the walk that already separates a finding's
  disposition, and the source of the unmarked count. Reuse it; do not write
  a second walk.
- `joharness.sh:fb_marker` — how disposition is read out of prose, and the
  blind spot the feedback doc already records for it.
- `joharness.sh:cmd_ci` — the `== churn` stage, for how a counted process
  fact is already worded to a session.
- `joharness.sh:lint_shallow` — the existing "cannot compute here" path, for
  what a no-merge-base sweep says instead of a number.
- `docs/product/unsupervised-mode.md`, Constraints — the detector rule and
  the anti-self-feeding rule this serves.
- `.agents/docs/graph.md`, Rules and Serving — what this may and may not
  store.

## Traps

- No state store, in any form, however small. A cached sweep is the second
  copy the graph rules forbid.
- A count that prints nothing when it finds nothing reads as a pass. Print
  every zero.
- Never hand-write a number into a file (`.agents/docs/graph.md`, Rules).
  The counts in this plan were measured 2026-08-25 and rot; re-run the
  commands rather than quoting them.
- `unsupervised-edge-work` and `unsupervised-fanout` also touch
  `.agents/harness/selftest.sh`; `unsupervised-edge-work` also touches
  `.agents/docs/plans/README.md`. Not a wave with either.
- The harness is off limits to unsupervised sessions
  (`docs/product/unsupervised-mode.md`). This plan edits `joharness.sh` and
  `.agents/harness/`, so it is supervised work — a session running it under
  the mode is already outside the boundary.
