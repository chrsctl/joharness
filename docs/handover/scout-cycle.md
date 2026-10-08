---
workstream: scout-cycle
status: in-progress
branch: claude/scout-cycle
pr: none
plan: scout-cycle
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: opus
updated: 2026-10-08
next: ci + verify green, then a third verifier pass on the research-step design; then retire and PR
---

## Goal

`docs/product/scout-role.md`, second bullet: the scout cycle's MACHINERY —
one reader `dispatch` and `drain` both ask, a `scout : DUE` tail line only
at DRAINED, a cadence dated from git (merged retires AND closed proposal
branches), at most one in flight, two conf keys. What a spawned scout does
is `scout-command`. Supervised session at the human's ask (protocol text).

## Decisions

- dispatch spawns a scout ONLY under `DRAINED — nothing free, nothing in
  flight` (the exit verdict). The other two DRAINED verdicts still have a
  manager in flight or a spawn pending — real work running — so a due scout
  there prints `suppressed`. drain has one DRAINED and gates on it.
- Branch half reads HISTORY (review r1): ONE `git log --source
  --diff-filter=A` over unmerged refs `--not origin/<base>`; identity is the
  added file's frontmatter at that commit. Still at the tip = in flight
  unless done/abandoned; gone = `retired`, a proposal at the human — open or
  closed, git cannot say which, and the plan forbids the control plane here.
