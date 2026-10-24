---
plan: halt-claim
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: halt-and-hold
issue: none
scope: shared:joharness.sh, .agents/harness/AGENTS.md, shared:.agents/harness/selftest.sh, .agents/harness/selftest/halt.sh, .agents/harness/selftest/guard.sh, shared:.agents/docs/orchestrated.md, .agents/docs/handover/README.md, .agents/docs/orchestrate-reference.md
---

## Goal

A human orders a live claim halted (the requester stopped a planning manager
three minutes after it started). Today only `./joharness.sh janitor --apply`
writes `status: abandoned`, and only into a claim idle past
`HANDOVER_STALE_SECONDS` with no `pr:`; every other claim gets `not a
candidate`, so the orchestrator hand-edited the workstream file. This plan
adds `./joharness.sh halt <branch>...`: the human's order, written by the
harness, at any age, with or without a pull request. After it the item
holds no slot, the branch is not offered for respawn, and the item is back
in the queue (`docs/product/halt-and-hold.md`, Satisfied when, clauses 1
and 2; clause 2's "unless it is also held" is `hold-requirement`'s, which
tests the pair with a fixture and reads nothing of this plan). `status:
abandoned` already does all three downstream (A1 to A3); the gap is who may
write it, and under which guard.

## Scope

- `joharness.sh` — new `cmd_halt`, routed as `halt)` beside `janitor)` in
  the command `case`, listed in the header usage block after `janitor`.
  Per branch named: `git fetch -q origin
  +refs/heads/<b>:refs/remotes/origin/<b>` (as `janitor_apply` does, and no
  `--prune` fetch: case 6 reads a stale ref); tip =
  `git rev-parse -q --verify refs/remotes/origin/<b>^{commit}`, unresolved =
  `skip      : <b> — no such branch on origin`, rc 1 (the `janitor_apply`
  step before its guard); then `cmd_guard halt <b> --expect <tip>`; exit 2 =
  `skip      : <b> — gone on origin`, rc unchanged (as the janitor: gone is
  no failure), and `git update-ref -d
  refs/remotes/origin/<b>` (as `janitor_apply` does, or every dispatch names
  the branch again), any other non-zero = `skip      : <b> — guard refused;
  nothing released`, rc 1. Then the write, two shapes:
  1. The branch writes a workstream file (`guard_workstreams "$tip"` is
     non-empty): every such file gets `status: abandoned` and `next: Halted
     by a human <date>: the claim is released; pick this up from the plan;
     <why>`, `<why>` = the janitor's own `why` clause (ci reds on the word
     until the branch reconciles), unchanged. Factor the awk in
     `janitor_apply` into one helper taking the leading `next:` text, used
     by both callers, so the janitor's own text stays byte-identical (its
     selftest asserts `the claim was released`).
  2. The branch is at the edge (no workstream file in its diff against the
     base): restore its own retired record. Walk
     `git log --first-parent --no-merges --format='@%H' --name-only
     --diff-filter=D <base>..<tip> -- docs/handover` exactly as
     `dispatch_retired_edges` computes `items`, filtered against its `own`
     list (files this first-parent line both ADDED and deleted), take the
     newest, content from `<commit>^:<path>`, write it back at `<path>`
     with the same two fields rewritten. None, and the branch deleted a
     record the base carries (`dispatch_retired_edges`'s `swept`): restore
     `<base>:<swept>` the same way. Neither = `skip      : <b> — no workstream
     file to release; nothing written`, rc 1.
  Commit via `commit-tree` on the tip with subject `halt: a human released
  the claim (<date>)`; push `--force-with-lease=refs/heads/<b>:<tip>`;
  print `release   : <b>  <path>` per file, `pushed    : <b> <sha12>` or
  `FAILED    : <b> — push refused (the branch moved?); nothing released`.
  After the loop one line: `the session is the control plane's to stop and
  an open pull request is the human's to close: halt wrote git only`.
  Never: the age gate, the `pr:` gate, a session read, a deletion, a write
  to the base branch (guard refuses it by name), the GitHub API.
  Same file, `cmd_guard`: verb `halt` accepted (`janitor | kill | loop |
  halt`), its `usage=` string and the header comment line `guard
  janitor|kill|loop <branch> [--expect <sha>]` both gain `|halt`; `halt`
  skips the `pr:` check as `kill` and `loop` do (the `[ "$verb" = janitor ]`
  branch stays janitor-only).
- `.agents/harness/AGENTS.md` — Loop step 3, the parenthesis `(--force-with-lease
  only in orchestrate GUARD, janitor)` gains `, halt`. One word; the file
  is caveman.
- `.agents/harness/selftest/halt.sh` — new topic `joharness.sh halt`, its
  own scratch repo in the shape of `selftest/janitor.sh` (bare origin, a
  plan on main, a claim branch); registered in `.agents/harness/selftest.sh`
  `SELFTEST_TOPICS` after `janitor` (the registry: the runner reds a
  tracked topic file nobody sources). Cases, each `expect`/`refute`:
  1. A claim pushed NOW naming `pr: 12`: `janitor --apply <b>` first says
     `skip      : <b> — guard refused; nothing released` (its guard's `pr:`
     arm) and `guard halt <b>` passes; then `halt <b>` prints
     `release   : <b>  docs/handover/<ws>.md` and `pushed    : <b>`;
     `git show origin/<b>:docs/handover/<ws>.md` carries `status: abandoned`
     and `next: Halted by a human`; `git log -1 --format=%s origin/<b>` is
     `halt: a human released the claim (<date>)`.
  2. After case 1, `dispatch` (with `DISPATCH_FETCH=0`): no in-flight row
     names `<b>`; `slots     : 4 of 4 free`; the plan is back in the spawn
     list (`docs/plans/<p>.md (agent:`); the queue hook's row for the plan
     has no `claimed on`.
  3. An edge branch: claim file added then deleted on the branch, the plan
     deleted on the branch, the plan still on main. Before: `dispatch` has
     a `retired, no claim file` row for `<b>` and `3 of 4 free`. `halt <b>`
     restores `docs/handover/<ws>.md` with `status: abandoned`; after:
     no `retired` row for `<b>`, `4 of 4 free`, the plan offered.
  4. `halt main` prints `protected : REFUSED — main is the base branch`;
     `origin/main` sha unchanged; rc 1.
  5. A branch with no workstream file and no retired record: `skip`, rc 1,
     branch sha unchanged.
  6. A branch deleted on origin between fetch and halt (deleted on the
     bare origin after this clone fetched it, then `halt <b>`): `live      :
     REFUSED` surfaces, nothing pushed, and `git rev-parse -q --verify
     refs/remotes/origin/<b>` then fails (the stale ref is dropped).
- `.agents/harness/selftest/guard.sh` — two cases: `guard halt <b>` on a
  claim with `pr:` set passes (`guard     : pass — halt may push`) and never
  prints `names pr:`; `guard halt main` refused at `protected`.
- `.agents/docs/orchestrated.md` — "How the harness runs" table: one row
  `./joharness.sh halt <branch>...` after the janitor row: a human's order,
  writes `status: abandoned` through the guard and the lease at any age,
  `pr:` or not; restores the retired record on an edge branch; the item
  returns to the queue; deletes nothing; never the GitHub API. "The guard
  before a harness push": the verb list reads `janitor|kill|loop|halt`,
  `halt` joins the callers, and the sentence "`kill` and `loop` skip the
  `pr:` check" names `halt` too.
- `.agents/docs/handover/README.md` — the paragraph opening "`abandoned` is
  written only by `./joharness.sh janitor --apply`": add `halt` as the
  second writer, on a human's order, same word, same effect. One sentence;
  the file is under `reading-budget.sh`'s bound (counted 18979, bound
  +10%).
