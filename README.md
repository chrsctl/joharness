# joharness

A working protocol for Claude Code agents. Add it to a repo and sessions pull
work from a queue, claim it on a branch, build and test it, record what the
next session needs, and merge their own pull request. All state lives in git,
so any session can stop and another can pick up where it left off.

This repo is the canonical copy. Other repos get a copy and stay current
through a sync.

![Repo layout](docs/readme/layers.png)

The harness is everything under `.agents/` and `.claude/`, plus
`joharness.sh`, `AGENTS.md` and `CLAUDE.md`. The sync owns these files. Your
own files are `docs/`, `joharness.conf`, `README.md` and the part of
`AGENTS.md` below `# Part 2 — project`. The sync never touches them.

## How it works

![Session loop](docs/readme/loop.png)

Each session runs one item through the Loop in
[`.agents/harness/AGENTS.md`](.agents/harness/AGENTS.md). Progress notes live
in a workstream file on that item's own branch (`docs/handover/`), and the
work is done only when `ci` and `verify` are green.

![Work flow](docs/readme/flow.png)

An orchestrator session spawns one manager per free plan, up to the cap in
`joharness.conf`. Managers can hand sub-tasks to subagents. You write
requirements in `docs/product/` or open issues, and you can revert anything.
The details are in [`.agents/docs/orchestrated.md`](.agents/docs/orchestrated.md).

## Usage

```bash
./joharness.sh help       # all commands and config keys
./joharness.sh ci         # the checks CI runs
./joharness.sh verify     # provision the environment, then smoke-test it
./joharness.sh dispatch   # queue and sessions in flight
./joharness.sh env k8s    # select an environment layer: docker | k8s | none
```

A session started with no prompt becomes the orchestrator. To keep sessions
starting without you, set up a scheduled Routine as described in
[orchestrated.md § Heartbeat](.agents/docs/orchestrated.md#heartbeat-making-the-fleet-long).

## Add it to a repo

![Distribution](docs/readme/distribution.png)

```bash
git clone https://github.com/chrsctl/joharness.git
joharness/.agents/scripts/bootstrap-consumer.sh --dry-run --env docker ../my-project
joharness/.agents/scripts/bootstrap-consumer.sh --env docker ../my-project
```

The script copies the harness and seeds `joharness.conf`, the CI and update
workflows, and stub `README.md` and `AGENTS.md` Part 2 files. Then do what it
prints: commit, write your rules under Part 2, and add requirements in
`docs/product/`. Don't hand-copy a clone of joharness: it carries joharness's
own queue.

To stay current, use the seeded `update.yml`, which opens a sync PR weekly, or
run `./joharness.sh upgrade`. Harness fixes land here first and reach your
repo through the next sync. All routes are in
[`.agents/docs/consumer-repos.md`](.agents/docs/consumer-repos.md).

## Contributing

Run `./joharness.sh ci` and `./joharness.sh verify`; both must be green.
Only humans edit `joharness.conf`, `.claude/settings.json` and `.github/`.

Diagrams: [diagram-design](https://github.com/cathrynlavery/diagram-design),
with HTML sources in [`docs/readme/`](docs/readme/).

## License

MIT ([`LICENSE`](LICENSE)). Consumers receive the grant as `.agents/LICENSE`
and `.agents/NOTICE`.
