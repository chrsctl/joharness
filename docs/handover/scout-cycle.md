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
next: Retire, open the PR, merge on green
---

## Goal

`docs/product/scout-role.md`, second bullet: the scout cycle's MACHINERY —
one reader `dispatch` and `drain` both ask, a `scout : DUE` tail line only
at DRAINED, a cadence dated from git (merged retires AND closed proposal
branches), at most one in flight, two conf keys. What a spawned scout does
is `scout-command`. Supervised session at the human's ask (protocol text).

## Decisions

- dispatch spawns a scout ONLY under `DRAINED — nothing free, nothing in
  flight` with zero managers (blocked ones included), and no curate or
  janitor due or in flight, and a fresh view of every branch this pass
  (fetch ran, worked, and its refspec reaches `refs/heads/*`). drain NEVER offers a scout as the session's
  item: orchestrated = the orchestrator's; supervised = name it to the
  human; unattended = exit. Deviation from the plan's "else this session's
  item" (research step R-f).
- In flight: two content-free `git grep` listings (`-l`, `-L`, empty `-E`
  pattern) over every unmerged tip AND the base tip, pathspec
  `docs/handover/scout-[0-9]*`; the PATH decides, never content (every
  filter failed open); in flight unless status is `abandoned`, on any tip.
  Nothing self-declared names a scout's branch (R-g: fail closed). A branch stacked on an unretired scout
  reads in flight — closed and visible.
- Dating: newest of the merged half (`cycle_age_h scout`, landing time) and
  the newest scout RETIRE on unmerged history (`scout_retired_ts`: one `git
  log --full-history --diff-filter=D ... --not origin/<base>`). Not the tip
  (a reconcile merge or janitor release would re-date), not a stamp
  (self-declared). Future times read as now (closed). Accepted: an open proposal nobody
  answers for 168h lets the next scout run — one proposal per window.
- The retire half and the tip walk run only when they can change the
  answer / when someone reads in-flight rows (`scout_due` sets globals).
- No `.claude/commands/scout.md` = `off`: the cycle wakes when
  `scout-command` lands, here and in each consumer.
- Automerge from the base branch's conf with `conf_get`'s expression; the
  environment first, as for every key.
- drain budget 308 -> 315: 292 -> 299, 302 -> 309 (CURATE_PLANS=1),
  `./joharness.sh perf drain` 2026-10-08; the shape carries the scout
  command so the gate counts the cycle on; margins kept at the merge
  base's 16 / 6.
