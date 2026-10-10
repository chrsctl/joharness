# joharness

**joharness is a working protocol for AI coding agents.** You drop it into a
repository, and Claude Code sessions in that repository stop being one-off
chats. They pick up work from a shared queue, claim it on a branch, build it,
prove it with tests, write down what the next session needs to know, and
merge their own pull request. Nothing is kept in a session's memory. Git and
GitHub hold all of it, so any session can stop at any moment and another one
can carry on.

This repository is the **canonical** copy of the harness. Other repositories
("consumers") receive a copy of it and stay current through a weekly sync.

> The files under `.agents/` are written for agents: short, rule-only lines in
> a deliberately terse "caveman" style. This README is the one page written
> for people.

---

## What problem it solves

Coding agents are good at a single task and poor at a long project. Every new
session starts with an empty context. Without a protocol, sessions redo each
other's work, overwrite each other's files, forget why a decision was made,
and call things "done" that were never tested.

joharness answers that with a few firm rules:

- **Git is the only memory.** A session writes down only what git cannot
  tell: the goal, the decisions, the paths it tried and rejected, the blocker
  and the next step. That note is the *workstream file*, one per piece of
  work, on that work's own branch.
- **One session, one item.** Each session owns exactly one plan, on its own
  branch, from claim to merge.
- **Nothing builds unplanned.** Work enters as a requirement or a GitHub
  issue, is broken into plans under `docs/plans/`, and only then built.
- **All green or not done.** `./joharness.sh ci` and `./joharness.sh verify`
  must pass before a pull request is opened, and a second agent that did not
  write the change reviews it.
- **Humans keep the levers that matter.** Money, credentials, product
  direction and the merge gate stay with people. Agents decide implementation
  on their own and stop only for those.

---

## What's in the box

![The six layers of a repo running joharness](docs/readme/layers.png)

A repo running the harness has two halves.

The **harness** half is copied from joharness and kept current by the sync.
You don't edit it in a consumer.

| Path | What it is |
| --- | --- |
| `joharness.sh` | The single entrypoint. Every hook and every command goes through it. Run `./joharness.sh help` for the full list. |
| `.agents/harness/` | The protocol: the Loop, the rules, and the session-start hooks that print the current state into each new session. |
| `.agents/docs/` | The reasoning behind every rule. Read this before you argue with a rule. |
| `.agents/env/<name>/` | One *environment layer*: what the sandbox needs to run your project. `docker` is plain Docker plus Compose, `k8s` adds a local k3d Kubernetes cluster, and `none` means no environment at all. |
| `.claude/` | Claude Code wiring: the SessionStart hook, the role commands (`/orchestrate`, `/manage`, `/handover`, `/who`, ...) and the verifier agent. |
| `AGENTS.md`, `CLAUDE.md` | Loaded into every session. Everything above the `# Part 2 — project` marker is harness; everything below it is yours. |

The **yours** half belongs to the repo and is never overwritten by a sync.

| Path | What it is |
| --- | --- |
| `docs/product/` | Requirements: what the product needs, in your words. |
| `docs/plans/` | The plan queue: how each requirement gets built, one plan per branch. |
| `docs/handover/` | Live workstream files, one per piece of work in flight. |
| `joharness.conf` | Your switches: which environment layer, when to provision it, how checks run, how many managers may run at once. |
| `README.md`, `AGENTS.md` Part 2 | Your project's own description and rules. |

Environments are **lazy by default**. A session reads the environment's rules
only when it touches the environment, and nothing is downloaded or started
until something asks for it. A session that never needs Docker never pays for
it.

---

## How a session works

![The seven-step session loop](docs/readme/loop.png)

Every working session follows the same loop. It is defined in
[`.agents/harness/AGENTS.md`](.agents/harness/AGENTS.md).

1. **Orient.** The SessionStart hook prints the handover state: which branch
   this is, whether a workstream file already exists for it, and what is in
   flight elsewhere.
2. **Pick.** Finishing beats starting. Work already near the edge comes
   first, then open issues, then requirements, then plans.
3. **Claim.** Branch from `main`, write the workstream file and push straight
   away. An unpushed claim does not count.
