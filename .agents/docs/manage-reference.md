# Manager reference

Rare branches of `.claude/commands/manage.md`, verbatim; its `ref §`
lines say when to read each; its terms hold here.

## Free

A copy task, never a build. Claim on `docs/handover/free-<key>.md`,
`workstream: free-<key>`, `plan: none`, key = the branch with every
character outside `A-Za-z0-9._-` as `-`. Push the claim, then
`./joharness.sh free <branch>`: it merges, drops the owner's workstream
files and stems DONE ON MAIN, runs `curate --apply` on the plans it brings
in only (restoring every other file curate touched), `ci`, commits. Its
refusals:

- `already merged into <your branch>` after `free` committed = done: push
  and §4.
- `holds`, `already merged into <base>`, `outside docs/`, `no such branch`,
  `shares no history`, `free takes another branch` = nothing to free: delete
  your workstream file, push, exit, no pull request.
- anything else = your own branch's state: fix it, run again.

Reset (conflict, red `ci`) = do by hand, inside a plan-only diff, what
`free` does: merge, delete the owner's workstream files, drop stems DONE ON
MAIN, retire a done record's plan, `curate --apply` (keep only the plans you
bring in), `ci`, recover lines from the owner's tip. Or block `conflict:`.
Then §4 whole; its `recover` lines and the owner branch go in the body.
Never push to the owner's branch.

## Human remainder

fits no plan and dies at retire (`.agents/docs/plans/README.md`,
"A human remainder"). Home: ONE pull request on branch `human/<stem>`,
opened before the retire commit, ready for a human to merge:

1. A separate worktree from fresh-fetched `origin/main`, never your own
   tree: `git worktree add -b human/<stem> ../<repo>-human origin/main`.
2. There, commit ONLY the core-path edit, run `./joharness.sh ci`, push
   `human/<stem>`. The edit needs a file your branch adds (`ci` red), or renames
   or moves a path the tree still uses (`ci` may pass) = the body leads with
   `merge after <your branch> lands on main`, naming that branch; `ci` red
   for any other reason = fix it there first. This commit is the one exception to the boundary (Loop
   step 2) and to a spawn prompt's "never commit under those paths": it
   never lands on your branch, and a human merges it.
3. `create_pull_request` from `human/<stem>`: title `human: <stem>: <edit,
   one line>`, body = the plan's reason, the `ci` result, and "merge is the
   human's"; then label it `human-review` (`issue_write` `update`), and read
   the label back (`pull_request_read` `get`). You
   never merge it, never approve it, never relabel it, and never push to it
   again unless the human asks.
4. `git worktree remove ../<repo>-human`.

Your own pull request body says `Refs #<core PR>`. The pull request carries
the plan's carve-out, nothing new. The push, `create_pull_request` or the
label fails = step 4, then `status: blocked`, `next:` = `github: human PR
not opened: <error, 40 chars>`, push, exit — never retire with it unopened
or unlabelled.

## Surveyor

For every held plan AND every
holder, read its `## Scope`; then, in frontmatter `scope:` only:

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

## Plan issue

Plan names `issue: N`? Plan carries a `## Issue remainder` section: body
carries `Refs #N`, never `Closes #N`. Otherwise body carries
`Closes #N` when no other plan on fresh `origin/main` names it
(`git grep -l -E '^issue: *#?N([^0-9]|$)' origin/main -- docs/plans`, yours
excluded), else `Refs #N`. That issue's labels (`issue_read`, `get_labels`,
one read when you open the pull request) include `scout`, or its title starts
`scout:`? Title starts `scout: ` and the pull request carries the
label `scout` (`issue_write` update on its number, labels); a follow-up
plan-only pull request for that work too. Nothing in the plan file marks
it.

## Link the issue

Right after the pull request opens, for EACH issue number
its body names with `Closes #N` or `Refs #N` (the plan's issue, a
human-remainder issue, any other):
post ONE comment on that issue (`add_issue_comment`): `PR #<M> <what it does
for this issue, one line>: <PR url>`, ending with the attribution footer the
session's system prompt names. One comment per issue per pull request; never
edit the issue's body or labels for it. A comment fails: name the failed call
in your final report line, never block, never retry — the `Closes`/`Refs` line
still links it.

## Lead

After the merge, send it as one message on the transport your prompt
names, in the orchestrator's grammar — `lead <stem>: <text>`, text at most
40 characters:

```
lead seat-limits: its create path skips the same check
```

A session id target: Claude Code Remote send_message. A name: SendMessage.
**The stem must be a QUEUE ITEM's name** — one you can name from your plan's
`needs:`, its `scope:` collisions, or the reconcile your prompt named. A lead
with no such stem (an issue, a merged item, the harness itself) goes in your pull request body
instead; a stem-less lead that is a DEFECT goes where the next paragraph says. Nothing to say is the normal case: send nothing, just exit.
Never send your own findings. One lead, its own line, nothing after the text,
no quotes or newlines. No transport line in your prompt, or one refusal: just
exit — no retry, no second transport. Run no queue command.

## Defect

1. It reproduces on fresh-fetched `origin/main` (run the same command on a
   checkout of it). No reproduction = it is your branch's: fix it in your item.
2. Search this repository's open issues for the same failing command or test
   name. Found issue M = file nothing; pull request body says `Refs #N` with the fresh
   reproduction (command, count, `origin/main` sha) in one line beside it.
   Then ask: does this defect stop your item meeting its Acceptance?
   - **No:** steps 3–5 as written.
   - **Yes, and step 2 found M:** park on M. M carries `human-review`? Say so
     in `next:`; `defect-resume`'s UNPLANNED row then reaches the human.
   - **Yes, nothing found:** file the issue as step 3 does, with NO labels,
     then park. The clerk plans it urgent (`.claude/commands/clerk.md` §3).
   - **Park** = `status: blocked`, `next:` = `defect: #<n>: <one line>`, push,
     exit. No `human-review` on the pull request or the plan's issue.
   - `issue_write` fails: block `github: defect not filed: <error, 40 chars>`,
     issue text under `## Blockers`.
3. Otherwise ONE issue per session (`issue_write` `create`) on this
   repository, before the retire commit: title
   `defect: <test or command>: <symptom, one line>`; body = the command, at
   most 20 lines of its output, the `origin/main` sha it reproduced on, and
   your branch name; labels `human-review` (none when blocking, step 2). Pull request body says `Refs #N`,
   never `Closes #N`.
4. A second defect in the same session: step 2 runs for EVERY defect. A
   match = step 2's `Refs #N` line. Only an unmatched second or later defect
   is pull request body only, one line each.
5. Non-blocking: `issue_write` fails: put the issue text in the pull request body under a
   line `defect not filed: <error, 40 chars>`. Never block or delay the item
   for it.
6. Not for harness defects found in a consumer (those go to canonical,
   `.agents/docs/feedback.md` §4) nor core-path edits (the human-remainder
   paragraph, §2).

For a non-blocking defect the
label holds the issue from the clerk until the owner removes it; no session
removes it.
