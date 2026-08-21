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
- **Unplanned** (no open plan carries `req: <requirement>`) = hook flags
  it. Planning = queue work: session decomposes into plans via PR, plans
  carry the `req:` edge. Plan queue rules: [`../plans/README.md`](../plans/README.md).
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

## Reconciliation

Consumer repos carry harness copies. One rule keeps them reconcilable: a
fix born ANYWHERE lands in joharness `main` first, then syncs out to
every consumer from there. Never consumer-to-consumer, never
consumer-only — one canonical line reconciles all copies. Sync mechanism:
`harness-sync` plan.
