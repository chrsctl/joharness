---
plan: finding-with-no-path-has-no-reader
urgency: normal
agent: sonnet
effort: high
scope: joharness.sh, .agents/harness/selftest/
---

## Goal

What remains of #258. The issue filed three directions and two have landed, so
this plan is scoped to the third — and narrower than the issue, because its
central factual claim no longer holds.

Filed as: a manager's findings are "written down properly and then destroyed on
merge". They are not. `cmd_feedback` serves findings out of merged history, and
`./joharness.sh feedback joharness.sh` returns them from merged edges today. So
findings survive a merge and reach the next session touching the same file.

**Reach the next session touching the same FILE.** That is the whole of it.
`feedback` keys on a path. A finding that names no path this repo owns is
served to nobody:

| bucket | `upstream` does | who reads it after the merge |
| --- | --- | --- |
| fix path the canonical owns | reports it | the canonical, via `/upstream-report` |
| fix path, none of them the canonical's | counts it, never quotes it | `feedback`, keyed on that path |
| **no fix path at all — `unplaceable`** | lists it, says it "will not guess" | **nobody** |

The third row is the one #258 measured hardest: the findings it cared about
most were about OTHER items in the queue, which is precisely the shape that
carries no path of its own. `lead <stem>: <text>` now covers part of that, but
only under orchestrated, only to the orchestrator, only one, and at 40
characters it is a pointer rather than the finding.

So: make a finding with no reader a DECISION at the moment it would be lost,
instead of a line in a command nobody is required to run.

## Scope

- `joharness.sh:fin_promote` (the block printing "N finding(s) recorded on this
  branch stop existing when it retires" and "This diff promotes into M
  file(s)"). It counts findings and promotion files. Add the third number it
  does not print: how many of those findings carry **no path** — neither a fix
  path in the commits that recorded them, nor a path in the finding's own text.
  Name them, one line each, because an unreadable count is what this plan is
  about.
- `joharness.sh:cmd_upstream` — reuse, do not re-derive. The three-bucket split
  already exists there (`fb_fix_map`, the `noid` bucket). `fin_promote` must
  reach the same verdict on the same finding, or two readers disagree about
  what is lost.
- `.agents/harness/selftest/` — a case per shape, in the topic that already
  covers `finish`. A finding WITH a path must not be named (it has a reader); a
  finding with no path must be; a branch with no findings must print what it
  prints today, unchanged.

**Overlap, declared rather than assumed.** This plan's `scope:` is
byte-identical to `docs/plans/unowned-block-age.md`'s — both touch
`joharness.sh` and `.agents/harness/selftest/`. Neither marks a prefix
`shared:`, because parallel safety between them is not proven: they edit the
same file. Whichever lands second reconciles. That is a cost to accept
knowingly, not a collision ruled out.

## Out of scope

- **Options 1 and 2 of #258 — both landed.** Do not re-propose them, and do not
  "improve" them. Option 1 is `.claude/commands/manage.md` §4's
  `lead <stem>: <text>`; option 2 is the promotion block this plan extends.
- **Routing anything to the canonical.** `cmd_upstream` deliberately refuses to
  carry an unplaceable finding into a report on another repository, and its
  comment says why. This plan makes the loss visible HERE; it does not widen
  what gets reported there.
- **Making `finish` RED on an unplaced finding.** Report only. The promotion
  block's own text says most findings are "branch-local and correctly
  forgotten" — a gate that fails on them would be a gate sessions route
  around, and `joharness.sh:fin_strength` already records why two strengths
  exist.
- **Changing `JOHARNESS_UPSTREAM_FEEDBACK`'s default.** That is the human's.
- **Touching `cmd_feedback`'s keying.** Making it serve path-free findings is a
  different, larger change; this plan only makes their absence visible.

## Acceptance

All pass or not done.

1. `./joharness.sh ci` → `ci: pass`.
2. `bash .agents/harness/selftest.sh` → `0 failed`, with a higher pass count
   than before the change. Read the number the suite prints; do not trust one
   written here.
3. On a branch whose `## Review` holds one finding naming a path it changed and
   one naming no path at all, `./joharness.sh finish` names the second and not
   the first.
4. On a branch with findings all naming paths, `finish`'s output is byte
   identical to before this change:
   `./joharness.sh finish > after.txt` against the same command at the merge
   base → no diff.
5. Each new assertion is mutation-tested: `./joharness.sh mutate joharness.sh
   <line> <replacement>` on the clause it pins reds that case and leaves the
   control green. Baseline green FIRST — a mutation that reds hundreds of cases
   proves nothing about one clause.
6. `fin_promote` and `cmd_upstream` agree: a fixture finding that `upstream`
   puts in its `unplaceable` bucket is the one `finish` names, asserted in the
   same case rather than in two.

## Where to look

- `joharness.sh:fin_promote` — the block to extend.
- `joharness.sh:cmd_upstream` — the three-bucket split and the comment naming
  why the third exists at all; reuse its placement, do not write a second one.
- `joharness.sh:fb_fix_map` — how a finding gets a path.
- `joharness.sh:fb_findings` — what counts as a finding. It reads only between
  `## Review` and the next `## `, which is its own trap below.
- `joharness.sh:fin_strength` — why `finish` reports where `ci` reds.
- `.agents/docs/feedback.md` — the unplaceable bucket, and "When the consumer
  is the detector".

## Traps

- A finding outside `## Review` does not exist. `fb_findings` stops at the next
  `## ` heading, so a fixture that writes findings under any other heading
  tests nothing and goes green. Measured twice on one branch: PR294 r12.
- Ownership is a DIFF against the merge base, never a tree read. Six merged
  edges bought that, and a seventh re-broke it by quantifying over refs it had
  not read (`.agents/docs/feedback.md`, "Worked example: tree or diff").
- Every sentence this prints may claim no more than it read. `finish` cannot
  know a finding is worthless, only that nothing will serve it — so say that,
  not "unimportant".
- A test written for this must FAIL without the change: revert, run, restore.
  Green both ways pins nothing.
- Never report a count without the command that re-counts it.
- `.claude/` and `joharness.sh` are protocol paths. Under unattended mode this
  plan is not implementable; a supervised session may take it
  (`.agents/docs/unsupervised.md`).
