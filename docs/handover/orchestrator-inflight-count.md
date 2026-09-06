---
workstream: orchestrator-inflight-count
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-inflight-count
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Add the no-claim edge row to cmd_dispatch, then its fixture in selftest/dispatch.sh
---

## Goal

`dispatch` reports a live manager's slot as free for the whole window between
its pull request opening and its merge — step 7 retires the workstream file
as the last commit before the pull request, so the claim disappears while the
branch, the pull request, the CI and the container are all still running. An
orchestrator acting on that verdict spawns a duplicate per item and exceeds
`JOHARNESS_MAX_MANAGERS`, which is the human's money. Measured on consumer
`chrsctl/gx`, 11 consecutive health passes, 2026-09-06.

## Decisions

- Fix on the CAPACITY side, never the claim side. The claims view is right —
  a retired file is genuinely not a claim, pinned with reasoning in
  `.agents/harness/selftest/handover-context-owns.sh:85`. `slots` is what
  answers the wrong question with the claims view's value.
- The row's trigger is the RETIRE RITUAL'S FINGERPRINT, not "no workstream
  file". A bare "unmerged branch carrying no workstream file" catches every
  branch that never claimed anything. Counted on this repo 2026-09-06 with
  the loop in the comment above `dispatch_retired_edges`: 4 unmerged branches
  own no workstream file, 1 of them carries the fingerprint — so at the
  default cap of 4 the wider test reports 0 of 4 free with nothing whatsoever
  in flight.
- The fingerprint is the DELETED PLAN FILE, with the deleted workstream file
  as the second half of a union — not the other way round, which is what this
  was written as first (see Review r1). The plan file lives on `main` because
  it IS the queue item, so step 7 deleting it is a real `D` in the net diff;
  the workstream file is usually born and retired on the same branch, which
  nets to absent from every filter. A workstream deletion still counts where
  it is visible: one the branch INHERITED and swept.
- The item it holds is that same deleted plan or research file. A branch that
  swept a workstream file and finished no queue item names none and still
  holds the slot, with the item printed `?` — a slot with an unknown item is
  still money committed.
- Item suppressed from the free list the same way a claimed one is (skipped,
  not annotated): the in-flight block already names the path and the branch,
  and a second rendering of one fact is how two readers start disagreeing.
- Counted separately from claimed managers (`n_edge`), with its own verdict
  line, because the ACTION differs: a claimed stall has a `session:` URL to
  `get_session`; this row has none, so the orchestrator finds it by title or
  reads it as gone.
- A shallow clone DEGRADES the report loudly; it does not refuse it. Refusing
  to print a spawn list there would turn a report the orchestrator can act on
  carefully into no report at all — against that role's own "the one thing
  this role must never do is read a full queue and leave it untouched" — and
  a shallow clone is the ordinary shape of a fresh container, not an
  exception. So: the verdict says an item under `spawn` may already be in
  flight, names `git fetch --unshallow`, and the per-row control-plane check
  the health pass already makes is what closes the gap.

## Rejected

- **Moving the retire commit after the merge** — the obvious repair, and the
  plan's own Out of scope: three pull requests that deferred the deletion each
  turned the base branch red within seconds.
- **Making a retired file count as a claim again** — would red
  `handover-context-owns.sh:85`, a pin whose comments record an earlier wider
  refute failing for a good reason. Never relax a guard to make room for a fix
  one layer above it.
- **Trigger = "unmerged + ahead + no owned workstream file"**, the plan's
  literal Scope wording. Measured against this repo's real remote before
  writing it: 4 branches qualify, 3 of which never wrote a workstream file at
  all, and at the default cap of 4 the report reads 0 of 4 free with nothing
  in flight. The plan's own second Scope bullet — "must still be
  distinguishable from a genuinely abandoned branch, or this trades a
  duplicate-spawn defect for a slot that never frees" — is what rules it out.

## Review

