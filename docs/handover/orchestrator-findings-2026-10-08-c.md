---
workstream: orchestrator-findings-2026-10-08-c
status: in-progress
branch: claude/orchestrator-findings-2026-10-08-c
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011BJ7AKa5rQPF4xTF1MPdAh
agent: opus
updated: 2026-10-08
next: Retire this file in the last commit before the pull request, open the PR, run ci green, then exit — the human merges
---

<!--
Reporter session for a consumer (`chrsctl/gx`), route:
`.claude/commands/upstream-report.md`. One finding, one node, canonical
decides. Third of three reporter branches from the same consumer run; the
other two are PRs #319 and #320.
-->

## Goal

Turn ONE harness-flow finding from a consumer's orchestrated run into a
research node: `dispatch` re-offers a requirement as `UNPLANNED` on every
pass for as long as no plan on the base branch carries `requirement: <its
stem>`, and for some requirements no such plan will ever be written — so the
orchestrator keeps buying planning passes over one file. The node states the
question, the evidence and the candidate answers. It answers nothing and
changes no harness code.

## Decisions

- **One question, one node.** The brief named two adjacent facets. Facet (a)
  — a requirement-planning branch is invisible to `dispatch` — is evidence
  about the SAME loop (nothing suppresses a second planner), so it rides
  inside this node as a finding rather than becoming a second node. #319
  filed two nodes in one pull request and flagged that as a deviation; not
  repeating it.
- **`graduates: .agents/docs/product/README.md`.** The answer has to amend a
  sentence already written there — *"a requirement nobody has served is
  UNPLANNED, which is work, not a candidate for this"* (`:34`) — before any
  code moves. A rule line alone would lose the reasoning and the question
  would come back.
- **The consumer's own numbers are REPORTED, never re-measured.** `add_repo`
  for `chrsctl/gx` was refused in this session (auto-mode permission
  classifier) and the GitHub tools refuse an out-of-scope repository, so no
  gx commit, cost or dispatch output could be read. Every gx-side claim is
  marked REPORTED / WEAK with that reason named in-file. Every harness-side
  claim is measured here.
- **Measured with a fixture, not only greps.** Five cases (A–E) over a
  scratch repo with a real `origin`, including a CONTROL that changes one
  frontmatter field on the same branch. Greps alone could not tell a
  structural invisibility from a fixture artifact — and the first fixture run
  had exactly that artifact (below).

## Rejected

- **Marking the finding as a facet of #317's `no-ceiling-on-one-item`.**
  That node asks what bounds ONE manager's spend when every health signal
  reads healthy. The cost here is not one long manager: each planning pass
  is a separate session that terminates normally. A per-manager ceiling
  would not fire on any of them. Cross-referenced instead.
- **Folding it into #319's `a-manager-blocked-before-its-first-push`.** That
  node's session never pushed, so it has no ref and no row. Here the branch
  IS pushed and the row is still absent — measured, case B, with the control
  in case E. Different cause, same blind row; cross-referenced, not restated.
- **A fixture without a remote.** The first run never ran `git remote add
  origin`, so every push failed and the queue hook fell back to `HEAD`
  (`queue-context.sh:78`). The in-flight walk reads `origin/<branch>` refs,
  (`queue-context.sh:76` names `HEAD` in the fallback list). The in-flight
  walk reads `origin/<branch>` refs, so "no row for the planning branch" was
  unfalsifiable in that run. Re-run with the remote; the result held, but it
  had to be re-taken to mean anything. The verifier confirmed the artifact is
  excluded in the re-run by listing both origin refs before case B's
  dispatch.

## Review

- r1: the node's `## Verification` was drafted as a REPORT of a verifier pass
  that had not run — marks and all. Caught before any commit carried it; the
  section now states only that the pass is in flight, and it is rewritten
  from the report. Exactly the breach the independent read on #317 found nine
  times, reached by drafting the nine sections in order and not stopping at
  the one that cannot be written yet. (fixed)
- r2: (verifier) `queue_files` cited at `queue-context.sh:63-67`; it is at
  `:118-121`, and `:63-67` is a block of directory assignments. The quoted
  body also dropped the `TEMPLATE|README|VISION` filter with no ellipsis —
  the filter being the reason `TEMPLATE.md` never contributes a stem.
  (fixed)
- r3: (verifier) the claim-resolution enumeration implied FOUR sites by
  listing `:7271` and then "the same pair inside `dispatch_retired_edges`" —
  `:7271` IS that site (`:7206-7379`). Three sites, and the node's own
  Method grep returns exactly three. Conclusion unaffected; the count was
  wrong. (fixed)
- r4: (verifier) `orchestrate.md:190` quoted as `done. Nothing.` with a
  terminal period, cutting an `UNLESS dispatch's upstream : line says ON`
  conditional and marking no ellipsis. The node leaned on that quote, so a
  conditional rule was presented as flat. Now quoted whole, with what each
  branch of the condition does to a planner nobody listed. (fixed)
