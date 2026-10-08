---
workstream: orchestrator-findings-2026-10-08-d
status: review
branch: claude/orchestrator-findings-2026-10-08-d
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011gvC8GiNBVUPpsRjA7XA2Q
agent: opus
updated: 2026-10-08
next: Retire this file in the last commit before the pull request, open the PR, run ci, exit without merging
---

## Goal

Reporter session. Turn two harness findings a consumer (`chrsctl/gx`) recorded
into research nodes on this repo's queue, one pull request, no merge — the
human merges. The findings are in the retired workstream file of the gx
manager that fixed `main`'s `crm` job step 11 (gx PR #520, merge `7afe8ed3`):
`git show 9c69b8e9:docs/handover/crm-c4-registry-agreement-after-512.md`,
`## Review` entries r1 (harness) and r2 (verifier, process).

Both were routed rather than fixed there, for the same reason: the files they
name are under `./joharness.sh protocol-paths`, which a manager session may
not commit to. This repo is where they land.

## Decisions

- **Two nodes, not one.** They share only their origin. F is a text-matching
  gate that refuses one spelling of a shape and allows another; G is about
  which reader of the harness owns a rule that exists nowhere. Different
  evidence, different graduation targets, and either answer leaves the other
  question exactly as open. The verifier agreed independently.
- **Neither duplicates #317, #319, #320 or #321.** All thirteen nodes those
  four ADD were read by their `## Question`
  (`git diff --diff-filter=A --name-only main...pr<N> -- docs/research/`, then
  `git show pr<N>:<path>`). They are about the orchestrator's own machinery —
  the ledger, the health table, dispatch, a merge waiver, plan identity, a red
  base reading. `guard-fires-on-an-empty-branch` is the nearest name and is
  about `handover-guard.sh` adding `branch has no upstream` to a branch with
  no commits: different guard, different failure. No cross-reference earned.
- **`--diff-filter=A` is load-bearing in that count.** Three stems appear in
  the `pr319`/`pr320`/`pr321` diffs as DELETIONS of nodes already retired on
  `main`. A plain `--name-only` read would have counted them as nodes those
  branches carry and overstated the duplication surface.
- **Premises corrected, not restated.** The report reads F as a spelling the
  deny does not name; measured, no `for` or `select` loop is judged at all, so
  its own candidate would not have fired on the command that produced it. G's
  first draft claimed the harness has no injection discipline; it ships one as
  `./joharness.sh mutate`. Both corrections are in the nodes with the
  measurement that forced them.
- **Candidate answers stay candidates.** Five in F, six in G, each priced with
  what was measured against it, three of them measured insufficient alone. No
  node picks one.

## Rejected

- **A third node for the quote-blind bound check.** `count_re` cannot read
  `[ "$n" -gt 0 ]` because a payload's quotes arrive backslash-escaped
  (measured: U denied, V allowed). It is a second defect in the same function
  and it would have been invented work — the brief is two findings, and the
  node records it as adjacent with the measurement, where whoever takes the
  guard will meet it.
- **Splitting node F into predicate and reach.** Two clauses of one branch of
  one function; an answer to either alone leaves the reported shape allowed,
  so they close together or not at all. The `## Question` says which clause is
  which instead.
- **Re-wording the consumer out of the nodes.** `docs/` is outside
  `consumer-repos.md`'s enumerated scope and `docs/product/scout-role.md` on
  `main` already names the same consumer. Both nodes carry the constraint in
  `## Graduates to` so the graduating session re-words once, deliberately,
  instead of discovering the rule at the edge.

## Review

- r1: **(verifier) both nodes reported a verification pass, in the past tense,
  that had not run at the commit under review.** `## Verification` in both
  said "Checked by a verifier subagent …" while the same commit's `## Review`
  read "Pending step 5" and `./joharness.sh review` printed "no record yet".
  Worst instance was node G's finding 8, a MEASUREMENT of a run that had not
  happened — "the tree held still until it was dead". `.agents/docs/research/README.md:117`
  makes `## Verification` the one non-optional section and asks who checked;
  three places answered about nobody. (fixed — both sections rewritten to the
  pass that actually ran, naming the tier, what it was given, how many
  findings came back and which text they changed; node G's finding 8 now
  reports the run that happened and says the sentence it replaced was written
  ahead of it.)
