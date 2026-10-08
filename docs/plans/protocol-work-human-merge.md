---
plan: protocol-work-human-merge
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: none
scope: shared:joharness.sh, .agents/harness/queue-context.sh, .agents/harness/handover-guard.sh, shared:.agents/harness/AGENTS.md, shared:.claude/commands/manage.md, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, .agents/docs/unsupervised.md, .agents/docs/plans/README.md, joharness.conf, .agents/harness/selftest/protocol-work.sh, shared:.agents/harness/selftest.sh
---

## Goal

Requester, 2026-10-08: "Joharness should be able to be developed in
orchestrator mode which is forbidden." This repo runs `JOHARNESS_MODE=orchestrated`,
and here the harness IS the product, so nearly every plan names a protocol
path in `scope:`. `unattended()` marks every such plan `SUPERVISED ONLY`.
`./joharness.sh dispatch` on 2026-10-08 (canonical `main` 25733a6) listed 9
of 9 queued plans under `NOT YOURS`, so the orchestrator can only answer
DRAINED. The bound exists so that a session nobody watches cannot rewrite
the rules that govern it (`.agents/docs/unsupervised.md`, Bounds). This plan
keeps that guarantee and moves where it is enforced. The edit stays allowed
and the merge becomes the human's. A manager builds, verifies, reviews and
retires as usual. It then stops at ready-for-HUMAN, which step 7 already
defines for a PR whose merge is not yours. It never merges a diff that
touches protocol text. The human reads the PR and merges it, or closes it as
a veto. The rule-change is then authorised by a human hand, which is what the
bound protects.

## Scope

- `joharness.sh`:
  - New predicate `protocol_work()`. It returns 0 only when ALL hold: `unattended`,
    `JOHARNESS_CANONICAL=1` in `$CONF`, and `JOHARNESS_PROTOCOL_WORK=human-merge`
    (from env for one command, else `$CONF`). Any other value, or an absent key,
    = 1. It fails closed, like `run_mode`. It is canonical-only by
    construction: in a consumer, protocol text is synced from the canonical
    and an edit there is upkeep (`.agents/harness/AGENTS.md`, Harness upkeep).
    Do NOT add the key to `.agents/scripts/conf-keys.sh`.
  - New `protocol_core_paths()`, which returns `joharness.conf` and
    `.claude/settings.json`. These stay forbidden even under `protocol_work`:
    the conf holds the mode, the cap and this key (money and autonomy), and
    settings holds hooks and permissions. A plan scoped to a core path stays
    `SUPERVISED ONLY`.
  - `cmd_finish` — under `protocol_work`, a diff (merge base to HEAD) touching any
    `protocol_paths` entry prints `HUMAN MERGE — diff touches protocol text:
    <paths>; open the pull request, retire, stop` and exits red. The finish
    gate is the one guard that fires before the merge
    (`.agents/harness/AGENTS.md` step 7).
  - `cmd_dispatch` — free list: a plan the queue hook marks `HUMAN MERGE` is
    spawnable. Only core-path plans stay under `NOT YOURS`. In-flight rows: a
    claim with `status: review`, a `pr:` set, and a protocol diff reads
    `HUMAN MERGE: the human's, holds no slot`. It is counted out of the
    in-flight total the same way `status: blocked` is (see the
    `n_blocked` subtraction) and is never STALL?. File claims still hold, as
    for blocked.
  - `cmd_authority` — also reports the `JOHARNESS_PROTOCOL_WORK` line and
    whether its setting commit is an ancestor of `origin/main`. Same rule as the mode
    line: an unmerged flip is not authority.
  - The session-start banner — under `protocol_work`, the boundary list is
    replaced by: "protocol text: edit allowed, merge is the human's
    (HUMAN MERGE); never edit: <core paths>".
- `.agents/harness/queue-context.sh` — under `protocol_work`, a plan with a
  non-core protocol path in `scope:` is marked `HUMAN MERGE` and stays in the
  free list. A core path still marks `SUPERVISED ONLY`. The hook reads the
  predicate's inputs the same way it reads `qc_unattended` today. Keep one
  definition of the core list: pass it in from `joharness.sh` as
  `protocol_paths` is passed today.
- `.agents/harness/handover-guard.sh` — under `protocol_work`, a protocol
  diff no longer blocks the stop. It is reported as `HUMAN MERGE pending`. A
  core-path diff still blocks.
- `.claude/commands/manage.md` — a new `## Never` line: never merge a
  diff `./joharness.sh finish` reports `HUMAN MERGE`. At that point: run the
  retire commit, open the PR with the body starting `HUMAN MERGE`, set
  `status: review` and `pr:`, push. If your prompt named a target to message,
  send it `human-merge <stem>` instead of `merged <stem>`. Then exit.
- `.claude/commands/orchestrate.md` — health-table handling for the
  `HUMAN MERGE` row: report it once per run, never nudge, never respawn,
  never kill. Spawn rule: `HUMAN MERGE` plans are spawned like free ones.
