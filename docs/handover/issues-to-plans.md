---
workstream: issues-to-plans
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Correct issue #260's reproduction block, then retire and open the pull request
---

## Goal

Direct human ask: convert the open issues to plans. Loop step 2 is the rule
this serves — nothing builds unplanned, an issue decomposes into a plan
before code, and the decomposition IS the work. Five issues are open: #249,
#251, #254, #258, #260. None of them is buildable as filed; each names more
than one thing, and in four of the five part of what it names is a human's
decision rather than a build.

## Decisions

- `issue: none` in the frontmatter, deliberately. The field holds one
  number and this work decomposes five; naming one would tell another
  session the other four are free. The queue this produces is the claim
  surface, not this file.
- One artifact per issue, except #258, which the issue itself splits into
  options its own text calls "close to free and mostly independent". Two
  plans there, because one plan mixing an `orchestrate.md` prose change with
  a `joharness.sh` gate is the kind a literal reader half-does.
- Two of the five become RESEARCH files, not plans. #249's remainder is a
  scheduler, and the issue says in its own words that how it is scheduled
  "is the open question, and it is the whole question". #251's remainder
  needs a judgement nobody has made. A plan for either would be a plan whose
  Acceptance cannot be written, which is the shape
  `.agents/docs/research/README.md` exists to catch.
- Nothing here decides anything the issues left to the human: the sampling
  reviewer's cost (#251), blocked-versus-gone (#254), a time bound on an
  unowned block (#254), where a consumer's findings should go (#258). Each
  is named as out of scope in the artifact that would otherwise absorb it,
  with the reason, so the next session does not quietly decide it by
  building.
- No consumer repository is named in any artifact, per the requester's
  standing rule and `.agents/docs/consumer-repos.md`, "Name no consumer".
  The measurements the issues carry are cited as measurements.

## Rejected

- One plan per issue mechanically, including for #249 and #251. Writing
  "spawn a sampling conduct reviewer" as a plan would hand an unattended
  session a cap-beating spawn the issue explicitly does not claim is worth
  its cost. The plan file is an instruction, and an instruction is acted on.
- Re-filing the four rules withdrawn from #249 (PR #253) as a plan blocked
  on `docs/research/liveness-in-a-long-turn.md`. That node already promises
  to graduate into the health pass; a blocked plan beside it would be the
  same work named twice, and the churn that withdrew those rules is exactly
  what a second name invites.

## Review

- r1: (session) `./joharness.sh curate` on the result: `joharness.sh` was
  declared by 4 plans and unmarked — the registry shape that stalls a fleet,
  where one branch in flight holds every other plan and `dispatch` reads
  slots free with nothing to spawn. Three of those four declarations are
  mine; adding them is what crossed the threshold. Input that shows it: the
  command above, which printed 4 REPAIR lines and `verdict : CURATE`.
  (fixed — `shared:joharness.sh` on all four, which is only true because
  these four touch different regions of one 8000-line entrypoint and a
  reconcile between them is genuinely routine. `curate` now prints `NOTHING
  TO CURATE — 6 free plan(s), every declaration reads true`. The fourth plan
  is `findings-with-the-fix.md`, which I did not write: a one-sided `shared:`
  voids nothing, so marking only mine would have left the stall in place
  while looking fixed.)
- r2: (session) `findings-with-the-fix.md` promised in its Out of scope that
  peer divergence was "filed as its own question", and no such file existed
  — the promise was written and the file was not. (fixed — the question is
  filed now and the bullet names the path, so the claim is checkable rather
  than asserted.)
- r3: (session) `unowned-block-age`'s Scope quoted a git pickaxe query that
  does not answer its own question. `-S` matches every commit where the
  COUNT of the searched string changed — the park, the unpark, and the
  retire that deletes the file — so reading either end of that list is
  wrong, and the quoted `--reverse | tail -1` spelling is just the plain
  newest-first list, which can be an unpark. The Acceptance bullet beside it
  described the failure of a DIFFERENT spelling, so the plan contradicted
  itself. (fixed — the bullet names the trap and the discriminator, the
  file's content at the candidate commit, and quotes no query for a literal
  reader to copy. A plan may hand over a hard query; it may not hand over a
  wrong one.)
- r4: (verifier) the fix for r3 demonstrated the trap by QUOTING the searched
  string, and the demo commit then ranked first for its own query — a result
  that echoed the sentence producing it, and one that would be permanently
  unreproducible once merged, because that sentence outranks every real park
  for ever. Reproduced by running the quoted command, whose top hit was the
  commit that added the claim. (fixed — the demonstration is gone, the
  reason is given from the pickaxe's documented semantics instead, and the
  plan now requires the walk to be pinned to ONE file on ONE ref rather than
  `--all`, which is what makes unrelated prose harmless. The searched string
  is also out of this file's prose: a workstream file is exactly what that
  walk reads, so a finding describing the search was a false park sitting in
  the corpus.)
- r5: (verifier) `num-knob-digits` asserted the wrong symptom, from my own
  misreading of my own output. `JOHARNESS_CHURN_THRESHOLD=08 ... dispatch`
  exits 0, not 1, and prints its full output including the verdict —
  measured 2026-09-17, `echo $?` after the command. `set -e` is not in force
  and the arithmetic dies inside a command substitution, so the knob becomes
  EMPTY and the line reads `one file rewritten + times`. A literal reader
  following the old bullet would have asserted an exit status that is 0
  before and after, pinning nothing. The false claim is in issue #260's
  reproduction block too, which I wrote. (fixed — the Goal carries the
  measured output, the bullet asserts the line's content and a silent
  stderr, and the Traps section says why exit status is the wrong thing to
  read here. The issue is corrected separately, since a plan cannot fix
  what an issue claims.)
- r6: (verifier) the same plan's second bullet read the wrong LINE.
  `JOHARNESS_MAX_MANAGERS=010` prints `cap       : 010 manager(s)` — the raw
  string — and the octal misread surfaces one line down as
  `slots     : 8 of 010 free`. The bullet said the cap line prints 8, so an
  implementer would look where the defect is not, find `010`, and conclude
  it was absent. Measured the same day, same command. (fixed — the bullet
  names both lines and says which one carries the misread.)
- r7: (verifier) `unowned-block-age`'s perf bullet was vacuous:
  `joharness.sh:perf_rows` tracks nine entrypoints and `dispatch` is not one
  of them, confirmed by running `./joharness.sh perf`, whose output never
  names it. A bullet asking the budget to hold would pass whether or not the
  new git call existed. (fixed — the bound is stated where it can be seen,
  as a count of git invocations per row asserted in the fixture, and the
  bullet says why `perf` cannot carry it.)
- r8: (verifier) the same plan listed two of issue #254's three proposals as
  out of scope and said nothing about the third, so a reader of the plan
  alone would assume it was overlooked. It was not — proposal 1 merged as
  PR #257 — but the plan is what a session reads. (fixed — named in Out of
  scope with the pull request that built it. The verifier read it as dropped
  work, which is the reading the silence invited and the reason it needed
  saying.)

## Blockers

None.

## Where to look

- `.agents/docs/plans/README.md` — plan shape, the `scope:` rules, and why
  a registry gets `shared:`.
- `.agents/docs/research/README.md` — the nine sections, and what makes a
  file a node rather than prose.
- `docs/plans/findings-with-the-fix.md` — already carries #251's cheap
  slice, and its Out of scope promises a question filed here.