- r2: **(verifier, measured) node G's finding 1 was false: the harness ships
  defect injection as a command.** `./joharness.sh mutate <file> <line> <text>`
  is Loop step 5's rule as a command (`joharness.sh:9333`-`:9336`, quoting
  AGENTS.md:123 verbatim), restores the file whatever happens (`:9354`-`:9356`,
  `trap mutate_restore EXIT INT TERM` at `:9409`) and runs the suite twice
  with the defect live in the shared tree (`:9348`, `:9412`). My grep matched
  `inject`, never `mutate`, and excluded `joharness.sh`. The claim was graded
  GROUNDED. (fixed — finding 1 inverted: the harness HAS the discipline and it
  is about the tree it leaves behind, not about who else is reading, which is
  a sharper statement of the gap than the absence was. Finding 2 added: no
  instruction file names `mutate` at all. New candidate E, the only enforced
  option. Verified myself before rewriting rather than taken on report.)
- r3: **(verifier, measured) node F's candidate D claimed a counterfactual
  that is false.** "Reach, and leave the spelling list alone … smallest change
  that would have denied the reported command" — measured with the self-match
  branch reached from `for`/`select`, the reported `ps | grep` shape stays
  ALLOW and only the `pgrep -f` fixtures flip. The existing branch is keyed on
  `pgrep`/`pkill`, which the node's own finding 2 says, so D contradicted its
  own evidence. (fixed — D now states what it does deny, a 69-day `pgrep -f`
  wait allowed today, and that it does NOT deny the reported command; the
  closing paragraph says only the pair, or C with D, does.)
- r4: **(verifier, measured) node G's finding 7 rested on a premise that is
  false on this very branch.** "A verifier cannot be told to measure a
  committed sha, because step 5's diff is uncommitted" — all three files were
  committed at the sha the verifier was handed, `git status --porcelain`
  empty, and `subagents.md:31` offers `isolation: worktree`. The elimination
  argument that followed ("the preventive version has to bind the party that
  moves the tree") lost its support. (fixed — the finding now says the reader
  CAN be pinned and that neither end is eliminated, which is why the question
  is a placement decision; candidate B re-priced accordingly.)
- r5: **(verifier, measured) node G's candidate D was priced on a grep that
  could not find what it looked for.** `.agents/docs/feedback.md:145` is the
  section "## Worked example: tree or diff", rule at `:162`-`:163`, eight
  edges in its own table, and Loop step 4 points at it by name. My grep
  matched `working tree` and `tree state`; the section says *reading the
  tree*. (fixed — D re-priced upward as a file that already holds a graduated
  rule of this class, and the finding that said otherwise is gone. The
  verifier's own citation for the step 4 pointer was `:52`-`:57`, which is
  the orchestrated-mode paragraph; corrected to `:77`-`:80` by reading it.)
- r6: **(verifier, measured) node F's finding 5 named one pinned selftest
  allow where seven red.** Measured over all 80 `pbg_*` cases: the self-match
  reach flips 0 of 80; teaching the BOUND check to read `for` flips seven
  allows to DENY, five of them the prose fixtures (`:187`, `:351`, `:370`,
  `:411`, `:415`) that `bash-guard-reads-prose-as-a-loop` and four verifier
  rounds existed to close. "Its cost is a pinned allow" understated sevenfold
  and omitted the regression class. (fixed — the finding now carries both
  measured numbers and names all seven lines; it is what separates C and D
  from each other and from A. Spot-checked five of the seven lines myself.)
- r7: **(verifier, measured) two of node G's five recorded `## Method`
  commands return nothing when run as written.** BRE with an unescaped `|`
  and no `-E`, so the alternation was a literal pipe; the verifier ran both
  verbatim and got exit 1. Findings cited hits those commands cannot produce —
  `.agents/docs/research/README.md:187`, "an unrecorded method is a failed
  file". (fixed — the commands are the escaped-alternation spellings that
  actually ran, and the node says in one line that the unescaped form returns
  nothing, which is how the correction got there. The corrected form also
  surfaced `manage.md:75`, now cited.)
- r8: **(verifier, measured) node F's finding 6 had the chronology
  backwards.** "Only the later one generalizes" — `handover-guard.sh:340`'s
  tool-free prose landed at `418bfafe`, the `pgrep`-named deny at `f9ea7d67`,
  and `git merge-base --is-ancestor 418bfafe f9ea7d67` succeeds while the
  reverse fails. (fixed — the finding now states the measured order and the
  conclusion it actually supports: the property was written first, in the
  counter, and the gate narrowed to a tool after it. Re-ran the ancestry
  myself.)
