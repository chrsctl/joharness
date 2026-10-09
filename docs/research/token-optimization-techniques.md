---
research: token-optimization-techniques
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/caveman.md
---

## Question

Which token-optimization techniques from outside this repo, starting at
wernerkasselman-au/llm-tips `token_optimization.md`, hold up against their
primary sources AND cut tokens this harness actually pays for?

## Echo

Human asked: research token optimization, example
`https://github.com/wernerkasselman-au/llm-tips/blob/main/token_optimization.md`.
Read as two filters, not one. First: does each claim survive its own source?
Second: does it touch this harness's bill? Harness already compresses its
instruction files (`.agents/docs/caveman.md`) and already measured where
money goes (`.agents/docs/agent-selection.md` Cost levers: context re-reads,
not output). Technique that passes filter one and fails filter two = true,
and not worth a rule here. Answer decides whether `caveman.md` gains rules,
and whether a plan gets filed.

## Sweep

`goal-directed` — every technique the named document lists, plus the
Anthropic-side mechanisms it names (caching, token counting, tool loading).
Not every compression paper there is.

## What would settle it

Per technique: GROUNDED (primary source says it), WEAK (secondary source
only, or source measures a different task), UNGROUNDED (source missing or
says otherwise). Then per surviving technique: names a token stream this
harness pays (instruction chain, session-start injection, tool schemas,
resumed context) AND is not already a rule here. Survives both = new rule
or plan. None survives = caveman.md gains only a "checked, here is why not"
paragraph.

## Method

Web reads, verbatim:

- WebFetch `https://raw.githubusercontent.com/wernerkasselman-au/llm-tips/main/token_optimization.md`
- WebSearch `Evaluating AGENTS.md context files coding agents ETH AGENTbench`
- WebFetch `https://arxiv.org/abs/2602.11988` (abstract numbers)
- WebSearch `LLM table format comprehension markdown-kv JSON CSV accuracy benchmark improvingagents`
- WebSearch `zip2zip inference-time adaptive tokenization hypertokens arxiv`
- WebSearch `LLMLingua prompt compression 20x benchmark`
- WebSearch `Compel compression ratio data quality OpenReview LLM lz4 0.65 0.80`

Anthropic facts: claude-api skill bundled with this Claude Code build,
`shared/prompt-caching.md` (API reference), `shared/token-counting.md`,
`shared/agent-design.md` (tool search), cache dated 2026-10-06.

Repo counts:

```bash
./joharness.sh context        # instruction chain + session-start bytes
grep -n "## Cost levers" -A40 .agents/docs/agent-selection.md
```

## Findings

Filter one — does the claim survive its source.

- **Context files: cost up, success flat.** Source doc does not cite this;
  harness already does. arXiv 2602.11988 abstract: context files "do not
  generally improve task success rates" and raise inference cost "by over
  20% on average"; useful for "non-standard coding practices". Abstract
  gives no success-rate numbers; secondary write-ups disagree (-0.5% vs
  -2% vs -3%). Source: WebFetch arxiv abstract; WebSearch ETH AGENTbench.
- **Filler/article removal (T1, T2), terse descriptions (T6).** Doc's
  64% / 38% / 78% are single hand-picked examples, no corpus, no
  comprehension test reported. Technique matches caveman.md Drop list,
  already a rule here. Source: WebFetch of the doc.
- **`customer_id` 2 tokens, `customerId` 3.** Tokenizer-specific. Doc
  names no tokenizer for this count; its Validation sample uses tiktoken
  `cl100k_base` (OpenAI). Unverified for Claude. Source: WebFetch of the doc.
- **Count with tiktoken.** Wrong for Claude. claude-api skill
  `shared/token-counting.md`: "Do not use `tiktoken`. It's OpenAI's
  tokenizer. It undercounts Claude" — use `POST /v1/messages/count_tokens`.
  Doc's tiktoken path gives OpenAI counts; it also offers a `claude -p`
  usage path and does not say which produced its figures.
- **Markdown beats JSON; MD-KV 61%, Markdown 55%, JSON 50%, CSV 44%.**
  Doc's table cites nothing. Nearest source (inference, not doc's
  citation): Improving Agents, improvingagents.com/blog/best-input-data-format-for-llms,
  2025-09-30 — GPT-4.1 nano, 1,000 records, 1,000 lookup questions: MD-KV
  60.7, XML 56.0, JSON 52.3, Markdown table 51.9, CSV 44.3. JSON beats
  Markdown there; doc's 55/50 match no source. Measures table retrieval on
  one OpenAI model, not instruction following. TQA-Bench: JSON worst; Sui
  et al. (WSDM 2024): HTML > XML > JSON > Markdown. Ranking is task- and
  model-dependent. Source: WebSearch improvingagents; verifier read the
  original post.
- **Compression ratio zone 0.65-0.80 (OpenReview "Compel", lz4).**
  Doc cites "OpenReview (2025): Compel". Not found; no result carries the
  thresholds. Nearest is Entropy Law (arXiv 2407.06645), no thresholds.
  Source: WebSearch Compel, plus verifier's queries on Compel/OpenReview,
  Goldilocks/0.65/gzip, compression ratio data quality.
- **Inline constraint notation (T4: `!` required, `?` optional).**
  Invented abbreviation class. caveman.md Tokenizer facts: invented
  abbreviations save zero, reader still decodes. No source given in doc.