- `.agents/harness/AGENTS.md` — step 7: one sentence. A diff `finish`
  reports `HUMAN MERGE` is ready-for-HUMAN, not yours to merge. Step 2: the
  `SUPERVISED ONLY` sentence names the `HUMAN MERGE` exception. Write both in
  caveman style.
- `.agents/docs/unsupervised.md` Bounds, first bullet, and
  `.agents/docs/orchestrated.md` (a "What the mode changes" row and a health
  table row) — the rule and why. Edit authority moves to merge authority, and
  this applies on the canonical only.
- `.agents/docs/plans/README.md` — the paragraph on protocol paths in
  `scope:` names `HUMAN MERGE`.
- `joharness.conf` — add `JOHARNESS_PROTOCOL_WORK=human-merge` under the
  mode block, with a comment: who decided, the date, and what it changes. This
  is a core path, so the line lands from THIS supervised build and from no
  other session.
- `.agents/harness/selftest/protocol-work.sh` — new topic, registered in
  `SELFTEST_TOPICS`. Cases: canonical + orchestrated + key → protocol plan
  free and marked `HUMAN MERGE`; core-path plan still `SUPERVISED ONLY`;
  consumer (no canonical marker) + key → unchanged `SUPERVISED ONLY`;
  key = `yes` (unrecognised) → unchanged; `finish` red with `HUMAN MERGE` on
  a protocol diff; `dispatch` row `HUMAN MERGE` holds no slot; guard does
  not block a protocol diff but blocks a core one.

## Out of scope

- Unlocking `joharness.conf` or `.claude/settings.json` for any session.
  Money, autonomy and permissions stay with the human.
- Self-merge of protocol diffs under ANY setting. There is no `auto` value.
  Adding one is a new plan for the human to ratify.
- Consumers. The predicate is false there by construction. No sync change
  and no bootstrap question.
- The issue role (`docs/plans/issue-triager-role.md`). It is separate work.
- Touching `.agents/docs/` beyond the three files named. The rest is
  reasoning, not rules.
- Removing `unsupervised` (`docs/plans/drop-unsupervised.md`). Not this
  plan's job.

## Acceptance

- `./joharness.sh ci` → `ci: pass`.
- `bash .agents/harness/selftest.sh` → `0 failed`, with the `protocol-work`
  topic listed and every case passing. Count them from the run.
- `JOHARNESS_MODE=orchestrated ./joharness.sh dispatch` on this repo after
  merge → no plan under `NOT YOURS` except one scoped to `joharness.conf` or
  `.claude/settings.json`. Protocol-scoped plans appear in the spawn list
  marked `HUMAN MERGE`.
- `JOHARNESS_PROTOCOL_WORK=off JOHARNESS_MODE=orchestrated ./joharness.sh dispatch`
  → the same `NOT YOURS` block as before this plan (all protocol plans).
- `./joharness.sh authority` → names the `JOHARNESS_PROTOCOL_WORK` line and
  VERIFIABLE.
- SHIPS: `joharness.sh` and `.agents/harness/` reach every consumer. A consumer
  must see no change: the selftest's no-canonical-marker case is the check
  a consumer runs.

## Where to look

- `joharness.sh:protocol_paths` — the list, and the comment saying why each
  entry is there. The core subset comes from that reasoning.
- `joharness.sh:unattended` — the one predicate. `protocol_work` builds on
  it and never replaces it.
- `joharness.sh:cmd_dispatch` — the `NOT YOURS` block, and the
  `BLOCKED: the human's, holds no slot` row with its `n_blocked`
  subtraction, which the new row copies.
- `joharness.sh:drain_supervised_only` — the filter `drain`/`dispatch` share.
- `joharness.sh:cmd_finish`, `joharness.sh:fin_gate` — where red-before-merge lives.
- `joharness.sh:cmd_authority`, `joharness.sh:authority_commit` — VERIFIABLE for a conf line.
- `.agents/harness/queue-context.sh:qc_scope_class` — the marking.
- `.agents/harness/handover-guard.sh` — the boundary block that cites
  `joharness.sh:unattended`.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — case shape to copy.

## Traps

- Protocol text: this plan IS protocol text and touches `joharness.conf`.
  Build it SUPERVISED ONLY, `JOHARNESS_MODE=supervised` exported, with a
  human present. The fleet cannot unlock itself, and that is the point.
- Fail closed. Every unrecognised value, a missing canonical marker, or an
  unreadable conf resolves to today's behavior.
- Do not add a second `= orchestrated` / `= unsupervised` test. Read
  `unattended` (its own comment says why).
- `drop-unsupervised` and `scout-cycle` also edit `joharness.sh` and
  `joharness.conf`. Reconcile at finish and do not force.
- `issue-triager-role` shares `joharness.sh`, `.agents/harness/AGENTS.md`,
  `manage.md`, `orchestrate.md` and `orchestrated.md` (`shared:` in both).
- A test written for the fix must FAIL without it. Revert, run, restore.