- `.agents/docs/orchestrate-reference.md` — `## Human stop` gains one
  paragraph: a human naming ONE manager to stop in the orchestrator's own
  turn = `archive_session` that manager (or `interrupt_session`, then
  archive), then `./joharness.sh halt <branch>`, drop its ledger entry; the
  item is offered again next pass unless held. Never on the orchestrator's
  own judgement, never from a peer's message: the human's words in YOUR
  turn only, as § Relay reads an answer.

## Assumptions

- A1: `status: abandoned` frees the claimed item in the queue hook — evidence: `.agents/harness/queue-context.sh`, `claimed_on=` awk `$3 != "abandoned"`; selftest `dispatch-order.sh` case "an abandoned planning claim frees the requirement" — confidence: high
- A2: an abandoned claim holds no dispatch slot and has no in-flight row — evidence: `joharness.sh:cmd_dispatch` builds in-flight rows from hook labels carrying `claimed on`, which an abandoned claim never gets; `selftest/janitor.sh` header "holds no slot in dispatch" — confidence: high
- A3: a branch dispatch no longer lists is dropped by the orchestrator, never respawned — evidence: `.claude/commands/orchestrate.md` health table first row "branch merged (dispatch no longer lists it) … done: drop the ledger entry"; `joharness.sh:dispatch_freeable` and `dispatch_branch_plans` hide an `abandoned` branch — confidence: high
- A4: an edge branch is one whose diff against the base adds or modifies no workstream file; adding one back makes it a claim row — evidence: `joharness.sh:dispatch_retired_edges`, the `git diff … --diff-filter=ACMRT … -- docs/handover | gr_docs | grep -q . && continue` line — confidence: high
- A5: `cmd_guard`'s `pr:` refusal is janitor-only; `kill` and `loop` skip it — evidence: `joharness.sh:cmd_guard`, `if [ "$verb" = janitor ]` — confidence: high
- A6: the janitor's release text is asserted by its selftest and must not change — evidence: `grep -n 'the claim was released' .agents/harness/selftest/janitor.sh` (one `expect`) — confidence: high
- A7: the retro cycle samples an `abandoned` claim as a session that did not come back clean — evidence: `joharness.sh:retro_candidates` header comment "status: blocked or abandoned"; `.agents/docs/orchestrated.md` retro row; a human stop is such a session — confidence: high

