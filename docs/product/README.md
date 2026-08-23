# Product hierarchy

Requirements above plans, plans above branches. Human adds requirements
ANY time, mid-flight fine; sessions decompose them into plans; plans run
the Loop. Every level = graph nodes ([`docs/graph.md`](../graph.md)),
files as nodes, delete-on-done as state.

```
docs/product/<requirement>.md   what product needs. Human writes. Coarse.
docs/plans/<plan>.md            how, machine-executable. Sessions write.
claude/<plan> branch + PR       execution. One per plan.
```

## Requirements

One file per requirement, shape: [`TEMPLATE.md`](TEMPLATE.md). Frontmatter
`requirement`, `priority` (`normal` | `urgent`). Body: goal + satisfied-when,
requester's words. Coarse is fine — decomposition is session work, not
human work.

- **Add** = write file on `main` (direct or PR — human's call). Hook picks
  it up next session start.
- **Unplanned** (no open plan's `requirement:` names it) = hook flags it.
  Planning = queue work: session decomposes into plans via PR, plans carry
  the `requirement:` edge. Plan queue rules: [`../plans/README.md`](../plans/README.md).
- **Satisfied** = last plan's PR deletes the requirement file with the
  plan file. Survives in history.
- Requirement with open plans = silent in hook; its plans speak.

## Branch flow

- `main` = the only long-lived line. One branch per plan, cut from `main`.
  No long-lived integration branch: PR + `ci` + review-at-edge do that
  job; a second line rots against a fleet of short sessions.
- **Start** = Claim (Loop step 3): cut `claude/<plan>`, workstream file,
  push.
- **Finish** = PR green + reviewed, merge to `main`, DELETE the remote
  branch, PR deletes plan file (+ requirement file when last plan). A dead
  branch left standing reads as in-flight work and pollutes the claims
  view — three did exactly that (2026-08-21, recovered as plans seeded
  from their workstream files).
- `urgent` = same mechanics, jumps queue.
- Merge commits on shared branches, never rebase — history rewrite breaks
  other sessions' checkouts.
- **Conflict at finish** = local view of `main` is from session start; another
  session's PR may have merged since. Before opening or merging the PR,
  `git fetch origin main` and check ahead/behind — do not trust a stale
  clone. Behind = merge `main` into branch (not rebase), resolve, re-run
  `ci`, push. Conflict does not resolve clean (semantic, unclear intent) =
  do not force-merge through it — decide-alone exception (`harness/AGENTS.md`),
  stop, record in workstream file's `Blockers`, ask human.
- **Long-running session** = re-check `git fetch origin main` ahead/behind
  periodically during Build too, not only at Finish — a conflict caught
  mid-build is cheap, one hit at finish after hours of work is not.

## Reconciliation

Consumer repos carry harness copies. One rule keeps them reconcilable: a
fix born ANYWHERE lands in joharness `main` first, then syncs out to
every consumer from there. Never consumer-to-consumer, never
consumer-only — one canonical line reconciles all copies. Sync mechanism:
`scripts/sync-to-consumer.sh` (refuses to overwrite a consumer copy
whose content canonical history does not know). Automated: seeded
`.github/workflows/update.yml` runs same sync weekly in consumer's CI,
opens pull request. Consumer-own file, like ci.yml — never synced,
consumer edits stick.

New consumer starts via `scripts/bootstrap-consumer.sh`, never by using a
raw joharness clone as-is: a raw clone carries joharness's live plan
queue, handover files and canonical marker, so its sessions work
joharness's workstream instead of the child's. Bootstrap places the
harness set, seeds consumer-own stubs, strips those leaks.