- Dating: the merged half's landing time, and each scout branch's TIP
  committer time (a finished scout's retire). Stamps date nothing (r2). A
  tip in the future is skipped. Consequence, accepted: an open proposal
  nobody answers for 168h lets the next scout run — one proposal per window,
  answered or not.
- No `.claude/commands/scout.md` = `off` (r6): the cycle wakes when
  `scout-command` lands, here and in each consumer.
- Automerge read from the base branch's conf, env first (r7).
- drain: the scout is offered only with no edge work and no curate/janitor
  this session must take first (r4); the block says why it is not invented
  work (r5).
- drain budget 308 -> 330, counted with `./joharness.sh perf drain`
  2026-10-08: 292 -> 295 / 302 -> 305 (CURATE_PLANS=1) as gated — the shape
  has no scout command, so the cycle reads off — and 309 / 319 with that
  check bypassed in a scratch worktree, the path once the command lands.
- `scout_due` sets globals (SCOUT_DUE, SCOUT_ROWS) instead of printing, so
  callers walk once and only when the merged half alone says due.
- Selftest fixture names prefixed `scout_`: topics are sourced into one
  shell, and `swork` clobbered the perf topic's fixture of the same name.

## Rejected

- Per-ref walk copied from janitor_branches: over the drain budget on the
  shape — a fork per ref, the regression in kind the budget exists for.
- Tip-only `git grep` walk (the first committed spelling): blind to every
  proposal at the human, because step 7 retires the file before the PR (r1).
- Dating by the `scout-<stamp>` text: one malformed or future stamp on any
  branch hid the real ones or switched the cycle off (r2).

## Review

- r1: (verifier) + `/code-review`: a scout that follows step 7 retires its workstream file BEFORE its PR opens, so an open or closed proposal carries no `scout-*.md` at the tip — invisible to the walk: not in flight, never dates the cycle; reproduced, dispatch spawns a second scout. The plan's premise ("a remote branch whose workstream file reads…") is the defect. (fixed — the walk reads branch HISTORY: one `git log --source --diff-filter=A` over unmerged refs `--not` the base finds every scout file ever added; a file still at the tip is in flight unless done/abandoned, a retired one is a proposal at the human)
- r2: (verifier) + security + `/code-review`: newest stamp picked as TEXT, then parsed — `scout-20261001` or `scout-9` beat a real `scout-2026-10-07` and parsed empty, making the cycle due; `scout-2099-01-01` clamped to 0h switched it off. (fixed — stamps no longer date anything: each scout branch is dated by its tip's committer time; a time in the future is skipped, never clamped)
- r3: `/code-review`: a closed proposal dated from its stamp (scout START), not from when the scout finished. (fixed — same change: the tip's commit time, which is the retire for a finished scout)
- r4: (verifier) + security + `/code-review`: drain printed "This is THIS session's item" for the scout with edge work in flight, or a curate or janitor due and unclaimed — two items, or one outranked by finishing. (fixed — the block prints only with no edge work and no curate or janitor this session must take first)
- r5: (verifier): drain's DRAINED lines say "exit" / "does NOT invent work", then the scout block said "your item" with no reconciliation. (fixed — the block says why a scout is not invented work: it only proposes, and nothing enters the queue until a human merges)
- r6: (verifier): cycle on by default pointing at `.claude/commands/scout.md`, which `scout-command` has not landed. (fixed — no command file = `off`, with the reason; the cycle turns on when the command exists, here and in every consumer)
- r7: security: `JOHARNESS_SCOUT_AUTOMERGE` read from the working tree's conf, so a scout's own branch could turn it on for itself. (fixed — read from the base branch's `joharness.conf`; the environment still wins, as for every key)
- r8: security: dispatch's gate set at `n_inflight - n_blocked = 0` with blocked managers still present. (fixed — the gate also needs zero managers)
- r9: `/code-review` + security + (verifier): ownership by reading the tip tree and `cat-file` on the base tip, against step 4 "DIFF against merge base"; stacked branches inherited a scout's claim. (fixed — `--not origin/<base>` reads only commits the base does not have; a branch stacked on an UNMERGED scout branch shares its commits and `--source` names one of them — recorded, not fixed: two names for one scout, never a second scout)
- r10: `/code-review` + reproduce + (verifier): the walk ran twice per drain at DRAINED, and the `scout_due` comment still described the rejected per-ref walk. (fixed — callers walk once and hand the rows to both readers; comment rewritten)
- r11: `/code-review`: a third hand-copied cycle beside janitor and curate. (wontfix — the janitor walk keeps its per-ref fork and tip ownership on purpose: its subject IS a live claim at the tip; folding three different questions into one parameterised walk is a refactor of two merged cycles, out of this plan's scope)
- r12: security: the merged half's glob identifies scouts by filename. (wontfix — it needs a MERGED branch that added and deleted `docs/handover/scout-<digit>*.md`; the janitor cycle carries the same rule, `cycle_landed_sha`)
- r13: security: tens of thousands of unmerged refs overflow one argv. (wontfix — far past any measured repo; 170 refs here, 18 unmerged)
- r14: reproduce: "301 / 311" for the first spelling cannot be re-counted — that code was never committed. (fixed — the perf note no longer cites it)
- r15: (verifier, pass 2): no `--full-history`: a scout branch that merged a main carrying a scout-named file is simplified onto main, which `--not main` hides — the add vanished and the cycle read due. (fixed — `--full-history`; the fixture is that shape, and fails without the flag)
- r16: (verifier, pass 2): drain offered the scout while a manager built, which dispatch refused on the same queue. (fixed — research step R-f: drain never offers a scout as the session's item; only the orchestrator spawns one, and dispatch sees every claim)
- r17: (verifier, pass 2): under unsupervised drain said "Exit — after open GitHub issues" and then offered the scout, which those issues outrank. (fixed — same change: unsupervised reads "Not yours: exit as above")
- r18: (verifier, pass 2): dispatch spawned the scout in the same pass as a curator and a janitor, which drain suppressed (r4 fixed one reader). (fixed — the dispatch gate also needs no curate or janitor due; case added)
- r19: (verifier, pass 2): candidates were EVERY handover file on every work branch, a fork per claimed ref; and the perf shape had no scout command, so the gate measured the cycle off and 309 / 319 came from a scratch edit (UNVERIFIED to the reader). (fixed — the pathspec admits scout files only; the shape carries `.claude/commands/scout.md`, so the gate counts the cycle on: 299 / 309, budget 320)
- r20: (verifier, pass 2): a branch stacked on a scout branch was credited by `--source` and held the cycle off for as long as it lived. (fixed — the owner is the file's own `branch:` field; case added)
- r21: (verifier, pass 2): the automerge parser disagreed with `conf_get` on an indented later line, failing toward merging. (fixed — `conf_get`'s own expression; case added)
- r22: (verifier, pass 2): `JOHARNESS_CONF` ignored by automerge, and the environment still wins. (wontfix — the base branch's word is the point; the environment is the operator's for every key, and a session setting it breaks a rule `scout.md` will state rather than a parse)
- r23: (verifier, pass 2): a renamed scout file read as retired; `Done` / `in progress` never matched. (fixed — `--diff-filter=AR` and the tip read at the added path; status lower-cased and blank-joined; `Done` case added)
- r24: (verifier, pass 2): drain's "due, suppressed — not DRAINED" printed with a scout already in flight. (fixed — printed only when none is)
- r25: (verifier, pass 2): r13's "168 refs" does not match this checkout. (fixed — r13 now reads 170, counted with `git for-each-ref refs/remotes/origin | wc -l`, 2026-10-08)

## Research step (review churn: two rounds on scout_walk)

What the branch half must satisfy, all at once:

- R-a: see a scout at work (its file at the tip of the branch that owns it).
- R-b: see a proposal at the human, open or closed (file retired, branch
  unmerged), and date the cycle from it.
- R-c: cost constant in the number of work branches — drain asks at every
  session start (`perf`).
- R-d: survive what branches do: merge main in, get stacked on, rename.
- R-e: identity from frontmatter, never a filename alone.
- R-f: one gate in both readers (drain, dispatch).

Conflicting pairs, and the resolution:

- R-e vs R-c. Frontmatter costs a `git show` per candidate; candidates were
  EVERY handover file on every work branch (verifier 2, finding 5). Resolve:
  the pathspec narrows to `docs/handover/scout-[0-9]*.md` (the name
  `scout.md` writes), frontmatter still DECIDES. Candidates = scout files
  only. The janitor cycle's merged half already keys on the same glob.
- R-b vs R-d. `--source` names whichever ref git walked first, so a stacked
  branch inherits the scout; and default simplification drops the add once
  the branch merges main. Resolve: `--full-history`, and the OWNER is the
  file's own `branch:` field, not `--source`: in flight iff that ref is
  unmerged and its tip still carries the file, status not done/abandoned;
  dated by that ref's tip. A file whose `branch:` names no unmerged ref
  dates nothing.
- R-f. drain cannot see claims in flight without dispatch's walk, and a
  supervised or unsupervised session taking a scout as "its item"
  contradicts "stop and ask" / "exit" and the open-issues rank (verifier 2,
  findings 2, 3). Resolve: only the orchestrator spawns a scout. drain
  under orchestrated says the orchestrator's; otherwise drain NAMES it for
  the human (supervised: say it when you ask; unsupervised: exit — a human
  or orchestrator starts it). Deviation from the plan's "else this
  session's item", recorded here. dispatch suppresses while a curate or
  janitor is due too (finding 4), the rule drain already had.
- Perf: the shape gets `.claude/commands/scout.md`, so the gate measures
  the path every repo pays once `scout-command` lands — no scratch-edit
  numbers (finding 5).
- Automerge: parsed with `conf_get`'s own sed on the base branch's conf
  (finding 7a). The environment stays first, as for every key: a session
  setting it is breaking a rule, not exploiting a parse (7c, wontfix);
  `scout.md` says never set it.

## Blockers

None.

## Where to look

- `joharness.sh:janitor_due`, `janitor_branches`, `cmd_janitor` — mirrored.
- `joharness.sh:cycle_landed_sha` — the dating reader.
