---
workstream: joharness-minify-optimize
status: review
branch: claude/joharness-minify-optimize-narzrq
pr: none
plan: none
session: https://claude.ai/code/session_01CoyUYZVH6ezxbfyDWhR6bE
agent: opus
updated: 2026-08-24
next: Human decides whether to open the PR (outer harness forbids opening one unasked); then merge per Loop step 7
---

## Goal

Human: "Try to minify joharness remove everything unnecessary, research
optimizations." Read as: find what the harness does that it need not do, and
cut it — measured, not guessed.

## Decisions

- **Measure first, and keep measuring.** Every cut below was picked off a
  profile, not off a reading. `ci` was 62s; the profile said 50s of it was
  `selftest.sh`, and 20s of THAT was one line nobody had looked at.
- **The unnecessary work was never unnecessary code.** No dead function, no
  unused variable, no unreachable branch exists in this repo — checked
  mechanically across all 14 scripts, and `shellcheck -o all` finds only style
  nits. So "remove everything unnecessary" landed on work per run, not lines
  per file: subprocesses spawned, files re-read, history re-walked.
- **Fixtures do not re-prove the real bar.** Selftest fixtures ran
  `joharness.sh ci` ~20 times against scratch copies of joharness.sh, and each
  run shellchecked a file the real `ci` had shellchecked one section earlier.
  A stub on the fixtures' PATH removed 35s. The bar did not move: the real run
  still lints the real tree, and nothing in the suite asserts on shellcheck's
  output or reads an exit code it owns.
- **One frontmatter pass, not one per field.** `gr_field`/`field` forked an
  awk per field, and every caller wants four or five off the same five lines.
  `gr_fields`/`fields` reads them in one pass; the single-field entry point
  stays as a wrapper over it, because two parsers of the same frontmatter is
  one of them drifting.
- **Git walks are one command each.** `churn_top`, `fb_fix_map` and
  `fb_workstream` each forked per commit in the range — the measures that
  exist to notice a long branch got slow on exactly the long branches they
  were built for. Now: one `git log`, one awk.
- **`cmd_graph` was quadratic.** "Is this requirement planned" asked a
  `git show` per (requirement, plan) pair. Read once, before the pass.
- **Equivalence proved, not assumed.** `feedback`, `feedback <path>`,
  `feedback` with the edge cap lifted, `graph`, `review` and `session-start`
  all produce byte-identical output to `main`. `churn_top` was diffed old
  against new across all 27 origin refs: 0 differences.

Measured, this repo, warm cache:

| | before | after |
| --- | --- | --- |
| `ci` | 61.7s | 20.2s |
| `selftest.sh` | 50.4s | 15.2s |
| `feedback` (37 edges) | 2.46s | 1.54s |
| `review` | 2.43s | 1.63s |
| `graph` | 0.38s | 0.25s |
| `session-start` | 1.34s | 1.05s |
| `feedback` subprocesses | 1262 | 639 |
| `queue-context.sh` subprocesses | 198 | 158 |

## Rejected

- **Stripping the comments.** It is the obvious reading of "minify" and it is
  the wrong one here: 25% of the shell is comment, and those comments are the
  only record of why each guard exists — BSD sed's literal `\t`, bash 3.2's
  fatal empty-array expansion, `--first-parent` costing 14 phantom edges.
  Delete them and the next session re-learns each one from a bug report. The
  cut was taken out of work per run instead. Code lines are flat (+10 across
  three files); comments are up, and that is the trade, deliberately.
- **Deleting a subcommand.** `graph`, `feedback` and the review step are the
  three biggest things here and the most tempting to call unnecessary. They
  are working, tested, and load-bearing to rules in `.agents/harness/AGENTS.md`
  — cutting one is product direction, which is the human's call (Decide alone).
  Flagged, not taken.
- **Pure-bash frontmatter parsing, no awk at all.** Benchmarked the fork it
  would save: 2.7ms per call, ~135ms per `ci`. Not worth a hand-rolled parser
  in three files, when one awk pass for all five fields gets most of it.
- **A shared library the hooks source.** It would collapse the third copy of
  the frontmatter reader, but the hooks are standalone by design and the sync
  engine ships them as files. Wrong-shaped fix; the duplication stands.

## Review

Opus tier, adversarial, three lenses (correctness / portability / does-it-
reproduce). Findings against my own diff:

- r1: `fb_fix_map`'s awk cleared its arrays with `delete id` — the awk older
  macOS ships cannot delete a whole array, and this file runs there
  (fixed: `split("", id)`).
- r2: `gr_fields`'s `END { ... print (i in v) ? v[i] : "" }` — `print (expr)`
  is ambiguous in one-true-awk and can be parsed as the whole argument list
  (fixed: explicit if/else, all three copies).
- r3: moving `churn_top` to one `git log --name-only` silently changed the
  metric: `git log` applies rename detection by default, the `diff-tree -r`
  it replaced did not, so a rename would count once instead of twice
  (fixed: `--no-renames`; then diffed old against new over all 27 origin
  refs, 0 differences).
- r4: `fb_workstream` iterated `for f in $(...)`, which splits a workstream
  path containing a space into two paths that resolve to nothing — latent
  before this branch, carried into the rewrite (fixed: `while read`).
- r5: the fixture shellcheck stub would hide a real finding if any assertion
  read shellcheck's output, or read an exit code shellcheck owned. Checked
  every `ci` call site in the suite: none does, and the sections that could
  already clear `GITHUB_ACTIONS` for that exact reason (no change needed).
- r6: the `# Checks` banner introduced a section that started 80 lines later,
  after all of Upgrade — a reader following the banners lands in the wrong
  function (fixed: moved to `cmd_ci`).
- r7: `read -r` at EOF must still assign, or `set -u` kills the hook on a
  document missing its last field. Verified under `bash -u` before relying
  on it (no change needed).
- r8: read what `selftest.sh` cost the four earlier edges
  (`./joharness.sh feedback .agents/harness/selftest.sh`) before touching it,
  as the review step asks. Nothing there re-fires against this diff — the two
  findings nearest it, PR47 r8 ("a measure nobody runs twice measures
  nothing") and r9 (`--first-parent`), are the shape of this branch's own
  argument, and the cap and the first-parent walk both survive it unchanged
  (no change needed).

Green: `./joharness.sh ci` = `ci: pass`, 352 passed 0 failed, zero shellcheck
findings. `./joharness.sh verify` = 7 passed, 0 failed.

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — the stub block above `commit_all`. 35s of
  the 42s saved is this one paragraph; the comment says why removing it is
  correct and three times slower.
- `joharness.sh:churn_top` — one walk, and the `--no-renames` that keeps it
  the same metric.
- `joharness.sh:fb_fix_map` — `--raw -p` carries the changed paths and the
  patch in one stream, split by a marker line.
- `joharness.sh:gr_fields` — the single-pass reader; `field()` in both hooks
  is now a wrapper over its own copy of it.
