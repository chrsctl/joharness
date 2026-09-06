---
workstream: context-tax-count
status: in-progress
branch: claude/opus-tier-manager-requirements-pvzp83
pr: none
plan: context-tax-count
issue: none
session: https://claude.ai/code/session_01F4HQXMFP8vEakCs1sTwW8F
agent: sonnet
updated: 2026-09-06
next: Review at sonnet depth with the verifier, record findings, then open the pull request
---

## Goal

Human asked, in these words: "Do managers have to run Opus Tier? Optimize
Token usage" — then "Research and optimize, create pr". The first half is a
question the repo already answers; the second half is the work.

## Decisions

- The tier question needs no code. `.agents/docs/orchestrated.md` Roles:
  manager tier = the item's `agent:`, opus/xhigh only for an unplanned
  requirement. Counted over the 73 plan and research files ever merged on
  `origin/main`, tier read at the commit that added each (2026-09-06): 47
  sonnet, 20 opus, 5 haiku, 1 with no field. So ~27% of managers would be
  opus, and the role forces it exactly once. Nothing to change; the answer
  goes in the pull request body, not into a second spelling of the Roles
  table.

  ```bash
  git log --format=%H --first-parent origin/main --diff-filter=A --name-only \
    -- 'docs/plans/*.md' 'docs/research/*.md' | grep '^docs/' | sort -u |
  while read -r p; do
    h="$(git log --format=%H --diff-filter=A -1 -- "$p")"
    printf '%s %s\n' "$(echo "$p" | cut -d/ -f2)" \
      "$(git show "$h:$p" | sed -n 's/^agent: *//p' | head -1)"
  done | sort | uniq -c | sort -rn
  ```
- The token cost worth attacking is the one nothing counts. The instruction
  chain every session loads before its first prompt — CLAUDE.md, AGENTS.md,
  `.agents/harness/AGENTS.md` — is 17858 bytes today, and
  `.agents/harness/AGENTS.md` alone grew 770 words on 2026-08-23 to 2129 on
  2026-09-06. 2.8x in 14 days, in a file whose first line cites ETH
  AGENTbench for "long context file hurt agent, cost more". Every session
  pays it, in every mode, at every tier.

  ```bash
  ./joharness.sh context      # the chain, counted now
  git log --first-parent --format='%H %ad' --date=short origin/main \
    -- .agents/harness/AGENTS.md | tac | while read -r h d; do
    printf '%s %s\n' "$d" "$(git show "$h:.agents/harness/AGENTS.md" | wc -w)"
  done
  ```

  Orchestrated mode already cut the OTHER half, the session-start injection,
  by printing no queue and only this branch's handover files. No byte pair
  recorded for it on purpose: that injection carries the in-flight table, so
  it moves with the number of live branches and a figure written here is
  wrong within days. `(verifier)` caught exactly that, see r7.
