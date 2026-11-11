---
research: scoped-local-check-certificate
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/consumer-repos.md
---

## Question

Does local-mode `finish` certify a head whose consumer `local-check` ran only
part of its suites, and does a STARVED head, green on every run, need a human?

## Echo

A consumer under `JOHARNESS_CHECKS=local` whose `local-check` takes ~33
minutes, on a base that moves every half hour, starves at step 7: a full run
never ends 0 behind, and CATCH-UP refuses whenever one path changed on both
sides. chrsctl/gx answered that on its own side (PR #1499): its `local-check`
now re-runs only the suites the both-sides paths feed, measured from its last
full green. Two things rest on the harness. (1) `checks_gate` writes
`joharness-finish-cert` after ANY green `local-check`, so a scoped green
becomes a head the next CATCH-UP carries from: scoped runs chain with no full
run under them. (2) The STARVED block is `conflict: base outran finish`, and
every block that is not `defect:` asks a `decision needed:` question and labels
`human-review` (manager.md §3, manager-reference.md § Question), although the
pull request is green and already drafted; a human must remove a label to
release a merge nothing was wrong with.

## Sweep

`goal-directed`: the two gx managers that starved on 2026-11-11, gx's `main`
history for the 12 hours before, and canonical's own text for the two rules.

## What would settle it

(1) `checks_gate`'s certificate write reads anything a consumer's
`local-check` can say about how much it ran: yes = no defect. (2) The rules
exempt a STARVED block from the question and the label, or dispatch resumes it
without a human: yes = no defect.

## Method

In chrsctl/gx:

    git show ab063bad5:docs/handover/reeve-fit-settings-counts-door.md   # ## Blockers
    git show 117aa38be:docs/handover/reeve-fit-schema-layout.md          # ## Blockers
    # every 33-minute window, 600 s apart, over the 12 h before 2026-11-11T13:50Z:
    git rev-list --count --since=@<s> --until=@<s+1980> origin/main
    git log --since=@<s> --until=@<s+1980> --format= --name-only origin/main \
      | sort -u | comm -12 - <(git diff --name-only origin/main...<branch> | sort -u)

In canonical:

    grep -rn -iE 'scoped|not certify' AGENTS.md .agents/ .claude/   # no hit
    grep -n 'catchup=0' joharness.sh                               # checks_gate
    grep -n 'STARVED\|Not a `defect:` block' .claude/commands/manager.md

## Findings

- **A full local-check never ends level on a busy consumer.** gx PR #1494's
  manager measured `finish` at 1980, 1977 and 1987 s on three heads; `main`
  moved 22, 6 and 7 commits during them. In 0 of 69 33-minute windows was gx's
  `main` still (157 commits, 21 first-parent merges in the 12 hours). Command:
  the `rev-list --count` loop above.
- **CATCH-UP's shared-path rule refuses most of those windows.** A path
  changed on both sides in 47 of 69 windows for gx PR #1488's branch, 33 of 69
  for #1494's (sibling items share stylesheets, locales, criteria ledgers);
  #1494's own record names the third refusal (`crm_reeve_fit_doors.py`). Both
  ended `conflict: base outran finish` after three green full runs. Command:
  the `comm -12` loop above.
- **A consumer can scope instead, but the harness certifies the scoped run.**
  gx PR #1499: re-running only the suites the shared paths feed turns 47 -> 20
  and 33 -> 10 of those windows into full runs, most of the rest into a 25 s
  run. `checks_gate` writes its certificate when `rc=0` and its own
  `catchup=0` (`grep -n 'catchup=0' joharness.sh`), reading nothing from
  `local-check`; a scoped green is then certified as if full. Reasoned from the
  source by a verifier that did not write gx's change (gx #1499, r2); not
  executed.
- **The STARVED block costs a human gesture for no decision.** On
  2026-11-11 both PRs were drafted green, labelled `human-review`, and a human
  removed the label on each (gx `2a0e04316`: "label removed, unblocked";
  `0847989f7`: "Relay the human's answer: resume"). The answer was the same
  both times: catch up and merge. The draft alone already stops the merge
  nobody meant (manager-reference.md § Block on an open pull request).

## Consequence for the queue

1. `consumer-repos.md` § Local checks and `checks_gate`: a consumer-declared
   way for `local-check` to say "green, do not certify" (a reserved exit code,
   or a marker file in the git dir the harness reads and removes), so a scoped
   green carries no certificate. Selftest: a scoped green leaves none.
2. `manager.md` §3/§4 and manager-reference.md § Question: a STARVED block
   drafts the pull request and asks nothing, no `human-review`; dispatch
   resumes the claim once the base has moved since the block (as a `core path:
   waiting on #<N>` claim resumes on its merge), bounded by a respawn count.
   A plan each; canonical decides.

## Verification

UNGROUNDED here: no second context has re-read these findings. The figures
are a consumer's reading (gx); the `checks_gate` claim is from source.

## Graduates to

`.agents/docs/consumer-repos.md` — § Local checks owns CATCH-UP and the
certificate; the STARVED rule's text in `manager.md` follows from it.