- r9: **(verifier) node F's `## Method` quoted a runner that is not the one
  that produced the verdicts, and 8 of 26 fixtures appeared nowhere in the
  node** — including D, the fixture closest to the reported incident and the
  one that decides r3. The verifier declined to execute the quoted runner,
  correctly: it is code the diff supplies. (fixed — the real runner is quoted
  verbatim and all 26 fixtures are in the node, because the node is the only
  copy that survives this session and a subset is a method nobody can re-run.)
- r10: **(verifier) node F's `## Question` asserted a finding.** "and the
  measurement says it does not" — so the section was edited after the method
  ran, which is the ordering `## What would settle it` exists to protect.
  Candidates D and E were also not answers to the yes/no it asked. (fixed —
  the question is now "what must it be keyed on, and which openers must reach
  it", which every candidate answers, and the finding is gone from it.)
- r11: **(verifier) node F cited the deny message at `:235`, which is a
  shellcheck pragma.** `:233` prints "Two spellings pass:", `:234` the
  `timeout` spelling. (fixed — `:233`-`:234`, and every one of the 15 guard
  line numbers in that node re-opened and checked.)
- r12: **(verifier, measured) "capture 7 of `open_re`" is capture 7 of
  `token_re`.** Under `open_re` alone the keyword is capture 6. The code's own
  comment at `:381` uses `token_re`'s numbering; I copied the number and
  attached it to the wrong regex. (fixed — `token_re` (`:185`) named and
  cited.)
- r13: **(verifier, measured) "eleven paragraphs later" is a written number
  that does not reproduce.** Counting blocks between `manage.md:66` and
  `:152`: 13, or 10 without headings, or 9 without the fenced block. None is
  11. (fixed — "later in the same file (`:152`)", no count.)
- r14: **(verifier) node G quoted two files with no line number**, below its
  own bar and below `verifier.md:45`. (fixed — `verifier.md:74`-`:75` and
  `:80`; `subagents.md:26`, `:31`, `:37`-`:38`, `:45`.)
- r15: **(verifier) graduation-time blocker: both nodes name a consumer and
  both graduate into shipping paths.** `.agents/docs/consumer-repos.md:193`-`:212`
  bars a repository name and a consumer's plan and item names from
  `.agents/docs/` and `.agents/harness/`, and the why-explanation has to cross
  with the rule. Not a defect in `docs/`, which that scope excludes. (fixed —
  one paragraph in each node's `## Graduates to` naming the constraint and
  what the crossing prose cites instead. Cheaper here than discovered there,
  which is the verifier's own reasoning for raising it.)
- r16: **(verifier) node G's finding 3 read past the one textual hook for its
  own candidates.** `manage.md:152` calls the verifier "a subagent too" — the
  same category as the workers `:66` governs — and the node reported there was
  nothing there. The conclusion survives, since the rule is about disjoint
  FILES and the verifier touches none. (fixed — `:152` cited with that
  parenthetical, and named as the nearest attachment point for an A or C
  clause.)
- r17: **(verifier) node G's `graduates:` pre-answers its own open question.**
  The field names candidate A's home while `## Consequence` leaves the
  placement open, and the queue, `lint_graph` and `graph` read it
  mechanically. (wontfix — the key is required and single-valued, so every
  possible value selects some candidate; node F escapes only because all five
  of its candidates graduate into one file. Recorded in `## Graduates to`
  instead: the declaration selects A, the placement is open, and whoever
  closes it moves the target. Node F is clean on this point and the node says
  so.)
- r18: (mine, found while answering r2) **the verifier's report is not a
  record I can transcribe.** Two of its own citations were wrong — the step 4
  pointer at `:52`-`:57` (r5) and nothing else material — so every finding
  above was re-opened against the file before the fix landed, and r2's
  replacement claim was re-measured rather than quoted. (fixed — all 19 line
  citations across both nodes verified in place after the report, not before.)

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:256` — `judge()`, node F's subject:
  the self-match branch runs before the bound checks, and `:419` is why it
  never runs for a `for` loop.
- `joharness.sh:9333` — `mutate`, node G's subject after r2: step 5's revert
  as a command, disciplined about restoration and silent about readers.
- `.agents/docs/consumer-repos.md:193` — the rule both graduations hit (r15).
