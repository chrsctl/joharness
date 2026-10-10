# joharness

Harness for long-running Claude Code work: sessions claim items from a queue,
build them on their own branch, hand over through git, and merge their own
pull requests. This repo is the canonical copy; consumer repos sync from it.

```mermaid
flowchart TB
    accTitle: Repo layout
    accDescr: A repo running joharness has its own files on top and the synced harness below.

    subgraph yours["Yours: never synced"]
        direction LR
        docs["docs/<br/>requirements, plans, workstream files"]
        conf["joharness.conf<br/>environment, checks, manager cap"]
    end
    subgraph harness["Harness: synced"]
        direction LR
        claude[".claude/<br/>role commands, session hook, verifier"]
        protocol[".agents/harness/ + .agents/docs/<br/>the Loop and its reasons"]
        env[".agents/env/#lt;name#gt;/<br/>docker, k8s or none, provisioned lazily"]
        sh["joharness.sh<br/>entrypoint for every command and hook"]
    end
    docs ~~~ conf
    claude ~~~ protocol ~~~ env ~~~ sh
    yours ~~~ harness
```

## How it works

Each session takes one item through the Loop in
[`.agents/harness/AGENTS.md`](.agents/harness/AGENTS.md):

```mermaid
flowchart LR
    accTitle: Session loop
    accDescr: Seven steps from orient to finish; git is the only memory between sessions.

    orient[Orient] --> pick[Pick] --> claim[Claim] --> build[Build]
    build --> verify["Verify<br/>ci + verify green"] --> handover[Hand over] --> finish["Finish<br/>PR, merge"]
    finish -. next session .-> orient
    git[("Git + GitHub")]
    claim -. branch, push .-> git
    handover -. workstream file .-> git
    finish -. merge .-> git
    git -. state .-> orient
```

How work moves through the roles. The bounds are in
[`.agents/docs/orchestrated.md`](.agents/docs/orchestrated.md):

```mermaid
flowchart LR
    accTitle: Work flow
    accDescr: Issues become plans; the orchestrator spawns a manager per plan, which opens and merges a pull request.

    issue[GitHub issue] -- triages --> clerk[Clerk]
    clerk -- writes plan --> queue[("Plan queue<br/>docs/plans/")]
    queue -- claimed by --> manager[Manager]
    orch[Orchestrator] -- spawns --> manager
    manager -- delegates --> workers[Workers<br/>subagents]
    manager -- opens --> pr[Pull request]
    pr -- merges itself --> main[(main)]
    you([You]) -. requirements, veto .-> queue
```

## Usage

```bash
./joharness.sh help       # commands, config keys
./joharness.sh ci         # checks
./joharness.sh verify     # provision + smoke test
./joharness.sh dispatch   # queue, sessions in flight
```

## Add to a repo

```mermaid
flowchart LR
    accTitle: Distribution
    accDescr: joharness bootstraps a repo once, syncs it weekly, and receives harness fixes first.

    canon["joharness<br/>canonical"] -- once --> boot[bootstrap-consumer.sh] --> repo[Your repo]
    canon -- weekly --> sync["update.yml PR<br/>or upgrade"] --> repo
    repo -. findings .-> report[Upstream report] -. fix first .-> canon
```

```bash
git clone https://github.com/chrsctl/joharness.git
joharness/.agents/scripts/bootstrap-consumer.sh --env docker ../my-project
```

Then follow the steps it prints. To update, merge the weekly `update.yml` PR
or run `./joharness.sh upgrade`. Details:
[`.agents/docs/consumer-repos.md`](.agents/docs/consumer-repos.md).

## License

MIT.