- **Tool schemas cost 75-155 tokens each; consolidate tools (T5), filter
  allowed tools.** Doc attaches no source to 75-155; Tetrate / Scott
  Spence appear only in its reference list. Anthropic-side equivalent exists and is stronger: tool
  search with `defer_loading` loads only matched schemas, appended not
  swapped, so prefix cache survives (`shared/agent-design.md`;
  `defer_loading` in `shared/tool-use-concepts.md`). Claude
  Code already defers MCP and rarely used tools behind `ToolSearch` —
  this session's own start listed 80+ deferred tools by name only.
- **Caching: min cacheable 2,048 tokens (Anthropic), cached input 0.1x.**
  Stale. Current: 512 tokens on Opus 5.5, Sonnet 5.5, Haiku 5.5, Fable
  5.1; 4,096 on Opus 4.6/4.5 and Haiku 4.5; minimum not monotonic. Reads
  0.05x on Opus 5.5 ($0.20/MTok), 0.025x on Fable 5.1; writes 1.25x (5 min
  TTL) or 2x (1 h). Source: `shared/prompt-caching.md` API reference.
- **zip2zip 15-40%.** arXiv 2506.01084 v2 says 15-40% (v1 said 20-60%).
  Needs model uptraining (LZW hypertokens, 10 GPU-hours). Not usable
  against a hosted API. Source: WebSearch zip2zip.
- **LLMLingua (not in doc, nearest real compressor).** Up to 20x with
  ~1.5-point loss on GSM8K/BBH, GPT-3.5 target, LLaMA-7B compressor.
  Drops tokens by perplexity — conflicts with caveman.md "never drop
  meaning" for instruction text; fits retrieved context only. Source:
  WebSearch LLMLingua.
- **ROI example: 17,300 to 10,588 tokens saves $0.0045 per read.** Doc's
  own arithmetic shows prose compression is cents.

Filter two — does it touch this harness's bill.

- **Instruction chain is small and already counted.** `./joharness.sh
  context` (this branch, 2026-10-09): 17,776 bytes / 2,490 words
  instructions + 1,502 bytes session-start = 19,278 bytes. Session-start
  row is a fleet snapshot: verifier re-ran same day, 1,798 bytes. Already
  reported per branch delta; caveman.md "What it costs, counted".
- **Bill is context re-reads.** agent-selection.md Cost levers, measured
  2026-10-07: one orchestrator 1.21B cache-read tokens against 1.74M
  output; manager at 712K context cost 46.76 USD, one at 126K cost 0.88
  USD. A 19 KB instruction load (~4,800 tokens at bytes/4, estimate not
  count) is re-read every turn too, but it is ~3.8% of a 126K context and
  ~0.7% of 712K. Context growth inside a session dominates prose size by
  one to two orders of magnitude at the large-context end.
- **Levers that hit the real stream are already named.** Fresh session
  past cache TTL, subagent sweeps that return conclusions, cache-warm
  health cadence (Cost levers); fresh-session lever is under measurement
  in `docs/research/cost-per-merge-levers.md`. Context editing
  (`clear_tool_uses`) and server compaction are API features the harness
  does not control — Claude Code runs the loop.

## Consequence for the queue

No new plan. No technique passes both filters as a NEW rule: the ones that
survive their sources are already rules (caveman Drop list, tokenizer
facts, `context` counter, Cost levers); the ones that would be new either
fail their sources (0.65-0.80 zone, format table, 2,048 cache minimum),
contradict Anthropic's own guidance (tiktoken counting), or need what a hosted-API harness lacks (zip2zip uptraining, LLMLingua
meaning loss). The one correction worth carrying is negative: caveman.md
should say why the doc's format and count claims are not adopted, so the
next session handed the same link does not re-open it.

Biggest token lever stays context size per session, already the subject of
`cost-per-merge-levers`. Nothing here unblocks or reorders it.

## Verification

Second context: general-purpose subagent with web access (not the
`.claude/agents/verifier.md` reader, which has no web tools and could only
check internal consistency). It re-read every web source, the claude-api
skill files, and re-ran `./joharness.sh context`; it edited nothing.

- Context files, arXiv 2602.11988 quotes: GROUNDED (read abstract).
  Secondary -0.5/-2/-3% not re-checked: WEAK.
- T1/T2/T6 percentages as quoted: GROUNDED (raw doc).
- `customer_id` count: WEAK — doc names no tokenizer; corrected above.
- Do not count with tiktoken: GROUNDED (`shared/token-counting.md` l.7).
- Format table: original UNGROUNDED as written — wrong model (mini, not
  nano) and wrong numbers; corrected above from original post.
- Compel 0.65-0.80 not found: GROUNDED across four queries.
- T4 notation unsourced: GROUNDED; "saves zero" rests on caveman.md, a repo
  rule, not an outside source.
- Tool schema 75-155: WEAK — unsourced in doc; corrected above.
- Caching minimums and multipliers: GROUNDED (`shared/prompt-caching.md`
  l.135-144).
- zip2zip 15-40% v2, 20-60% v1, 10 GPU-hours: GROUNDED (arXiv 2506.01084).
- LLMLingua 20x / 1.5 points: GROUNDED (arXiv 2310.05736, MSR blog).
- ROI $0.0045: GROUNDED (6,712 x $0.67/MTok = $0.004497).
- `context` numbers: GROUNDED, session-start drifted; noted above.
- Cost levers numbers: GROUNDED (agent-selection.md l.185-188).
- 2.5% / 0.4%: UNGROUNDED — arithmetic wrong; corrected to 3.8% / 0.7%.

## Graduates to

`.agents/docs/caveman.md` — it holds the tokenizer facts and the counted
cost; a short "Outside techniques, checked" section there is where a
session reading why caveman looks the way it does will find why these were
not adopted. No rule line in AGENTS.md: nothing here changes what a session
does.
