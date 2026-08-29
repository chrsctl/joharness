---
plan: issue-claim-edge
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, .agents/docs/handover/TEMPLATE.md, .agents/docs/handover/README.md, .agents/harness/AGENTS.md, joharness.sh, .agents/harness/selftest.sh
---

## Goal

Issue #119. A claim on a PLAN is representable and a claim on an ISSUE is
not, so two sessions solved #114 in parallel on 2026-08-28 and one of them
threw the work away.

The plan edge works: the workstream file's `plan:` frontmatter names the
plan, the queue hook reads it from every branch, and the plan shows as
`claimed on <branch>`. Nothing equivalent exists for an issue. The session
that got there first filed its plan on its own branch — a same-session plan,
which the protocol permits — so `main`'s queue never saw it and #114 read as
free. The hook DID list that session's workstream file; nothing tied it to
the issue, because the link lived only in prose inside the file's Goal.

Loop step 3 says "Hook shows overlap? `/who`." There was no overlap to show.
The entrypoint line "open GitHub issues outrank plans — check first" tells a
session to check the issues and gives it no way to check whether one is
already taken.

Requester chose the shape 2026-08-29: an `issue:` frontmatter field on the
workstream file, the same stable edge `plan:` already is. Deriving it by
grepping prose for issue numbers was rejected as fragile in the one direction
that matters — a missed match reports the issue free, which is the failure
that caused the duplicate.

## Scope

- `.agents/harness/handover-context.sh` — read `issue:` alongside the fields
  it already reads, on both print sites (this branch's file, and every other
  branch's). Print it on the entry line, AND print one consolidated line
  naming every issue claimed by work in flight, because the question a
  session actually asks is "is #119 taken?" and scanning entries to answer it
  is what nobody did.
- `.agents/docs/handover/TEMPLATE.md` — the field, with its edge meaning.
- `.agents/docs/handover/README.md` — the protocol: what the field claims,
  that it is written when the work starts and not when the pull request
  opens, and the `none` default.
- `.agents/harness/AGENTS.md` — step 2's "open GitHub issues outrank plans —
  check first" gains how to check whether one is taken. One clause, no more.
- `joharness.sh` — `lint_graph` validates the field: empty, `none`, or a
  number with an optional leading `#`. Anything else is red, because a
  malformed claim reads as no claim, which is the defect.
- `.agents/harness/selftest.sh` — fixtures per the file's style.

## Out of scope

- Asking GitHub anything. The hook is offline by construction — it reads git
  refs and nothing else, and every consumer runs it. A hook that needs a
  token to tell a session what is claimed fails closed in exactly the repos
  that most need it. It reports what the tree claims; whether that issue is
  still open is the session's to check, and it already checks.
- Closing the issue automatically, linking to GitHub, or writing `Closes #N`
  into pull request bodies. That is prose a session already writes.
- A `status`-like field on the ISSUE. Nothing here mutates: an issue number
  never changes, which is the whole argument for a field over a derived
  grep, and the argument would not survive a mutable one.
- Retro-filling `issue:` into workstream files already in flight. They are
  other sessions' files on other branches; this ships the field and the
  reader, and the next file written carries it.
- Making the field required. A branch claiming no issue writes `none`, the
  same as `plan:`. A gate that reds a plan-only branch teaches sessions to
  write a fake number.

## Acceptance

- A workstream file carrying `issue: 114` makes the hook print that claim on
  the entry line for its branch. Paste the output.
- The hook prints a consolidated line naming every claimed issue and the
  branch claiming it, and prints nothing when none is claimed — a section
  that vanishes when empty is indistinguishable from one that failed to run,
  so the empty case says so.
- `issue: #114` and `issue: 114` both work; the `#` is not significant.
- `issue: none`, and an absent field, print no claim and no warning.
- `issue: fourteen` fails `ci` by name, naming the file.
- The `## Where to look` anchors in the TEMPLATE and README resolve.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 6 passed, 0 failed. Required: the diff touches a
  non-`*.md` file under `.agents/harness/` and `joharness.sh`.
- The consumer-side check this plan owes, because every file in scope except
  the plan itself SHIPS: a consumer whose workstream files carry no `issue:`
  field gets identical output to today. The field is additive or it is a
  sync that changes what every consumer's hook prints.

## Where to look

- `.agents/harness/handover-context.sh:fields` — the one-pass frontmatter
  reader; add the key to the two callers rather than forking a third.
- `.agents/harness/handover-context.sh` — the two print sites: this branch's
  entry, and the `others` loop for every other ref.
- `joharness.sh:lint_graph` — the workstream loop, and `lint_enum` beside it
  for how an out-of-vocabulary value is already reported.
- `.agents/docs/handover/README.md` — the `plan:` edge this mirrors, and
  Graduation for why a field beats discipline here.
- `.agents/docs/plans/README.md`, Lifecycle — the same-session plan rule
  that made #114's claim invisible.

## Traps

- A missed claim must never read as "free". Everything here fails toward
  saying MORE, not less: an unparseable value is red, not silently dropped.
- The hook ships and runs in every consumer. A field no consumer file
  carries must change nothing about their output.
- `fields` stops at the closing frontmatter delimiter on purpose, so a body
  line reading `issue: 12` is not metadata. Do not widen it.
- Count, never trust: the hook already reads several refs per run, and this
  adds a field to an existing read rather than a second `git show`.
- The layer rule holds for fixtures: `.agents/harness/` names no environment
  layer.
