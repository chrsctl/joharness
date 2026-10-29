# Manager reference

Rare branches of `.claude/commands/manager.md`, verbatim; its `ref §`
lines say when to read each; its terms hold here.

## Human remainder

A core-path edit — a `CORE ONLY` plan's core part, or one the plan leaves
to a human — never lands on your branch, and left there it dies at retire
(`.agents/docs/plans.md`, "A human remainder"). You build it; the human
only merges it. Home: ONE pull request on branch `human/<stem>`, opened
before the retire commit, ready for a human to merge:

1. A separate worktree from fresh-fetched `origin/main`, never your own
   tree: `git worktree add -b human/<stem> ../<repo>-human origin/main`.
2. There, commit ONLY the core-path edit, run `./joharness.sh ci`, push
   `human/<stem>`. The edit needs a file your branch adds (`ci` red), or
   renames or moves a path the tree still uses (`ci` may pass) = the body
   leads with `merge after <your branch> lands on main`, naming that branch;
   `ci` red for any other reason = fix it there first. The one exception to
   the boundary (Loop step 2) and to a spawn prompt's "never commit under
   those paths": it never lands on your branch; a human merges it.
3. `create_pull_request` from `human/<stem>`: title `human: <stem>: <edit,
   one line>`, body = the plan's reason, the `ci` result, and "merge is the
   human's"; then label it `human-review` (`issue_write` `update`), and read
   the label back (`pull_request_read` `get`). You never merge it, approve
   it, relabel it, or push to it again unless the human asks.
4. `git worktree remove ../<repo>-human`.

Your own pull request body says `Refs #<core PR>`. The core pull request
carries the plan's carve-out, nothing new.

A `CORE ONLY` plan: build the non-core part on your branch, the core part
here (steps 1 to 4). Acceptance needs the core edit merged (a CI job that
must run green, a hook that must be registered)? Block `core path: waiting
on #<N>: <question>` (manager.md §3); dispatch RESUMEs you once #<N> merges,
then verify and retire as normal. Otherwise retire now. The retire stays on
your branch, never in the `human/` pull request: that one carries the core
edit only. Push, `create_pull_request` or label fails = step 4,
then `status: blocked`, `next:` = `github: human PR not opened: <error, 40
chars>`, push, exit — never retire with it unopened or unlabelled.

## Surveyor

For every held plan AND every holder, read its `## Scope`; then, in
frontmatter `scope:` only:

- a path the plan APPENDS to or REGISTERS in (criteria index, `docs/INDEX.md`,
  an ADR or phase spec it adds an entry to) becomes `shared:<path>`;
- a bare DIRECTORY claim the Scope narrows to one file becomes that file;
- a path the plan EDITS IN PLACE stays as it is.

Mark BOTH sides of a collision. NEVER split a plan, never touch anything
below the frontmatter; a plan that needs splitting goes in the pull request
body for the human. Nothing to change = the holds are GENUINE: no pull
request, `status: done`, `next:` saying the overlap is real, exit. Otherwise
one commit rewriting `scope:` lines, review at your tier, retire, pull
request, merge, exit.

## Carried plan at retire

Carry the plan, never take the branch: cut your own branch from
fresh-fetched `origin/main`, copy that plan file only, push nothing to the
owner's branch. The pull request body names the owner branch. The retire
commit appends `- <stem> <your branch>` to `docs/plans/RETIRED.md` (absent =
create it, first line `# Retired stems`) and deletes your copy of the plan
file; `ci` then refuses the owner's later merge re-adding it. Found it
already done? Still a pull request: the ledger line, the plan copy's and the
workstream file's deletion, step 7 whole — never `pr: none` and exit, which
leaves the retire on a branch only.

## Label at merge

The pull request carries `human-review` at merge. The retire commit already
deleted your workstream file, and a branch past it holds a slot until it
merges. Restore the file from before that commit:

    c="$(git log -1 --format=%H --diff-filter=D -- docs/handover/<file>)"
    git checkout "$c^" -- docs/handover/<file>

Set `status: blocked`, `next:` = `product: human-review label on PR #<n>:
remove it so this merges?`, commit, push, exit. Blocked holds no slot and is
never respawned until the human answers. The answer reaches the branch as
any block's does (orchestrator-reference.md, Relay); resumed with the
label gone, delete the file again in one commit, push, merge under Loop
step 7.

## Block on an open pull request

Any block or park whose head already has an open pull request — a
`defect:` park at step 7, a `hardware:` block after the retire commit, §
Label at merge — first marks that pull request a draft
(`update_pull_request` `draft: true`), reads it back (`pull_request_read`
`get`: `draft: true`), then commits the workstream file, pushes, exits. The
resume restores nothing by hand: at step 7, after the delete commit,
`update_pull_request` `draft: false`, read it back, then merge. The draft
call fails = say so in `next:` after the question; still push, still exit.