4. **Build.** Research first: every claim in a plan or issue is a hypothesis
   until it is checked against the code.
5. **Verify.** `./joharness.sh ci` and `./joharness.sh verify` both green,
   plus a review by the verifier agent, with its findings recorded.
6. **Hand over.** Update the workstream file in the same commit as the code,
   so a session that dies mid-task leaves a usable trail.
7. **Finish.** Open the pull request and merge it once checks are green and
   the branch is up to date with `main`. The last commit deletes the
   workstream file and the finished plan. Git history keeps both.

Then the next session starts at step 1 and reads what this one left behind.

---

## How work flows through the roles

![From GitHub issue to merged commit](docs/readme/flow.png)

The harness runs in one mode, **orchestrated**, with a few roles, each a
slash command in `.claude/commands/`:

| Role | What it does |
| --- | --- |
| **Orchestrator** | Reads the queue with `./joharness.sh dispatch` and spawns one manager session per free item, up to the cap in `joharness.conf`. It watches their health and restarts stuck ones. It never builds anything itself. |
| **Manager** | Owns exactly one item from claim to merge. It may hand sub-tasks to worker subagents, but the branch, the review and the merge are its own. |
| **Worker** | A subagent inside a manager's session that does one sub-task and returns. |
| **Clerk** | Turns open GitHub issues into plans, in a plan-only pull request. |
| **Curator** | Keeps the plan queue honest: proposes how to split and order plans. |
| **Surveyor** | Corrects plans whose declared file scope keeps them blocked behind other work. |
| **Scout** | When the queue is empty, proposes new requirements. A human merges or rejects the proposal. |

Each plan names the **agent tier** (haiku, sonnet, opus or fable) that should
implement it. Mechanical work runs on a cheap model and hard design work on a
strong one. See [`.agents/docs/agent-selection.md`](.agents/docs/agent-selection.md).

**Where you come in:** you write requirements under `docs/product/` (or open
GitHub issues), set the numbers in `joharness.conf`, and stay in charge of
money, credentials and product direction. Agents merge their own pull
requests. A human veto is a revert.

---

## Using it day to day

Start a Claude Code session in the repo. The hook prints the state. With no
other prompt, the session takes the orchestrator role and works through the
queue until it reports `DRAINED`.

Commands you will reach for:

```bash
./joharness.sh help        # every subcommand and config key
./joharness.sh ci          # the same checks GitHub runs, locally
./joharness.sh verify      # provision the environment, then smoke-test it
./joharness.sh dispatch    # what's in flight, what's free, what spawns next
./joharness.sh review      # review depth this branch needs, and whether it's recorded
./joharness.sh feedback    # what past reviews found, overall or for one <path>
./joharness.sh env         # which environment layer is selected
./joharness.sh env docker  # select a different one
./joharness.sh setup       # provision the selected environment now
```

In a session, `/who` shows which other sessions are working on which
branches, and `/handover` writes this branch's workstream file.