- So: count it where sessions already look, and print what THIS branch adds
  to every future session. Report, never gate — `scorecard`'s own doctrine
  ("report first... the same bar `churn` cleared before it earned a
  ceiling"), and a gate on prose size would fire on the honest rule
  addition.
- Nothing is added to `.agents/harness/AGENTS.md` by this branch. A pointer
  there would grow the number this stage exists to measure; `ci` prints the
  command, which is where a session already reads.
- `agent: sonnet`, `effort: xhigh` rather than an opus tier: the counter's
  failure mode is a silently wrong number, and executable acceptance
  (selftest asserting exact counts on a fixture) is the cheaper answer to
  it. xhigh because the diff touches the layer split, which is Part 2's one
  prohibition here.

## Rejected

- A tier-less plan reaching `dispatch` as spawnable. Probed 2026-09-06: a
  plan with no `agent:` is not offered — the queue hook lists tracked files
  only, and `lint_enum` (joharness.sh:1985) reds a missing or non-enum
  value in `ci` first. `(agent: unreadable)` in `cmd_dispatch` is
  defence-in-depth, not a live path. No finding.
- Cutting `.agents/harness/AGENTS.md` in this branch. It is protocol text
  and the cut is content judgement over rules other sessions obey; it wants
  its own review, with the counter's baseline already on `main` to measure
  against. Handed to the queue as `docs/plans/harness-agents-cut.md`.

## Review

Depth: sonnet — `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet, per `./joharness.sh review`.

Order note, recorded rather than hidden: r1 to r5 were written AFTER their
fixes, not before them in the same commit. The rule wants the record to
exist and to be honest about what each round found; this one is both, and
the ordering was still wrong.

- r1: (session, correctness) `./joharness.sh mutate joharness.sh 848` on the
  fence line said NOTHING REDDED — the fence case pinned nothing. The
  fixture's fenced `@sub/NEVER.md` named a file that did not exist, so a
  followed import and an ignored one printed the same nothing. (fixed — the
  fixture writes `sub/NEVER.md`, four lines, so a fence regression moves the
  subtotal as well as adding a row. Re-run on the moved line, `mutate
  joharness.sh 861`, reds 5 cases)
- r2: (session, correctness) `git show <ref>:<dir>` prints a tree listing and
  exits 0, so an import naming a DIRECTORY was skipped in the worktree
  (`[ -f ]` refuses it) and counted from a ref — and the branch delta is the
  difference of the two, so the defect surfaces as a wrong delta rather than
  as an error. (fixed — the ref side requires `cat-file -t` = blob)
- r3: (session, correctness) a repo with no `CLAUDE.md` returned before the
  `session-start` row, which is paid either way, and before the delta —
  suppressing exactly the number a reader wants when the chain just went
  away. (fixed — the early return sets the subtotal to 0 and falls through;
  two cases, and the negative delta is asserted)
- r4: (session, docs) one sentence served both a growth and a cut, so a
  branch that REMOVED 107 bytes was asked whether it was worth it. (fixed —
  two messages; a case asserts the cut is never asked to justify itself)
- r5: (feedback) `./joharness.sh feedback joharness.sh` served PR220 r4: a
  plan claiming `.agents/harness/` reaches consumers is wrong, because
  `.agents/harness/selftest.sh` is `CANONICAL_ONLY` and
  `.agents/harness/selftest` is `CANONICAL_ONLY_DIRS`. Both plan files here
  made that claim. (fixed — each names the paths that actually ship, and
  `ci`'s ship-scope stage now agrees with both)
- r6: (session, clean) `verify` on this branch first ran 2 passed / 4 failed.
  Not attributed to the diff and not called a flake: `origin/main` in a
  separate worktree ran 3 passed / 3 failed at the same moment, so egress and
  container networking were failing for the container, not for the change.
  Re-run on this branch after the layer was warm: 6 passed, 0 failed
  (2026-09-06). The green run is the branch's number; the first was
  provisioning order.
- r7: (verifier, correctness) the byte pair written for the session-start
  injection was ALREADY wrong on the tree that shipped it — 5983/1541
  written, 6249/1828 counted the same day, deterministic over three runs.
  Root cause is not a typo: the injection carries the in-flight table, so it
  moves with the number of live branches on the remote. A per-mode constant
  is not a property that exists. (fixed — no byte pair is written anywhere
  now; the comment says what orchestrated cuts and why the figure drifts,
  and the command prints the caveat beside the row)
- r8: (verifier, correctness) `mutate joharness.sh 900 '  dir=""'` said
  NOTHING REDDED: nothing pinned resolving an import against the importing
  file's directory. The fixture's only nested import was `@../CLAUDE.md`,
  which normalises to `CLAUDE.md` whether or not `dir` is computed. Same
  class as r1, found by the same tool. (fixed — `sub/RULES.md` now carries a
  bare `@SIBLING.md`, which can only reach `sub/SIBLING.md` through `dir`)
- r9: (verifier, correctness) `ctx_read`'s blob guard does not separate a
  symlink blob from a regular one: the worktree side follows the link and
  reads the target, the ref side prints the link's own path as content.
  Unreachable today — nothing in the chain is a symlink — and silent if it
  ever is. (fixed — both sides skip a symlink, `-L` on one and mode 120000
  on the other)
- r10: (verifier, docs) `docs/plans/context-tax-count.md` named `ctx_bytes`
  in Scope; no such function was ever written. (fixed — Scope names the seven
  that were)
- r11: (verifier, docs) the "3.5s against 14.7s" timing claim carried no
  command, against the repo's own rule that a measured number carries what
  produced it in the same sentence. (fixed — the two-line `date +%s%N`
  measurement is in the comment, with the ms it produced and a warning that
  it is hardware-dependent)
- r12: (verifier, docs) the 73-file tier count in this file carried no
  command either. (fixed — the pipeline that produced 47/20/5/1 is here)
- r13: (code-review, correctness) `ctx_norm` CLAMPED a path that leaves the
  repository instead of refusing it: `@../shared/RULES.md` resolved to
  `<root>/shared/RULES.md` and `@/etc/rules.md` to `<root>/etc/rules.md`, so
  a different file's bytes printed as what a session loads — on both sides
  of the delta, with no diagnostic. (fixed — an escaping or absolute path
  prints nothing and is dropped; clamping is the shape that turns bad input
  into a confident wrong number)
- r14: (code-review, correctness) the command says "reports; never gates"
  and then shelled out to `session-start`, which fetches from origin
  (`handover-context.sh`, HANDOVER_FETCH) and, with an eager layer in a
  remote sandbox, runs `setup` — whose output would then be counted as
  session context. (fixed — the measuring run sets `HANDOVER_FETCH=0` and
  `JOHARNESS_ENV_SETUP=lazy`, and the comment says the row excludes
  provisioning rather than hiding that it does)
- r15: (code-review, correctness) the delta counted the chain only but
  printed under a `total` that includes the injection, so a branch adding
  forty lines of hook output would read "adds nothing" directly beneath a
  number those lines are inside of. (fixed — every delta line now says "to
  the chain")
- r16: (code-review, correctness) growth versus cut was decided on bytes
  alone, so `-8 bytes, +7 words` printed "Saved" for a chain that got
  wordier — and words are the unit the growth this exists to watch was
  measured in. (fixed — either count up is a growth)
- r17: (code-review, process) the `## Review` section carried no finding
  tagged `(verifier)` when it was first written. (fixed by the reader
  finishing: r7 to r12 are its, and `./joharness.sh review` counts them)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_ci` — where the new stage registers, beside `churn`.
- `joharness.sh:perf_report` — the precedent for a counted number with a
  budget, and the wording for what a session does when it moves.
- `.agents/docs/caveman.md` — owns the brevity claim this counts.