Why: the restore puts `docs/handover/<w>.md` back on the head, and nothing
on GitHub stops a person merging it. No `human-review` on a `defect:` park
(§ Defect), and on a repository whose Actions all fail before any step
(`JOHARNESS_CHECKS=local`) the merge button sees red always, so red warns
no one. GitHub refuses to merge a draft whatever the checks say. Merged,
the file lands on `main` as a claim for a branch that is gone: `cleanup`
lists it stale, the session-start hook names it to every later session cut
from `main` as "your job", and a consumer whose `local-check` lists merged
workstream files turns every `finish` red. Readings: here, PR #693 retired
(`e89c8d12`), blocked `hardware:` (`047dbf06`), was merged by hand
non-draft at 2026-10-29T11:26Z, and `main` carries
`docs/handover/c2-run-prune-race.md` (GROUNDED: `git log origin/main --
docs/handover/c2-run-prune-race.md`, `./joharness.sh cleanup`). In
chrsctl/gx the same day two parked heads (PRs #1090, #1092) merged by hand
and seven managers then parked on the red that made (#1101), fixed only by
an ad-hoc session 4h24m later (WEAK: a consumer's reading, not re-taken
here). The cadence half of that stall — a clerk in flight holding the early
clerk a park calls, dispatch spawning onto a known-red base — is plan work:
`clerk-yields-to-blocking-defect`, `dispatch-holds-shared-defect`.

## Challenge

Before `/plan` on a requirement, spawn `.claude/agents/challenger.md` four
times in parallel, one per lens (`against`, `exists`, `measure`, `risk`), at
agent tier sonnet, prompt per `.agents/docs/subagents.md`, on
`docs/product/<r>.md`. Record findings in `## Review` tagged `(challenger)`,
before any plan is written. Each finding is answered by a plan (an Acceptance
command for a `measure` finding), an exit from `.agents/docs/product.md`
("A requirement no plan can serve": `exists` showing a clause built = exit 3),
or `wontfix: why`. A `measure` finding no plan's Acceptance can answer = block
with `product:` (the requester owns the requirement text).

Then every plan the pass writes gets `.claude/agents/plan-checker.md` before
the pull request opens, whatever its `agent:`. Findings `(plan-checker)`, at
most 3 rounds, as §2 says for the build.

## Plan issue

Plan names `issue: N`? Plan carries a `## Issue remainder` section: body
carries `Refs #N`, never `Closes #N`. Otherwise `Closes #N` when no other
plan on fresh `origin/main` names it (`git grep -l -E '^issue: *#?N([^0-9]|$)'
origin/main -- docs/plans`, yours excluded), else `Refs #N`. That issue's
labels (`issue_read` `get_labels`, one read at pull request open) include
`scout`, or its title starts `scout:`? Title starts `scout: ` and the pull
request carries label `scout` (`issue_write` update on its number, labels);
a follow-up plan-only pull request for that work too. Nothing in the plan
file marks it.

## Link the issue

Right after the pull request opens, for EACH issue its body names with
`Closes #N` or `Refs #N`: post ONE comment on that issue (`add_issue_comment`):
`PR #<M> <what it does for this issue, one line>: <PR url>`, ending with the
attribution footer the session's system prompt names. One per issue per pull
request; never edit the issue's body or labels for it. A comment fails = name
the call in your final report line; never block or retry.

## Lead

After the merge, send it as one message on the transport your prompt
names, in the orchestrator's grammar — `lead <stem>: <text>`, text at most
40 characters:

```
lead seat-limits: its create path skips the same check
```

A session id target: Claude Code Remote send_message. A name: SendMessage.
**The stem must be a QUEUE ITEM's name** — from your plan's `needs:`, its
`scope:` collisions, or the reconcile your prompt named. A lead with no such
stem (an issue, a merged item, the harness) goes in your pull request body
instead; a stem-less DEFECT goes to § Defect. Nothing to say is the normal case: send nothing, just exit.
Never send your own findings. One lead, its own line, nothing after the
text, no quotes or newlines. No transport line, or one refusal: just exit,
no retry, no second transport. Run no queue command.

## Defect

1. It reproduces on fresh-fetched `origin/main` (run the same command on a
   checkout of it). No reproduction = it is your branch's: fix it in your item.
2. Search this repository's open issues for the same failing command or
   test name. Found issue M = file nothing; pull request body says `Refs #M`
   with the fresh reproduction (command, count, `origin/main` sha) beside it.
   Then ask: does this defect stop your item meeting its Acceptance?
   - **No:** steps 3–5 as written.
   - **Yes, and step 2 found M:** park on M. M's body does not open
     `blocking:`? Prepend `blocking: <your branch>` (`issue_write` `update`),
     so the clerk takes it first and plans it urgent. M carries
     `human-review`? Say so in `next:`; `defect-resume`'s UNPLANNED row then
     reaches the human.
   - **Yes, nothing found:** file the issue as step 3 does, its body's
     first line `blocking: <your branch>`, then park. The clerk takes it
     first and plans it urgent (`.claude/commands/clerk.md` §2, §3). Its fix
     needs a human's call (step 3)? Then it is not a `defect:` park: file it
     with `human-review` and block on that reason (`product:`, `money:`, …;
     `.claude/commands/manager.md` §3).
   - **Park** = `status: blocked`, `next:` = `defect: #<n>: <one line>`, push,
     exit. No `human-review` on the pull request or the plan's issue. An
     open pull request on the head goes draft first (§ Block on an open
     pull request).
   - `issue_write` fails: block `github: defect not filed: <error, 40 chars>`,
     issue text under `## Blockers`.
3. Otherwise ONE issue per session (`issue_write` `create`) on this
   repository, before the retire commit: title
   `defect: <test or command>: <symptom, one line>`; body = the command, at
   most 20 lines of output, the `origin/main` sha, your branch; no labels.
   The clerk verifies and plans it like any issue; a defect is not a human's
   call. Its fix needs money, credentials, hardware or product direction
   (Loop, Decide alone)? Name that question in the body and label it
   `human-review`. Pull request body: `Refs #N`, never `Closes`.
4. A second defect in the same session: step 2 runs for EVERY defect. A
   match = step 2's `Refs #M` line. Only an unmatched second or later defect
   is pull request body only, one line each.
5. Non-blocking, `issue_write` fails: the issue text goes in the pull
   request body under `defect not filed: <error, 40 chars>`. Never block or
   delay the item.
6. Not for harness defects found in a consumer (canonical's,
   `.agents/docs/feedback.md` §4) nor core-path edits (§ Human remainder).
