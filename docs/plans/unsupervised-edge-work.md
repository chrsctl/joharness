---
plan: unsupervised-edge-work
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
scope: .agents/harness/queue-context.sh, .agents/docs/plans/README.md, .agents/harness/selftest.sh
---

## Goal

The queue hook already finds the edge and names it: with no free plan and
nothing unplanned it prints `Edge reached: no free plan — every plan
claimed or blocked. done.`, and with no plans at all it prints `... or ask
human.` Under supervised that is correct and stays. Under unsupervised the
edge is where work begins instead of where it stops.

The danger is the whole difficulty of this plan: a session inventing its
own backlog invents make-work unless something bounds it, and under this
requirement's full-loop autonomy that make-work merges without a human
reading it. The bound is a goal. Unsupervised mode is live only while a
requirement is open; the requirement's `Satisfied when` is the finish line,
and its deletion is the terminus. No open requirement means no goal, and a
session with no goal stops and asks exactly as a supervised one does.

Three things the requester named, and where each already lives in the
graph rather than being invented here:

- **Final goal** — the requirement's `Satisfied when`. Observable,
  checkable, and delete-on-satisfied makes reaching it a state change
  anyone can see (`.agents/docs/product/README.md`).
- **Guidelines** — the requirement's `Constraints`, already defined as the
  hard boundary a decomposing session must not cross, plus the source list
  below.
- **References** — the `requirement:` frontmatter edge, plus the
  `Where to look` anchors every plan carries
  (`.agents/docs/graph.md`, Edges).

## Scope

- `.agents/harness/queue-context.sh:205` and `:333` — the two edge paths,
  now three-way rather than two. Supervised: unchanged, byte for byte.
  Unsupervised with an open requirement: print the generate-work
  entrypoint, naming the requirement and the source list. Unsupervised with
  NO open requirement: print that the goal is reached and stop, in the same
  terms supervised uses. Silence in that third case would read as an
  invitation to keep going.
- `.agents/docs/plans/README.md` — the rules a generated plan obeys, in one
  place a generating session and a reviewing human both read:
  1. It carries `requirement:` naming an OPEN requirement. A plan serving
     no open requirement is not generated.
  2. It names, in its Goal, the `Satisfied when` bullet it advances. One
     bullet, named — not "advances the requirement".
  3. Its evidence comes from a CLOSED list of sources, each checkable
     against this checkout: a failing or skipped check; a `## Review`
     finding recorded on a merged branch and never acted on; a documented
     rule with no test covering it; a TODO or known-gap comment in tracked
     code; drift between an instruction file and the code it describes.
     Closed, not illustrative — a literal reader treats an open list as
     permission for anything.
  4. It cites the source and the evidence, so a human reading the queue
     later can tell observed work from invented work.
- The terminal action, in the same file: when every `Satisfied when` bullet
  of the open requirement reads true, the session deletes the requirement
  file rather than generating another plan. Reaching the goal is the last
  act, not a state to work past.
- `.agents/harness/selftest.sh` — all three edge cases in both modes, and
  the supervised wording unchanged.

## Out of scope

- Generating requirements. `docs/product/` is the human's
  (`.agents/docs/product/README.md`); a session that writes its own finish
  line has none, and the goal bound this plan exists to add would be
  circular.
- Implementing the generated plans. This plan fills the queue; the normal
  Loop empties it. A bad generator must not also be the implementer in one
  step.
- Spawning sessions — `unsupervised-fanout` owns that.
- Judging whether a `Satisfied when` bullet is really true. The session
  reads them and decides; no scoring, no heuristic. A rubric here would be
  a second definition of done competing with the requirement's own.
- Research outside the repo: upstream releases, dependency advisories, the
  web. Every listed source is checkable against this checkout, which is
  what makes a generated plan auditable.
- A cap on plans per run. Declined 2026-08-24 and still declined; the goal
  bound is what answers that risk.

## Acceptance

- Supervised, empty queue — output byte-identical to a pre-change capture,
  including `Edge reached: no free plan`. Diff and paste.
- Unsupervised, empty queue, one open requirement — prints the
  generate-work entrypoint, names that requirement, and names the closed
  source list.
- Unsupervised, empty queue, NO open requirement — says the goal is
  reached and routes to asking the human. Assert it does NOT print the
  generate-work entrypoint; this is the restriction, and a test that only
  checks the happy path does not prove it.
- Unsupervised, non-empty queue — unchanged from supervised. The edge is
  the only behavioural difference.
- Unsupervised with unplanned requirements present — still routes to
  planning those first. A requirement the human wrote outranks work the
  session invents; fixture carries both.
- End to end on a scratch repo: an unsupervised session at the edge with an
  open requirement produces a plan file whose frontmatter names that
  requirement and whose Goal names one `Satisfied when` bullet. Paste the
  generated frontmatter.
- End to end, terminal case: a requirement whose bullets all read true
  produces a deletion of the requirement file, not another plan.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed. Required: touches a
  non-`*.md` file under `.agents/harness/`.

## Where to look

- `.agents/harness/queue-context.sh:200-207` — the no-plans branch, both
  arms, including the unplanned-requirements arm that must keep winning.
- `.agents/harness/queue-context.sh:333` — `Edge reached: no free plan`.
- `.agents/harness/queue-context.sh:16` — the header comment stating "No
  free plan and nothing to plan = done", which this plan makes depend on
  the mode AND on whether a goal is open.
- `.agents/docs/product/README.md`, Requirements — `Satisfied` is already
  defined as the last plan's PR deleting the file. This plan gives that
  definition a second reader.
- `.agents/docs/graph.md`, Nodes and Edges — the Requirement node and the
  `requirement` edge this plan leans on; nothing new is stored.
- `docs/product/unsupervised-mode.md` — Satisfied when and Constraints, the
  goal bound this plan implements.

## Traps

- Not invent work is still the rule under supervised
  (`.agents/harness/AGENTS.md`). This plan branches on a mode that defaults
  to supervised, and now also on whether a goal exists.
- The no-goal case must SAY the goal is reached. A quiet fallthrough is
  indistinguishable from a hook that failed, and the session would be left
  guessing whether it may proceed.
- An open-ended source list is the failure. A literal reader given
  "sources include..." treats anything as a source.
- Human input outranks generated work in every ordering: issues, then
  requirements, then plans. The edge comes after all three are exhausted.
- No new state. Whether a goal is open is `docs/product/*.md` existing —
  the same delete-on-done the rest of the graph uses
  (`.agents/docs/graph.md`, Rules).
- Hook output is paid every session — caveman
  (`.agents/docs/caveman.md`); the source list belongs in `docs/`, pointed
  at rather than printed.
- `unsupervised-fanout` also touches `.agents/harness/queue-context.sh` and
  `.agents/harness/selftest.sh`; never parallel with it.
