---
plan: lineup-cache-read-pricing
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/docs/agent-selection.md, .claude/commands/manage.md, docs/product/scout-role.md, docs/research/cost-per-merge-levers.md
---

## Goal

Human asked (2026-10-09) to evaluate model usage against Simon Willison's
Haiku 5.5 post (simonwillison.net/2026/Oct/7/claude-haiku-5-5/), then to
fix what the evaluation found. Anthropic's pricing page, fetched
2026-10-09 (platform.claude.com/docs/en/about-claude/pricing.md), confirms
the post: Sonnet 5.5 cache reads halved to 0.10 $/MTok (0.05x input), Opus
5.5 stays 0.20, Haiku 5.5 is 0.01 at prompts ≤100K tokens and 0.05 above,
and the 100K line counts the WHOLE prompt including cache reads, priced
per request. The harness says context — cache reads — is the bill
(`.agents/docs/agent-selection.md` Cost levers), yet its Lineup carries no
cache-read price, and its haiku claim ("a twentieth below 100K, a quarter
above") compares INPUT prices. On cache reads haiku is a tenth of sonnet
below 100K and a half above. Sonnet and opus were at cache-read parity
until 2026-10-07; now sonnet is half. Correct the numbers where sessions
choose a tier, add the rule the 100K line implies for haiku workers, and
hand the research file its priced starting point. No tier changes — those
are money, humans only.

## Scope

- `.agents/docs/agent-selection.md`, section `## Lineup`:
  - Table gains a column `Cache read $/MTok` between `$/MTok in/out` and
    `Use for`. Values: haiku `0.01 (prompt ≤100K) / 0.05 above`; sonnet
    `0.10`; opus `0.20`; fable `0.25`.
  - The intro sentence naming the price source (lines starting
    "Developed in a consumer" at the top of the file) gains: cache-read
    column from Anthropic's pricing page fetched 2026-10-09, which
    supersedes the skill cache's sonnet cache-read 0.20.
  - Replace the paragraph starting "Price gap moved with the generation."
    up to and including "cannot land unchecked." with a paragraph that
    says, in caveman style (`.agents/docs/caveman.md`): on input price
    haiku is a twentieth of sonnet ≤100K, a quarter above; on cache reads
    — the bill — a tenth ≤100K, a half above. The 100K line counts the
    whole prompt, cache reads included, per request: a haiku session
    whose context grows past it pays 5x on every later turn. Sonnet cache
    reads halved 2026-10-07 (0.20 → 0.10); before that sonnet and opus
    cost the same per cached token, so for long sessions sonnet now costs
    half of opus on the dominant line. Keep the existing sentence that the
    manager re-runs the acceptance command before any commit.
  - Keep the "Opus 5.5 defaults to effort `medium`" sentence unchanged.
- `.agents/docs/agent-selection.md`, `## Selection rules`, the haiku
  bullet: append one sentence — a haiku unit is also SMALL: its whole
  session stays under 100K prompt tokens; a unit that cannot = sonnet.
- `.agents/docs/agent-selection.md`, `## Cost levers`, bullet "Context is
  the bill": after "(opus 5.5: 0.20 against 4 /MTok, claude-api skill
  cache 2026-10-06)" add "; sonnet 5.5 0.10 against 2, haiku 5.5 0.01
  against 0.10 ≤100K, pricing page 2026-10-09".
- `.claude/commands/manage.md`, section `## 2. Decompose, then fan out to
  workers`, the `tier:` bullet: append "A haiku sub-task stays small —
  past 100K prompt tokens haiku bills 5x (Lineup,
  `.agents/docs/agent-selection.md`); a sub-task that cannot = sonnet."
- `docs/product/scout-role.md`, the Evidence bullet starting "Prices,
  $/MTok in/out.": append one sentence — cache reads, pricing page
  2026-10-09: haiku 5.5 0.01 (≤100K) / 0.05, sonnet 5.5 0.10 (halved
  2026-10-07), opus 5.5 0.20, fable 5.1 0.25.
- `docs/research/cost-per-merge-levers.md`, `## Method`: add a bullet
  `Priced prior (arithmetic, not a trial):` with exactly these two items,
  each naming its source:
  - Lever 3: the run-3 orchestrator's counted usage (1.21B cache-read,
    1.74M output tokens, `docs/product/scout-role.md` Evidence) priced at
    5.5 rates — opus 242 + 34.8 = ~277 USD, sonnet 121 + 17.4 = ~138 USD.
    Cache reads plus output only; input and cache writes excluded. Sanity
    check: same usage at opus 5 rates (0.50 cache read, 25 out) = ~649
    against 710.70 billed.
  - Lever 4: per cached token haiku 5.5 is 0.1x sonnet 5.5 at ≤100K
    prompt and 0.5x above; the share of worker turns above 100K decides
    which ratio a fleet pays, so the trial counts it (`list_events`
    `usage` per worker turn).
  `## Findings` stays "None yet." — a price is not a trial result.