- r1: (session, does-it-reproduce) the trigger was written as "deleted a
  workstream file", and it cannot see the ordinary case. `git diff base..tip`
  compares two STATES: a workstream file born on the branch and retired on it
  is added-then-deleted, which nets to absent from `--diff-filter=D` and from
  `ACMRT` alike. Every one of the nine new fixture cases went red on the first
  `ci`, and the one real branch it did match on this repo matched for the
  other reason — it had INHERITED its file. (fixed: the deleted plan or
  research file is the trigger, since the plan file lives on `main` and its
  deletion survives the net diff; the workstream deletion stays as the second
  half of a union, and `mgr-sweep` pins that half. Recorded rather than
  quietly repaired: reading a net diff as a history walk is the same class as
  `.agents/docs/feedback.md`'s tree-or-diff trap, one level in.)
- r2: (session, correctness) a ref with no merge base was skipped in silence,
  so on a SHALLOW clone — grafted history, most refs unreachable from the base
  — a retired edge among them is not counted and its slot reads free. That is
  the defect this function exists to fix, reproduced one clone deep, and the
  sibling reader had already paid for it: `owned_at` over-reports in exactly
  this case because a missing claim costs two sessions on one branch.
  Measured on this checkout, full clone: 0 of 124 refs (`git merge-base "$r"
  origin/main` per ref, 2026-09-06) — so nothing here would have shown it.
  (fixed: unreadable refs are counted and the listing says it is a floor and
  which number to distrust; no row is invented for a ref with no evidence,
  since that would hold a slot the fleet may need. A `--depth 1
  --no-single-branch` clone of the fixture origin pins it — `file://`, because
  git IGNORES `--depth` on a local clone and the first version of that case
  passed against a full clone.)
- r3: (verifier, correctness) `!unverified` was an in-band sentinel on a
  channel that carries branch names, and it is a legal git ref name. A branch
  called `!unverified` that retired an item got no row, freed its own slot,
  had its item offered again, and printed that item as the shallow caveat's
  count on a full clone — the whole defect restored by a branch name. (fixed:
  the sentinel is `..unverified`; `git check-ref-format` refuses two
  consecutive dots, so no branch can collide with it. A branch literally named
  `!unverified` is now a fixture case.)
- r4: (verifier, correctness) on a shallow clone the caveat printed while
  `slots`, the spawn list and the verdict all read clean, and
  `orchestrate.md` step 1 says "act on that output only" — so the duplicate
  was still spawned, with a warning above it. The new case asserted only the
  caveat strings, never the numbers, so it was green over exactly that.
  (fixed: a `SHALLOW CLONE` line on the VERDICT, where the spawn decision is
  made, saying an item under `spawn` may already be in flight and naming
  `git fetch --unshallow`; the case now asserts the verdict too.)
- r5: (verifier, correctness) `head -1` on the deleted-item scan: a branch
  retiring two plans named one and suppressed one, so the other was offered
  again — half the duplicate spawn surviving the fix — and the row named an
  item the branch had not finished, sending `orchestrate.md`'s by-title
  lookup after a manager that never existed. (fixed: every deleted item is
  suppressed, the row names the first and counts the rest; `mgr-both` pins it.)
- r6: (verifier, correctness) `orchestrate.md` gave two answers for a `?`
  row — the table said RESPAWN, the paragraph below said never respawn a
  branch you cannot identify. Live on this repo right now:
  `claude/upkeep-off-session`. (fixed: three table rows, one answer each; a
  `?` row is the human's, and the dispatch row itself now says so rather than
  saying it only in the command file.)
- r7: (verifier, correctness) a row printing the token `STALL?` was not in
  the stall count, so one pass gave a reader who greps and a reader who reads
  the verdict two different numbers. (fixed: one counter, `n_stall`, for both
  kinds of row.)
- r8: (verifier, correctness) the `ahead` guard could never fire — not an
  ancestor of the base already implies at least one commit the base lacks —
  and a check that cannot fail reads as a guard while guarding nothing.
  (fixed: removed, with the reasoning kept as the comment.)
- r9: (verifier, docs) the load-bearing measurement was written in four
  places, against caveman's state-each-fact-once. (fixed: the run record in
  `.agents/docs/orchestrated.md` owns it; the code and fixture comments point
  there.)