- Selftest fixture names prefixed `scout_`: topics share one shell.

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
- r13: security: tens of thousands of unmerged refs overflow one argv. (wontfix — far past any measured repo; 170 refs here, 17-18 unmerged — it drifts)
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
- r26: (verifier, pass 3): owner from the self-declared `branch:` field, read at the ADD commit: a field that differs from the ref drops the scout and dispatch spawns a second — r20's fix failed open. (fixed — addendum R-g: in flight is read from each ref's own tip, nothing self-declared decides)
- r27: (verifier, pass 3): dating by the owner's tip let a janitor's `abandoned` commit or a reconcile merge restart the 168h window. (fixed — dated by the newest RETIRE commit on unmerged history; an abandoned scout retired nothing)
- r28: (verifier, pass 3): dispatch spawned a scout with a janitor or curator IN FLIGHT; drain the same. (fixed — the gate also needs none in flight, in both readers)
- r29: (verifier, pass 3): drain's second suppressed line printed with a scout in flight, or naming the scout itself as the edge. (fixed — a scout in flight prints its IN FLIGHT rows first, in every branch of the gate)
- r30: (verifier, pass 3): the perf note's "the same 11 as before" — at the merge base 308 cleared 302 by 6; 320 added slack. (fixed — budget 315 keeps the merge base's margins exactly: 16 on the gated reading, 6 on the curate case)
- r31: (verifier, pass 3): comments and `## Decisions` describing superseded designs ("its stamp dates the cycle", "this session's item", `--source`, 308 -> 330). (fixed — rewritten to the code)
- r32: (verifier, pass 3): reason line said "(open, or closed by a human)" for any row; drain silent on an UNREADABLE scout cadence; a `= unsupervised` test against the plan's Traps; r13's 18 unmerged reads 17 now. (fixed — reason names a finished scout; drain prints UNREADABLE as the curate block does; `unattended` decides; r13 says 17-18, it drifts)
- r33: (verifier, pass 4): a scout marked `done` but not yet retired was neither in flight nor dated — dispatch spawned a second scout on one that had just finished. (fixed — only `abandoned` leaves flight; `done` holds until the retire dates it)
- r34: (verifier, pass 4): frontmatter filters failed open — CRLF, no `plan:`, `plan: "none"`, `Scout-...`, a path in `plan:` each dropped a scout in flight. (fixed — the PATH decides, in both halves; CR stripped before the status read)
- r35: (verifier, pass 4): dispatch spawned on a view it knew was stale (fetch failed). (fixed — a failed fetch holds the spawn, and says so)
- r36: (verifier, pass 4): a retire dated 120s in the future — ordinary clock skew — read as no retire; the selftest pinned that open direction from r2. (fixed — a future time reads as now: closed; the case now asserts not due)
- r37: (verifier, pass 4): a human deleting a closed proposal's branch deletes git's only record of it, and the cycle reads due. (wontfix — the human's act, step 7 allows it; written in `scout_retired_ts`'s comment)
- r38: (verifier, pass 4): two texts still described tip dating (`joharness.sh` help, orchestrated.md row). (fixed)
- r39: (verifier, pass 4): between a scout's spawn and its first push dispatch still says due; only an orchestrator ledger guard stops a second spawn — `scout-command`'s scope (`scouted=<stamp>`), and the cycle stays off until that plan's command lands. (no change here — carried to scout-command: it must not land without that guard)
- r40: (verifier, pass 5): the `^workstream:` content grep was a frontmatter filter after all — `Workstream:`, indented, `workstream :`, a stub with none, and a user's `grep.patternType=fixed` each hid a scout in flight. (fixed — the listing reads no content: empty `-E` pattern, `-l` plus `-L`, colour off; cases for the stub and the patternType)
- r41: (verifier, pass 5): a retire inside a merge commit (`merge --no-commit`, `git rm`) was invisible — plain `log` shows merges no diff. (fixed — `-m` in `scout_retired_ts` and, for the scout kind only, in `cycle_landed_sha`; case added)
- r42: (verifier, pass 5): the byte-identical "inherited" skip hid a scout whose file reached main before its retire. (fixed — no skip; the base tip is read too; any copy not abandoned on any tip is in flight; rows keyed on file AND status, since a path-only key let an older abandoned copy hide the base's live one; case added)
- r43: (verifier, pass 5): `DISPATCH_FETCH=0` spawned on a view of unknown age. (fixed — no fetch holds the spawn as a failed one does; the selftest's dispatch fetches its own bare origin)
- r44: (verifier, pass 5): the comment said a far-future retire holds "one window after each read"; it holds for as long as its branch stands. (fixed — comment says so; closed by design)
- r45: (verifier, pass 5): "the PATH decides" contradicted by the content grep four lines on; the CRLF test passed either way. (fixed by r40; the stub and patternType cases fail without it)
- r46: (verifier, pass 6): a single-branch or depth-1 clone fetches main alone — the fetch succeeds, no scout branch is ever seen, dispatch spawned. (fixed — a `remote.origin.fetch` that does not reach `refs/heads/*` holds the spawn, as a failed fetch does; case added)
- r47: (verifier, pass 6): a ref pruned between `for-each-ref` and `git grep` / `git log` makes git exit 128 and print nothing for ANY ref; the status was discarded. (fixed — exit status kept: a grep error is one in-flight row `unreadable`, a log error a retire NOW; not reproduced as a race here — the mechanism was, by the verifier)
- r48: (verifier, pass 6): `GIT_LITERAL_PATHSPECS` / `GIT_NOGLOB_PATHSPECS` turn the glob literal and empty every reader. (fixed — pinned to 0 on all three readers; case added)
- r49: (verifier, pass 6): a branch-controlled file name containing `|<path>=in-progress|` forged the seen-key and hid the live copy. (fixed — exact entries in a newline list; the case's own fixture first failed to write the decoy — a `/` in the name — and passed vacuously; it now asserts the file exists)
- r50: (verifier, pass 6): a scout file committed as a symlink is listed by neither `-l` nor `-L`; a retire with a clock 168h BEHIND reads old. (wontfix — no scout command produces a symlink; a past time cannot be told from a real one; both written in the code's comments)
- r51: (verifier, pass 6): no case made an EMPTY scout file, so `-L` could be deleted green. (fixed — case added; fails with `-L` removed)
- r52: (verifier, pass 6): the patternType case pinned nothing `-E` adds — with an empty pattern every type matches every line. (no change — kept as a regression case for config-driven listing; r45's claim about it corrected here)
- r53: (verifier, pass 6): the merged-side `-m` in `cycle_landed_sha` had no case. (fixed — a retire inside a merge, then merged; the case checks the AGE, since without `-m` an older proposal still reads "since the last proposal merged"; fails with `-m` removed)
- r54: (session) after reconciling with main (24 behind), ci went red: `lint_existed` read a `needs:` target retired on a merged side branch as "never existed" — default history simplification follows the branch parent of the reconcile merge. Red on every branch reconciling after such a retire, not on main. (fixed — `--full-history` in `lint_existed`; a ci-graph-lint case reproduces the reconcile shape and fails without it)
- r55: (session) the seventh verifier pass, on the pass-6 fixes, did not run: the account's weekly usage limit (resets 2026-10-14). (no change — six independent passes are recorded above; the pass-6 fixes carry reverted-fix proofs, and every case added since fails with its fix removed)

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

### Addendum — the churn rule fired again (verifier pass 3)

r20's resolution (owner = the file's `branch:` field) undid r9's safety: a
field that differs from the real ref drops the scout, and the cycle fails
OPEN — a second scout spawns (pass 3, finding 1). The requirement the first
resolution missed:

- R-g: every failure must be CLOSED — a misread may hold the cycle off
  (a human sees `IN FLIGHT` and acts), never spawn a second scout.

Revised resolution for R-a / R-b / R-d, nothing self-declared deciding:

- In flight (R-a): ONE `git grep -l` over every unmerged ref's TIP, pathspec
  `docs/handover/scout-[0-9]*.md`; a hit whose frontmatter is a scout with
  status not done/abandoned is in flight on THAT ref. A hit the base branch
  carries byte-identically is inherited, not the branch's, and skipped. A
  branch stacked on an unretired scout reads in flight too — closed, safe,
  visible.
- Dating (R-b): the RETIRE, not the tip. ONE `git log --full-history
  --diff-filter=D` over unmerged refs `--not` the base, same pathspec: the
  newest deletion of a scout file is when a scout last finished. A later
  reconcile merge or a janitor release does not re-date (pass 3, finding
  2): an abandoned scout retired nothing. Deletion times in the future are
  skipped.
- R-c holds: two git calls, plus one per scout file at a tip.

## Blockers

None.

## Where to look

- `joharness.sh:janitor_due`, `janitor_branches`, `cmd_janitor` — mirrored.
- `joharness.sh:cycle_landed_sha` — the dating reader.