## Out of scope

- Changing any plan's, role's or spawn's tier or effort. Money, humans
  only (`.agents/docs/agent-selection.md` Selection rules).
- Changing the orchestrator tier in `.agents/docs/orchestrated.md`. The
  evaluation recommends it stays sonnet; that is a note for the human,
  not an edit.
- Editing `joharness.sh` (`lint_enum`, review depth) — tiers unchanged.
- Subscriber API credits (Max/Team, announced 2026-10-07). Under 2
  merged edges a month at ~128 USD per edge; not worth a line.
- Willison's effort spread (low 0.09¢ vs max 3.38¢, one prompt). n=1,
  informal; the Cost levers effort bullet already covers the mechanism.
- The tokenizer. Haiku 5.5 shares the 4.7+ tokenizer with sonnet and opus
  5.5 (pricing page, Tokens section); no tier comparison changes.
- Running any lever trial or writing `## Findings`.

## Acceptance

- `grep -c 'Cache read' .agents/docs/agent-selection.md` — `1` or more,
  and the Lineup table renders with 6 columns on every row:
  `sed -n '/^## Lineup/,/^## Selection/p' .agents/docs/agent-selection.md | grep '^|' | awk -F'|' '{print NF}' | sort -u`
  prints `8` only.
- `grep -n 'a twentieth' .agents/docs/agent-selection.md` — one hit, in
  the same paragraph as `a tenth`.
- `grep -n '100K' .claude/commands/manage.md` — one hit, in the `tier:`
  bullet.
- `grep -n '0.10 (halved' docs/product/scout-role.md` — one hit.
- `grep -n 'Priced prior' docs/research/cost-per-merge-levers.md` — one
  hit, under `## Method`; `grep -A1 '^## Findings' docs/research/cost-per-merge-levers.md`
  still shows `None yet.`
- `./joharness.sh ci` — `ci: pass` (glossary spellings, anchors, graph).
- Every price in the diff matches the pricing page re-fetched on the day
  of implementation. A changed price = update the number and the date,
  record it in the workstream file.
- Plan `ci` calls SHIPS: `ci`'s glossary and anchor lint run in every
  consumer; `.agents/docs/agent-selection.md` and `manage.md` reach
  consumers at their next sync.

## Where to look

- `.agents/docs/agent-selection.md:## Lineup` — table and the "Price gap"
  paragraph being replaced.
- `.agents/docs/agent-selection.md:## Cost levers` — "Context is the
  bill" bullet; the numbers style to match.
- `.claude/commands/manage.md:## 2. Decompose, then fan out to workers` —
  `tier:` bullet.
- `docs/product/scout-role.md:Evidence` — the "Prices, $/MTok in/out."
  bullet.
- `docs/research/cost-per-merge-levers.md:## Method` — levers 3 and 4.
- `.agents/docs/research/README.md:## Shape` — why a priced prior is
  Method, not Findings.

## Traps

- Measured number carries what produced it, same sentence — every price
  names the pricing page and its fetch date (Loop step 5).
- Never write a number nobody can re-count: the ~277 / ~138 / ~649 are
  arithmetic from counted usage; say "arithmetic", never "measured".
- `docs/plans/scout-command.md`'s pull request deletes
  `docs/product/scout-role.md`. Merging after it: drop the scout-role
  edit, do not recreate the file.
- Core paths (`joharness.conf`, `.claude/settings.json`, `.github`) are
  not touched by this plan; any diff there is out of bounds.
- Contested terms have one spelling (`.agents/docs/glossary.md`): "agent
  tier", not "model tier".