- r11: (verifier, correctness) round 2, and the sharpest one: `estem` was the
  ALPHABETICALLY first deleted item, not the item the manager was spawned on.
  A manager on `theta` that also retired `iota` was looked up as
  `manager: iota`, missed, read as gone, and `orchestrate.md` then says
  RESPAWN — two sessions on a live manager's branch. The round-2 fixture
  could not see it: `mgr-both` used `plan: lambda` with `lambda.md`+`mu.md`,
  and `lambda` sorts first, so it was green either way. (fixed: the branch's
  own retired record is read at the base whether or not items were found, and
  the item it names is lifted to the front. `mgr-order` names `xi` while `nu`
  sorts first.)
- r12: (verifier, correctness) the `n_stall` fold pinned nothing —
  `mutate` on that line said NOTHING REDDED, because the new stall case
  asserted row text only and the one verdict-count assertion runs before any
  edge branch exists. (fixed: the case now asserts the verdict's own count,
  `5 manager(s) past the stall window`, four claimed plus the one edge. The
  first version of that assertion caught a real misplacement immediately —
  the counter had landed in the CLAIMED row's branch, so the parenthetical
  counted 4 rows that all had sessions. Counted on live data afterwards:
  with the fold this repo's verdict carries `1 manager(s) past the stall
  window … (1 of them carry no claim file)`; with that one line replaced by
  `:` the verdict carries no stall line at all, 2026-09-06.)
- r13: (verifier, correctness) a deleted path containing a SPACE split the
  space-joined item field: one retired item printed as two, both naming paths
  that do not exist. (fixed: such a path is dropped, because the queue hook's
  own row pattern is `docs/plans/[^ ]*\.md` — a file it can never list is not
  an item this command can be holding.)
- r14: (verifier, correctness) the `SHALLOW CLONE` tail sat under a primary
  verdict that still said `spawn up to 1 now`, and the role is told to branch
  on the verdict line — so the warning was a note the procedure steps over.
  The verifier also refuted "no information to do it from": the sibling
  reader already unshallows. (fixed both ways: the fetch unshallows when the
  clone is shallow, exactly as `.agents/harness/handover-context.sh` does,
  with the plain prune as the fallback; and what is left when that fails is
  now the PRIMARY verdict line, `DEGRADED — shallow clone`. The spawn list is
  still printed, and a case pins that too: refusing to print one leaves an
  orchestrator with a full queue and nothing to act on, which is the one
  thing that role must never do.)
- r15: (verifier, correctness) folding the edge rows into `n_stall` left the
  sentence they feed calling a branch with no session a "manager" and
  ordering a health pass with nothing to pass over — live on this repo, every
  pass. (fixed: one count still, and the sentence names how many of them
  carry no claim file.)
- r16: (verifier, docs) the measurement disagreed with itself inside its new
  single home: `orchestrated.md` Runs says "11 of 28 passes", the Concurrency
  paragraph said "11 consecutive". (fixed: the paragraph points at Runs and
  states no number.)
- r10: (verifier, clean) checked and clean: `handover-context-owns.sh`
  untouched and green inside the suite; a merged branch drops out; a branch
  owning a workstream file is not double-counted; the `edge_items` match is
  safe against `eta.md`/`beta.md` prefix collisions; the counters increment in
  the current shell, not a subshell; no glossary term misspelled; `dispatch`
  cost over 124 refs is within noise (5370/5190/5917 ms without the helper,
  7058/5530/5858 ms with). It also re-ran `mutate` against copies: the
  workstream-deletion-only trigger reds 9 cases, the widened trigger 4, the
  suppression 1 — so r1's "nine cases" is a counted number now.

## Blockers

None here. Consumer-side acceptance (this plan SHIPS) cannot be met from this
session: GitHub scope is `chrsctl/joharness` only, and the reproduction repo
is `chrsctl/gx`. Recorded in the pull request body as the outstanding bar.

## Where to look

- `joharness.sh:cmd_dispatch` — the `--- managers in flight` loop and `n_slots`.
- `joharness.sh:dispatch_retired_edges` — the new scan.
- `.agents/harness/selftest/dispatch.sh` — the fixture, both directions.