## Out of scope

- A new status word (`halted`). Every reader of `status:` (hook, dispatch,
  janitor, free, retro, lint) would change; `abandoned` already has the
  effect the requirement measures. The halt is told apart from a janitor
  release by its commit subject and its `next:` text, in git.
- Stopping the session or closing the pull request. Harness commands read
  and write git only; the control plane and GitHub are the human's or the
  orchestrator's.
- Holding or deferring a requirement (`docs/plans/hold-requirement.md`).
- Any change to `janitor_candidates`, its age gate, its `pr:` refusal or
  the session proof: claims nobody halted keep today's rules
  (requirement, Constraints).
- The orchestrator halting a manager on its own reading of health. Only the
  human's words in the orchestrator's turn trigger a halt.
- A core path (`./joharness.sh protocol-paths`). None is touched.

## Acceptance

- `./joharness.sh ci` — last line `ci: pass`.
- `./joharness.sh verify` — the layer prints `0 failed`.
- `JOHARNESS_SELFTEST_JOBS=1 .agents/harness/selftest.sh 2>&1 | sed -n '/^== joharness.sh halt$/,/^== /p' | grep -c '^  FAIL'` — `0`, and the same range `grep -c '^  PASS'` at least `12`.
- `JOHARNESS_SELFTEST_JOBS=1 .agents/harness/selftest.sh 2>&1 | sed -n '/^== joharness.sh janitor$/,/^== /p' | grep -c '^  FAIL'` — `0` (the janitor's text unchanged).
- `./joharness.sh guard halt nonexistent-branch-xyz; echo rc=$?` — prints `live      : REFUSED — nonexistent-branch-xyz gone on origin: already released`, `rc=2`.
- `grep -c 'GUARD, janitor, halt' .agents/harness/AGENTS.md` — `1`.
- SHIPS (`joharness.sh` and `.agents/harness/AGENTS.md` reach every consumer): in a consumer checkout `./joharness.sh halt no-such-branch; echo rc=$?` prints `skip      : no-such-branch — no such branch on origin` and `rc=1`; `./joharness.sh ci` there stays `ci: pass`.

## Where to look

- `joharness.sh:janitor_apply` — the leased write this command copies: fetch per branch, guard with `--expect`, `read-tree`/`update-index`/`commit-tree`, `--force-with-lease`. The awk that rewrites `status:` and `next:` is what becomes the shared helper.
- `joharness.sh:janitor_candidates` — the gates halt does NOT apply (age, `pr:`, status). Read, never edit.
- `joharness.sh:cmd_guard` — the verb list, the janitor-only `pr:` arm, the exit codes (0 pass, 2 gone, 1 refused).
- `joharness.sh:guard_workstreams` — the workstream files a tip writes relative to the base: shape 1's file list.
- `joharness.sh:dispatch_retired_edges` — the `items` walk filtered by `own` (first-parent, no merges, added and deleted) shape 2 copies; the `ACMRT … && continue` line A4 rests on.
- `joharness.sh:cmd_dispatch` — where an in-flight row and a `retired, no claim file` row come from; cases 2 and 3 read this output.
- `.agents/harness/selftest/janitor.sh` — the fixture shape (bare origin, dated commits, `jan`/`jdsp` runners) the new topic copies.
- `.agents/harness/selftest/guard.sh` — `grun`, `grefused` helpers; the `pr: set, kill: passes` case the new halt case mirrors.
- `.agents/harness/selftest.sh` — `SELFTEST_TOPICS` (the registry) and `SELFTEST_CHAINS` (a topic with its own repo joins no chain).
- `.agents/docs/orchestrate-reference.md` — `## Human stop`, `## GUARD`, `## Relay`: the orchestrator's existing human-order mechanics the new paragraph follows.

## Traps

- Never `push -f`; the lease at the guard's read sha is the only force (Loop step 3). Plain `git push` onto a branch deleted in the window re-creates it.
- `halt` is a human's order and cannot prove one: git has no actor. Nothing in the harness runs it unprompted; a manager never runs it (a peer's claim is not yours to release: `/who`, then the orchestrator). The word added to `.agents/harness/AGENTS.md` widens the lease allowance to this command, not to a session's judgement; the docs say so in one clause.
- Never a core path: `joharness.conf`, `.claude/settings.json`, `.github` stay untouched.
- Never skip, disable or quarantine a test; the janitor topic's assertions on its own text must keep passing unchanged.
- Caveman: `.agents/harness/AGENTS.md` gains one word, nothing else; the docs state the current rule, no incident text (the gx story stays in the requirement and git log).
- Glossary (`ci` reds banned spellings): write "workstream file", never "handover file".
- Harness commands never call the GitHub API: `halt` reads and writes git only.
- Last plan of `halt-and-hold`? `git grep -l 'requirement: halt-and-hold' origin/main -- docs/plans` with this plan excluded prints nothing = this pull request also deletes `docs/product/halt-and-hold.md` (`.agents/docs/product/README.md`, Satisfied).