To keep the fleet going without anyone starting sessions by hand, create a
**heartbeat**: a scheduled Routine that starts a fresh orchestrator session
on an interval. Recurring spend is your call, so the harness documents the
heartbeat but never creates one. The setup and its traps are in
[`.agents/docs/orchestrated.md`](.agents/docs/orchestrated.md#heartbeat-making-the-fleet-long).

---

## Adding the harness to a new repo

![One canonical, many copies](docs/readme/distribution.png)

Don't copy files by hand, and don't clone joharness and start working in the
clone. A raw clone carries joharness's own work queue and its canonical
marker, so its sessions would end up working on joharness. Use the bootstrap
script, which copies the harness and seeds the files that belong to you.

**1. Get the canonical next to your project.**

```bash
git clone https://github.com/chrsctl/joharness.git
```

**2. Do a dry run.** It reports what it would do and writes nothing.

```bash
joharness/.agents/scripts/bootstrap-consumer.sh --dry-run --env docker ../my-project
```

`--env` picks the environment layer (`docker`, `k8s` or `none`). Only that
layer is copied. Leave the flag out to start with `none` and choose later.

**3. Bootstrap for real.**

```bash
joharness/.agents/scripts/bootstrap-consumer.sh --env docker ../my-project
```

In a terminal, the script asks about each switch: environment layer, when
to provision it, how to load its rules, and whether the review record gates
`ci`. Press Enter to accept the default. In a script or CI run it asks
nothing and uses the defaults. It also seeds the files that belong to the
new repo: `joharness.conf`, `.github/workflows/ci.yml`,
`.github/workflows/update.yml`, a stub `README.md` and a stub for
`AGENTS.md` Part 2.

**4. Finish the steps it prints.**

1. `git init` and make a first commit, if the directory isn't a repo yet.
2. Write your project's rules in `AGENTS.md`, below the
   `# Part 2 — project` marker.
3. Write your first requirements under `docs/product/`. This is where the
   queue starts.
4. Replace the stub `README.md`.
5. Pick a root `LICENSE` for your project. The harness's own MIT grant
   ships in `.agents/LICENSE` and `.agents/NOTICE`, and covers only the
   synced files.
6. Run `./joharness.sh ci` and push.

Already copied joharness whole by mistake? Point the same script at that
clone. It spots the canonical marker, strips it, and deletes joharness's live
plans and workstream files. The script refuses to run on a repo that already
runs the harness, so it can't wipe live work.

### Staying current

The seeded `.github/workflows/update.yml` runs the sync every Monday at 06:00
UTC (and on demand from the Actions tab). It opens a single pull request,
branch `joharness-update`, with the changes and a report. Review it and merge
it like any other pull request. You can also pull updates yourself:

```bash
./joharness.sh upgrade --dry-run   # report only
./joharness.sh upgrade             # fetch canonical and sync this repo forward
```

Set a `JOHARNESS_UPDATE_TOKEN` repository secret if joharness is private to
you, or if the update pull request should run CI. Without it, GitHub won't
run checks on a pull request opened by a workflow.

To change a switch later, run this from the canonical checkout:

```bash
joharness/.agents/scripts/bootstrap-consumer.sh --reconfigure ../my-project
```

### Fixes go upstream first

If a consumer finds a bug in the harness, the fix lands in joharness `main`
first and reaches every consumer through the sync. A fix never goes from one
consumer straight to another, and never stays only in one consumer. The full
procedure, including how to report from a consumer, is in
[`.agents/docs/consumer-repos.md`](.agents/docs/consumer-repos.md).

---

## Working on joharness itself

This repo *is* the harness, so harness work happens here. Before a change is
done, both of these must be green:

```bash
./joharness.sh ci        # expect: ci: pass
./joharness.sh verify    # expect: 0 failed
```

A few paths are core and only a human changes them: `joharness.conf`,
`.claude/settings.json` and `.github/`. They cover money, permissions and the
merge gate. `./joharness.sh protocol-paths` prints the list.

Further reading, for people and agents alike:

- [`.agents/docs/handover/README.md`](.agents/docs/handover/README.md): the handover protocol and why it is shaped this way
- [`.agents/docs/orchestrated.md`](.agents/docs/orchestrated.md): roles, health checks, bounds, the heartbeat
- [`.agents/docs/plans/README.md`](.agents/docs/plans/README.md): how plans are written and queued
- [`.agents/docs/consumer-repos.md`](.agents/docs/consumer-repos.md): every way to create or update a consumer
- [`.agents/env/README.md`](.agents/env/README.md): the environment layer contract
- [`.agents/docs/caveman.md`](.agents/docs/caveman.md): the house style for agent-facing files

The diagrams on this page are built with the
[diagram-design](https://github.com/cathrynlavery/diagram-design) skill. The
HTML sources sit next to the images in [`docs/readme/`](docs/readme/). Open
one in a browser to see it full size, or re-export it after editing.

---

## License

MIT. See [`LICENSE`](LICENSE). The grant travels with the harness: every
consumer receives [`.agents/LICENSE`](.agents/LICENSE), a byte-identical copy
of the root file, and [`.agents/NOTICE`](.agents/NOTICE), which says what the
grant covers and names the third-party material distilled into
`.agents/docs/`. A consumer's own root `LICENSE` stays its own choice.
