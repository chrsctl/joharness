# Harness

Caveman file: every line loads into every session, so rules only. Why lives in
`.agents/docs/` — read there before fighting a rule. Style:
[`.agents/docs/caveman.md`](../../.agents/docs/caveman.md). Contested terms
have ONE spelling: [`.agents/docs/glossary.md`](../../.agents/docs/glossary.md);
`ci` fails on the others.

## Loop

1. **Orient.** Hook prints handover state. Names a workstream file for this
   branch? That is your job: read it whole, go to 4. Compacted? Re-read THIS
   file and your role command, not only the workstream file. Before saying
   what is done, read the branch's merged pull requests.
2. **Pick.** Finishing outranks starting: edge work in flight (`pr:` set, or
   `status:` review/done), oldest first; LIVE on another session (`/who`) =
   not yours. Then open GitHub issues (through `/clerk` into plans), then
   `docs/product/*.md`, then `docs/plans/*.md` and `docs/research/*.md`.
   `dispatch` names stale claims? Prove each session gone (ARCHIVED or not
   found), then `./joharness.sh janitor --apply <branch>...`.
   `curate : DUE`? `/curate` first. Plan naming an open `research:` is blocked.
   NOTHING builds unplanned — decompose into a plan first
   (`.agents/docs/plans/README.md`); copy or sync task is the one exception.
   Plan's `agent` tier binds: below it, record wanted tier, push, hand off
   (`.agents/docs/agent-selection.md`). Orchestrator reads `./joharness.sh
   dispatch` and spawns (`/orchestrate`); manager works the ONE item its
   prompt names (`/manage`); otherwise `/start`. Nothing left: exit, say
   DRAINED, invent nothing. Boundary:
   no commit to a core path (`./joharness.sh protocol-paths`).
3. **Claim.** Branch from `main`. Write `docs/handover/<workstream>.md`. Push
   NOW — no push, no claim. Overlap? `/who`; only `RUNNING` = taken.
4. **Build.** Research first: every plan or issue claim is a hypothesis until
   checked against code. `./joharness.sh feedback <path>` on files you will
   touch. Design question open? Settle it, record it, THEN code. Does a
   branch own a file? Diff against merge base, never read the tree.
   Consumer product work opens no non-`.md` file under `joharness.sh`,
   `.agents/harness/`, `.agents/scripts/`, `.agents/env/`: read `.md` docs and
   command output. Anchor points there = anchor wrong. Exempt: canonical,
   sync or upgrade task, verifier.
5. **Verify.** All green or not done: `./joharness.sh ci` and
   `./joharness.sh verify`, before the pull request. Trust counted numbers,
   never written ones. Edge review always, depth by plan tier, plus
   `.claude/agents/verifier.md` at the branch's tier — tag its findings
   `(verifier)`. Findings go in the workstream file's `## Review` as
   `- rN: text (fixed|wontfix: why|no change)`, same commit as the fix; clean
   pass = one line saying so. `./joharness.sh review` prints depth and
   record state. Fix undoes an earlier fix? Stop patching; research step at
   raised tier (`.agents/docs/agent-selection.md`, review churn). Test for a
   fix must FAIL without it. Tree holds still while your verifier lives
   (`.agents/docs/subagents.md`). Measured number names the command and when.
   NEVER skip, disable or quarantine a test to get green. NEVER kick CI.
   Background command must be able to finish (bound it); never `pgrep -f`
   a pattern your own command line carries.
6. **Hand over.** Workstream file updated in SAME commit as code, before
   ending any unfinished turn. `/handover` writes it.
7. **Finish.** PR, merge to `main` yourself — own PR only (opened by this
   session, or handed to it). Merge when ALL hold:
   - GitHub checks green on head (`JOHARNESS_CHECKS=local`: `finish` runs
     `ci` + `verify` instead);
   - branch 0 behind fresh-fetched `origin/main` — behind = reconcile first
     (`.agents/docs/product/README.md`, "Conflict at finish");
   - `./joharness.sh verify` green when the diff touches non-`*.md` files
     under `joharness.sh`, `.agents/harness/`, `.agents/env/`,
     `.agents/scripts/` — unless this head's checks verified the selected
     layer (read the run; a skipped layer proves nothing);
   - `./joharness.sh finish` green;
   - edge review recorded; no unresolved human review thread.

   Merge-commit method only. Human veto = revert. PR body carries the
   command that recovers its workstream file. LAST commit before the PR
   opens deletes the workstream file and done plan file (+ requirement file
   when last plan); keepers go to `AGENTS.md` or `docs/` first. Never delete
   branches (`git push --delete` is human-only). Merge button not yours?
   Retire and record review BEFORE asking the human. Infrastructure state
   is re-checked every time, never inherited. One item per session.

## Decide alone

- Implementation yours. Interface signatures not yours.
- Scope change too big to ratify alone? Decide, write down, flag for human.
  Do not stop.
- Block ONLY for money, credentials, hardware, product direction, or a
  merge conflict into `main` that does not resolve clean. Block =
  `status: blocked`, `next:` = `<reason>: <question>`, push, exit. Never wait in
  session.
- Consumer repo: no harness upkeep in a session holding product work; a sync
  opens its own pull request (`.agents/docs/consumer-repos.md`).

## Handover

- Shape: `.agents/docs/handover/TEMPLATE.md`; protocol:
  `.agents/docs/handover/README.md`.
- Write only what git cannot tell: goal, decisions, rejected paths,
  blockers, next step.
- Copy or sync task: no workstream file.
