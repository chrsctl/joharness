---
research: merged-ref-batch-prose-vs-code
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/harness/AGENTS.md
---

## Question

After the merged-ref batch, do `joharness.sh` and step 7 still state three
facts that canonical's own `perf` and a consumer's own `joharness.conf`
contradict?

## Echo

A report from a consumer, `chrsctl/gx`, which synced `c1a7257` and merged it
as `chrsctl/gx#355`. The code in that sync is correct — a reader that did not
write it rebuilt both hooks against `sed`-restored copies carrying the old
per-ref `merge-base --is-ancestor` and got byte-identical output over a
fixture holding one merged and one unmerged branch. What did not travel
correctly is the PROSE around it: three sentences that describe the batch, or
the key that gates the step it changed, and that no longer say what their own
subject measures.

What rests on the answer: whether the conf-comment rule `38818b3` graduated
covers the case a consumer actually presents, and whether `14 is sized from
the regression it must catch` is still a measurement or has become a number
the file states and no longer pins.

Canonical cannot see the first of these at all. It has no consumer, so the
conf it reads is always the long one.

## Sweep

`goal-directed` — everything needed to decide whether each of the three
sentences is repairable prose or a rule that has drifted. Not a sweep of the
harness's comments generally, and not of the batch's code, which the consumer
already established as sound.

## What would settle it

For each sentence, either:

- the sentence names a fact that a command re-counts to the stated value, in
  BOTH canonical and a consumer bootstrapped before the key existed — it
  stands, and this node closes having found the report wrong; or
- a command run in either repo returns something else, or the file the
  sentence points at does not carry what it promises there — the sentence is
  repaired and the repair lands in the file named in `graduates:`.

The headroom finding has a third outcome and it is the interesting one: if
11 is defensible, then `14 is sized from the regression it must catch` is the
sentence to change, not the budgets. Both are decidable by re-counting the
regression, which the file already documents at +25/+26 per ref and +20 per
edge.

## Method

Run in `chrsctl/gx` at its merge of the sync (`93f870c2`), and in this repo at
`c1a7257`, 2026-09-12:

```
grep -c 'JOHARNESS_CHECKS' /home/user/gx/joharness.conf
grep -n 'JOHARNESS_CHECKS' .agents/scripts/conf-keys.sh
sed -n '151,155p' .agents/harness/AGENTS.md
git log -p -1 -- .agents/docs/consumer-repos.md
sed -n '1236,1246p' joharness.sh
sed -n '1690,1701p' joharness.sh
./joharness.sh perf                       # both repos
JOHARNESS_CURATE_PLANS=1 ./joharness.sh perf drain    # consumer
./joharness.sh upstream claude/joharness-gx-update-iw0xc9   # consumer
```

## Findings