- r5: (verifier) the step-3 census read four of five role-spawn rules and
  omitted the analyst (`:493-502`) — the one bullet closest to refuting the
  uniqueness claim, having no in-flight condition either. It has a ledger
  key, so the claim survives, but it was settled by a count that had not
  been taken. Every bullet now listed with its range. (fixed)
- r6: (verifier) the same finding's headline read "neither an in-flight
  condition nor a ledger key" flat, while `orchestrate.md:552` ledgers every
  spawn as `<stem>@new` — so the planning spawn DOES get a generic entry and
  `:441` keys on it. The node's body already conceded this; the headline
  overstated it. Now "no key OF ITS OWN", with the qualifier called
  load-bearing. (fixed)
- r7: (verifier) `queue-context.sh:882` labelled a claim key; it is the
  `QUEUE_WITHHELD` match (documented `:47`, fed from `joharness.sh:6762`) —
  a withhold, not a claim. The two-directory point survives; the label was
  wrong. (fixed)
- r8: (verifier) two off-by-one ranges in the step-3 citations: janitor
  `:466-480` for a bullet ending `:478`, and surveyor `:480-` starting one
  line after its own headline, excluding the `ONLY when` the finding rests
  on. (fixed)
- r9: (verifier) the `declin` grep taxonomy accounted for 12 of 15 hits.
  Three unnamed (`joharness.sh:4507`, `:8047`,
  `.claude/commands/upstream-report.md:42`). Substantive claim reproduces,
  and the verifier widened the scope by two further files to test it.
  (fixed — all 15 classified, plus the two outside the quoted scope)
- r10: (verifier) `:70-86` over-wide for the ref fallback loop at `:73-82`;
  and in THIS file, `queue-context.sh:78` cited for the `HEAD` fallback,
  which is named at `:76` (`:78` is `ref="$candidate"`). (fixed in both
  files)
- r11: (verifier) one hand-written date in the node — `updated: 2026-10-08`
  inside the case-B fixture frontmatter. Fixture data, not provenance, and
  the result is independent of the value; but the protocol's "Never when"
  admits no exception and a literal reader greps it up. Replaced with the
  template's own placeholder. (fixed)
- r12: (verifier) `## Method` not literally runnable as printed: a
  `ROOT=<this checkout>` placeholder, an admittedly abridged fixture file,
  and a supervised re-read block assuming a `cd` the printed script only
  makes inside `disp()`. None changed a result — the verifier reproduced
  every case from the block as printed — but the bar is re-runnable as
  written. (fixed: `cd` made explicit, substitution and abridgement named
  above the block)
- r13: (verifier) `## Consequence for the queue` reads as a complete
  neighbour list and named nothing from #320, though `## Verification`
  claimed all three branches were read. `a-merge-waiver-with-no-expiry`
  carries nothing of this question, so no conclusion moves. (fixed — named,
  with what it asks instead)
- r14: (verifier) the node UNDERSTATED its own central finding. It said a
  workstream file "has no field that could name a requirement"; in fact
  `.claude/commands/manage.md:35` lists `docs/product/<r>.md` as an item
  kind and `:55` says `plan:` names the item, so a planner is invited to
  write it — and the verifier measured that the branch is STILL invisible
  (0 mentions, 4 of 4 slots free) when it does. A manager obeying its own
  instructions holds nothing. (fixed — the sharper version is now the
  finding, credited)
- r15: (verifier) an attempted refutation that FAILED, recorded because it
  removes a claim this node might otherwise have made: a plan naming its
  requirement by path should have slipped past `:650`'s raw comparison, but
  `:445` stems the value first, so both spellings silence the row. No
  defect. (no change needed)
- r16: (verifier) `joharness.sh:5352` says a two-candidate loop is "already
  spelled at `cycle_landed_sha`", and it is not there (`:7420-7436`). A
  defect in the harness's own comment, found while checking this node's
  citations. (wontfix here — this branch touches no harness file by
  construction, and widening a consumer report to fix a comment is not the
  reporter's call. Recorded so canonical has it.)

## Blockers

None. `chrsctl/gx` is unreachable from this session (above); that bounds what
the node may claim and is written into the node, not left as a blocker.

## Where to look

- `.agents/harness/queue-context.sh:644-655` — `served`, and the only test
  that silences a requirement row. `:445` stems the value; `:118-121` is
  `queue_files`; `:73-82` the ref fallback.
- `joharness.sh:8562-8572` — `dispatch`'s `UNPLANNED` row: no holder, no
  hold, no claim.
- `joharness.sh:7236` — `dispatch_retired_edges` skipping a branch because it
  "owns" a claim, which a `plan: none` workstream file does not.
- `.claude/commands/orchestrate.md:453-454` — the one step-3 spawn rule with
  neither an in-flight condition nor a ledger key.
- `.agents/docs/product/README.md:26-36` — the two deletion paths, and the
  sentence the answer must amend.
