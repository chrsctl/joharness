# joharness

A harness that lets Claude Code sessions work on a repo for days without a
person watching. You describe what you want; sessions turn it into plans,
build each plan on its own branch, check it, and merge it. Git is the only
memory they share, so any session can stop and the next one picks up where
the last one left off.

This repo is the canonical copy. Other repos install it once and sync from
it weekly.

## The short version

You write down what you want. A small cast of Claude sessions does the rest:

- one keeps the system running,
- one hands out work,
- one per task does the work and merges it,
- a few helpers tidy up and look back at what went wrong.

Nobody waits in a chat for you. When a session needs a decision, it writes
the question down, notifies you, and stops.

```mermaid
%%{init: {'theme': 'neutral'}}%%
flowchart LR
    accTitle: Who hands work to whom
    accDescr: You write requirements and issues. The clerk turns issues into plans. The keeper keeps an orchestrator running; the orchestrator starts a manager per plan; each manager builds with workers and merges its own pull request.

    you([You]) -- requirement --> queue[("Plan queue")]
    you -- issue --> clerk[Clerk]
    scout[Scout] -- proposal --> you
    clerk -- plan --> queue
    keeper[Keeper] -- keeps one alive --> orch[Orchestrator]
    orch -- reads --> queue
    orch -- starts one per plan --> manager[Manager]
    manager -- hands sub-tasks --> workers[Workers]
    manager -- opens and merges --> main[(main)]
    manager -. question .-> you
```

## The roles

**You.** You own the goals and the money. You add requirements or open
issues whenever you like, set the budget (how many sessions may run at once),
answer questions sessions leave for you, and approve or decline ideas the
scout proposes. A few files are yours alone — the config, the permissions
and the GitHub settings — and no session may change them.

**Keeper.** A small, cheap session woken once an hour. Its only job is to
make sure exactly one orchestrator is running: it starts one if none is,
and swaps in a fresh one when the current one has run long enough to get
expensive.

**Orchestrator.** The dispatcher. Every few minutes it looks at the queue,
starts a manager for each waiting plan (up to the budget), checks that
running managers are still making progress, and stops one that is stuck —
saving its notes first so the next one can continue. It passes questions
on to you and stops when there is nothing left to do. It builds nothing and
merges nothing; keeping it simple lets it run on a cheap model.

**Manager.** The one who does the work. A manager owns exactly one plan from
start to finish: it makes a branch, keeps a short notes file about what it
is doing, builds the change, runs the checks, has someone else review it,
opens a pull request, and merges it. If it hits something only you can
decide, it writes the question down, marks itself blocked, and exits.

**Workers.** Helpers a manager starts for pieces of its task — write this
test, review this diff. They have no branch of their own and disappear when
they finish.

**Occasional helpers.** These run on their own schedule, one at a time,
and don't use up the manager budget:

| Helper | What it does |
| --- | --- |
| Clerk | Turns open GitHub issues into plans, about once a day. Issues reach the queue only this way. |
| Surveyor | When plans wait on each other because they seem to touch the same files, checks whether they really do and corrects them. |
| Scout | Researches new ideas and files them as issues, each with the case against it from a reviewer that didn't write it. An idea becomes work only after you approve it. Off until you name the GitHub login that approves its ideas and write its brief (`docs/product/SCOUT.md`); reading outside the repo is off until you switch it on too. |
| Retro reviewer | Weekly, in two modes. Audit samples finished work and checks its tests prove the right things. Trace reads the sessions that ended badly, plus audit concerns, and files plans for the checks that would have caught each failure. |

## How work flows

1. **An idea comes in** — a requirement you write, an issue anyone opens,
   or a scout idea you approve.
2. **It becomes a plan.** A requirement is challenged first — a reader
   that didn't write it looks for holes — and then split into plans. A
   plan says which files change, what is out of scope, which commands
   prove it is done, and which model tier builds it. Nothing is built
   without one, except tiny fixes. Plans for the bigger tiers get a second
   reader before building starts.
3. **The orchestrator hands the plan to a manager** once there is room in
   the budget and no running work overlaps it.
4. **The manager builds, checks and merges.** All checks must pass, a
   reviewer that didn't write the change must look at it, and the branch must
   be up to date with `main`. Optionally, with `JOHARNESS_CHECKS=local` set in
   the session's environment (not in `joharness.conf`), the manager's final
   check runs those checks itself on the agent's machine instead of waiting
   for GitHub Actions. Finished work leaves no files behind.
5. **The slot frees up**, and the orchestrator fills it on its next round.

## How the roles talk to each other

Mostly they don't, directly. Everything goes through git and GitHub:

- **Taking a task** means pushing a notes file that names it. Everyone else
  sees it as taken.
- **Progress** is measured by pushes. The orchestrator doesn't ask how a
  manager is doing; it looks at when it last pushed.
- **Questions** are written into the manager's notes file. The orchestrator
  notices and notifies you; you reply to the orchestrator and it writes your
  answer back.
- **The orchestrator's memory** travels in its own scheduled wake-up
  message, not in the repo.

Because everything lives in git, any session can die at any moment and
nothing is lost but the work since its last push.

## When you're needed

- **Decisions.** A blocked session says why — money, credentials, a product
  call, and a few others. Answer and the work resumes.
- **Protected files.** If a plan needs a change to a file only you may
  edit, the manager prepares it as a separate pull request labelled
  `human-review`. You review and merge that one yourself.
- **Approvals.** Scout ideas wait for your `approved` comment.
- **Stopping things.** Revert a merge you don't want. Add the
  `human-review` label to freeze an issue or pull request. Set the manager
  budget to 0 to pause everything, or pause the hourly heartbeat to stop
  restarts.

## Starting a session by hand

The start of your prompt decides the role:

- `/manage <plan>` — a manager for that plan.
- `/keeper` — the keeper (normally only the hourly heartbeat sends this).
- anything else — an orchestrator.

`/who` shows which sessions are working on the repo right now. `/map`
writes or refreshes the `INDEX.md` in each product folder: what the folder
is for, its interface and how to verify it.

## Commands

```bash
./joharness.sh help       # every command and config setting
./joharness.sh ci         # the checks
./joharness.sh verify     # set up the environment and smoke-test it
./joharness.sh dispatch   # what is queued and what is running
./joharness.sh finish     # whether this branch may merge now
./joharness.sh release    # claims left behind by sessions that are gone
./joharness.sh conf       # every setting, its live value and where it came from
```

## Add it to your repo

```mermaid
%%{init: {'theme': 'neutral'}}%%
flowchart LR
    accTitle: Distribution
    accDescr: joharness sets up a repo once, syncs it weekly, and takes harness fixes back first.

    canon["joharness<br/>canonical"] -- once --> boot[bootstrap-consumer.sh] --> repo[Your repo]
    canon -- weekly --> sync["update pull request<br/>or upgrade"] --> repo
    repo -. findings .-> report[Upstream report] -. fixed here first .-> canon
```

```bash
git clone https://github.com/chrsctl/joharness.git
joharness/.agents/scripts/bootstrap-consumer.sh --env docker ../my-project
```

Then follow the steps it prints. To stay current, merge the weekly update
pull request (opened every Monday) or run `./joharness.sh upgrade`.

Your repo keeps its own `docs/` (requirements, plans, notes),
`joharness.conf` and the `INDEX.md` in each product folder, which sessions
read before searching that folder; everything else is the harness and gets synced. It
receives one environment layer — the one its `joharness.conf` names — not
all of them (`.agents/env/README.md`).

## License

MIT.