- **Step 7 points at a key a consumer's `joharness.conf` does not contain,
  and the rule forbidding exactly that shipped in the same sync.**
  `.agents/harness/AGENTS.md:154` reads *"the trade is written at the key that
  sets it, `joharness.conf`"*. In `chrsctl/gx`, `grep -c 'JOHARNESS_CHECKS'
  joharness.conf` returns **0** — not a shorter comment, no key at all — while
  this repo's copy carries the key plus its 8-line trade at `joharness.conf:44-56`.
  `38818b3` added the rule to `.agents/docs/consumer-repos.md` and its own text
  says the case was *"found 2026-09-11 cutting `.agents/harness/AGENTS.md`,
  where a `JOHARNESS_CHECKS=local` sentence was about to be replaced by
  exactly such a pointer; the wording was made true against the shorter seeded
  copy instead."* The premise is *shorter seeded copy*. A consumer bootstrapped
  before the key was declared has no copy, and `.agents/scripts/conf-keys.sh:49`
  is what reaches it: the sync names the key and its default in its report and
  writes nothing without a terminal — which `sync-to-consumer.sh` did on this
  sync, printing `JOHARNESS_CHECKS (default github)` under *settings this repo
  does not answer*. So the fact is delivered, by a route the sentence does not
  name, and the sentence itself is false where it is read.

- **`joharness.sh:1242` describes the path the batch removed.** `perf_shape`'s
  inventory still reads `merged refs   the cheap path: one ancestor check
  each.` After the batch there is no per-ref ancestor check: the shape's merged
  refs cost one `for-each-ref` between them. The line is outside the batch's
  hunks, which is why it survived — its subject is what the hunks deleted. Cost
  here is a reader learning a mechanism that no longer exists while reading the
  file that changed it.

- **The file sizes headroom at 14 and now pins 11 on two rows.**
  `joharness.sh:1693` reads *"14 is sized from the regression it must catch,
  not from taste"*, and `joharness.sh:1227` and `:1460` both cite 14 as the
  figure a measurement was weighed against. `./joharness.sh perf` after the
  batch, counted in BOTH repos on 2026-09-12 and identical in each —
  session-start **276/287**, queue-context **104/117**, queue-orchestrated
  **104/117**, drain **287/308** — leaves headroom 11, 13, 13 and 21; and
  `JOHARNESS_CURATE_PLANS=1 ./joharness.sh perf drain` reads **297/308**, the
  worst case the batch's own comment predicts, which is 11. The batch's comment
  says *"every row keeps the headroom it already had"*, which is true against
  the old pairs and is a different claim from the one at `:1693`. **This is not
  a regression in safety**: the documented cheapest regression in kind is +25
  per ref and +20 per edge, and 11 catches both. It is a number the file states
  in three places and no longer pins, which is the shape ADR-0134-style
  folklore takes one step before anybody notices.

Dropped at the gate: **one**. A 133-character comment line at
`joharness.sh:1719`, in a paragraph wrapped at ~78 elsewhere. Established as
byte-identical between the two repos, so it is this repo's own wrapping
faithfully synced rather than sync corruption — and no gate in `./joharness.sh
ci` can see it, since shellcheck has no line-length rule. Dropped because it
carries no measurable cost to anybody: the sentence's content is correct, only
its wrapping is not. Recorded here so the next reader does not re-find it and
weigh it again.

Also not filed as a finding, because it is design rather than defect, and
noted only because it is the reason the first bullet's check had to be run by
hand: `d90317f` added `.agents/harness/selftest/handover-context-merged-filter.sh`
and registered it in `.agents/harness/selftest.sh`, and neither ships to a
consumer — `ci` there prints `harness selftest: not here (canonical-only)`. So
nothing in a consumer asserts the new filter, and a later local edit to either
hook goes unmeasured where it runs.

## Consequence for the queue

No plan changes; there is no plan on this. Three prose repairs, all in files
this repo owns, and one of them is a decision rather than an edit:

1. `.agents/harness/AGENTS.md:154` — point at `./joharness.sh finish`'s own
   output, which ships, rather than at `joharness.conf`, which may not carry
   the key at all. The sentence already says `finish` *"names what it cannot
   cover, in its own output"*, so the repair is a deletion.
2. `joharness.sh:1242` — say what the merged-ref path now costs.
3. `joharness.sh:1693` and its two citations — either restate the sized
   headroom as 11 with the regression figures that justify it, or raise the
   four budgets to keep 14. Whoever takes this decides which; the report does
   not.

`.agents/docs/consumer-repos.md`'s conf-comment rule may also want its premise
widened from *the copy the reader has is shorter* to *the reader may have no
copy*, which is the case that produced finding 1. That is the same decision as
1 and belongs with it.

## Verification

Two contexts, and they are split by repo rather than by person, which is worth
saying plainly rather than claiming more independence than there was.

- The consumer-side observations came from `.claude/agents/verifier.md` run at
  opus in `chrsctl/gx` against the sync diff, a reader that did not write it.
- The canonical-side grounding — every `sed`, `grep`, `git log` and `perf` run
  in THIS repo, listed under `## Method` — was done by the reporting session,
  which did not produce the consumer-side observations and did not take them on
  trust.

| claim | mark | what the second context read |
| --- | --- | --- |
| a consumer's conf has no `JOHARNESS_CHECKS` | GROUNDED | `grep -c` = 0 in the consumer; the key present at `joharness.conf:44-56` here |
| `38818b3`'s premise is *shorter seeded copy* | GROUNDED | the commit's own added text, read from `git log -p` |
| `:1242` describes a removed path | GROUNDED | the line, beside the batch's hunks in the same file |
| headroom is 11/13/13/21, and 11 at the drain worst case | GROUNDED | `perf` run in both repos, same numbers; the `CURATE_PLANS=1` run in the consumer |
| 11 still catches the regression in kind | GROUNDED | `:1694-1700`'s own +25/+26 per ref and +20 per edge |
| the dropped line is this repo's wrapping, not sync corruption | GROUNDED | byte comparison of the paragraph across the two repos |
| a runner counts one more than a laptop | WEAK | found only in the CONSUMER's `.github/workflows/ci.yml:642`, against the OLD pairs (runner 323/128/324, local 322/126/323). Carried onto the new budgets it would read 277/287 and 105/117 — still clear, but nobody has re-counted it since the batch, and no runner has run at all on that repo since 2026-09-07 |

The WEAK row is the one to re-measure before acting on finding 3: if a runner
really counts +1 on the three queue-context entrypoints, the headroom on
session-start is 10 and not 11.

## Graduates to

`.agents/harness/AGENTS.md`. The pointer is the only one of the three with a
consequence outside this repo — a consumer session reads step 7, opens
`joharness.conf`, and finds nothing — so the answer has to land where that
session reads. The two `joharness.sh` comment repairs ride with it rather than
graduating separately: they are the same class of defect, prose left unrevised
beside the code it describes, and splitting them would file two nodes for one
reading.
