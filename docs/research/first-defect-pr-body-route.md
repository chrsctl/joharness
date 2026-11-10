---
research: first-defect-pr-body-route
urgency: normal
agent: opus
effort: medium
graduates: .agents/docs/manager-reference.md
---

## Question

Does the `finding routes` gate accept `PR body` for a manager's FIRST out-of-item defect, which § Defect step 3 says must become an issue, and does it miss a defect recorded anywhere except a `## Review` line?

## Echo

§ Defect says only an unmatched SECOND or later defect may go in the pull request body. The gate behind it, as manager-reference.md and manager.md describe it, checks only that a `## Review` verdict cites `#<n>` or `PR body`. That check cannot tell an observation from a defect that reproduces, and it cannot tell a first defect from a second. The clerk plans from issues, not pull request bodies. So a defect that leaves through the pull request body is dropped from the queue unless a human files it.

## Sweep

goal-directed: one consumer edge (chrsctl/gx PR #1338) and the rule text it ran under, then canonical's rule text and lint source at `origin/main` `fbd9e1df`.

## What would settle it

- **Yes:** canonical's `lint_finding_routes` passes a `## Review` line whose verdict cites `PR body` for a finding that reproduces on `origin/main`, when no issue was filed in that session. It also passes a branch whose defect shows up only outside `## Review`.
- **No:** the lint, or another step of `finish`, refuses either case.

## Method

Run on chrsctl/gx, 2026-11-10:

```
git show 38d211034a0ac127a43b5c010ca29fd9ee6ae42f:docs/handover/commerce-shopify-channel.md
grep -n -E 'Defect|PR body|ONE issue|second' .agents/docs/manager-reference.md
grep -n -E 'PR body|finding routes' .claude/commands/manager.md
./joharness.sh upstream mgr/commerce-shopify-channel
pull_request_read get chrsctl/gx#1338 ; issue_read get chrsctl/gx#1341
```

Run on canonical's checkout (`origin/main` `fbd9e1df`):

```
grep -n -E 'PR body|ONE issue|second' .agents/docs/manager-reference.md .claude/commands/manager.md
grep -n -A40 'lint_finding_routes' joharness.sh
sed -n '/^fr_out_of_item() {/,/^}/p;/^fr_routed() {/,/^}/p' joharness.sh > fr.sh; source fr.sh
v='(wontfix: pre-existing, reproduces on origin/main, in PR body)'
fr_out_of_item "$v" && echo OUT; fr_routed "$v" && echo ROUTED      # → OUT, ROUTED
sed -n '/^fb_findings() {/,/^}/p' joharness.sh > fb.sh; source fb.sh
printf '## Decisions\n- unitless line 422s (wontfix: pre-existing)\n## Review\n- r1: x (fixed)\n' | fb_findings   # → r1: x (fixed)
grep -n -i -E 'issue_write|defect: ' joharness.sh
```

## Findings

- **The edge sent a reproducible defect out through the pull request body only.**
  - PR #1338 (merged as `9c7fdd4b`, 2026-11-09T23:21Z) lists it under "Findings outside this item, recorded here": "`draft_order_invoice` copies a line's null `unit` over Billing's `C62` default. Any manually typed order line without a unit fails its draft. Commerce-plugin's existing behaviour, not changed here." (`pull_request_read get`)
  - Nothing records a reproduction on `origin/main`, and no issue was filed. The body cites only #1337 (an `interface:` question) and #1322 (a storyboard red).
- **In the workstream file, the defect is a `## Decisions` bullet, not an `rN` line.**
  - Line 30 of the recovered file reads: "The parser carries `unit: \"C62\"` in `extra` … a unitless ingested line made every drafted invoice line 422 (measured: run step \"unit: is required and cannot be null\")."
  - `## Review` runs r1–r21. Only one line cites `PR body`, r20, and it is about criterion indexing, not this defect.
  - So the `finding routes` stage never saw this defect.
- **The harness reports nothing.** `./joharness.sh upstream mgr/commerce-shopify-channel` → `21 finding(s) landed on this repo's own files: not canonical's.` / `verdict : NOTHING TO REPORT`.
- **The defect was real and worse than the pull request body said. It reached the queue only because a human asked.**
  - Issue #1341 was created 2026-11-09T23:44Z, 23 minutes after the merge.
  - It reproduces on `origin/main` `a2e6274c1`: the `for_each` step failed with "422 invalid_value: unit: is required and cannot be null", and the invoice stayed committed with 0 lines.
  - The clerk then planned it in PR #1342. (`issue_read get #1341`)
- **Canonical's rule text is the same as the consumer's copy, at the same line numbers.** Not fixed, not reworded.
  - `.agents/docs/manager-reference.md:217`: "3. Otherwise ONE issue per session (`issue_write` `create`) on this" (consumer: `:217`, same).
  - `:225-227`: "4. A second defect in the same session: step 2 runs for EVERY defect. A / match = step 2's `Refs #M` line. Only an unmatched second or later defect / is pull request body only, one line each." (consumer: `:225-227`, same).
  - `:166-171` (§ Lead): "one that reproduces on `origin/main` is a defect, § Defect (an issue, `Refs #M`, or a PR body line for a second unmatched one); anything else (an observation, a declined design change) is one line in your pull request body. The `## Review` verdict cites where it went, `#<n>` or `PR body`. `ci` stage `finding routes` reds one that cites neither (`joharness.sh:lint_finding_routes`)" (consumer: `:166-170`, same text).
  - `.claude/commands/manager.md:166`: "body, and its `wontfix` cites `#<n>` or `PR body` (`ci` stage `finding routes`)." (consumer: `:166`, same).
- **Canonical's lint matches the docs: one grammar for every route, `## Review` only.**
  - `joharness.sh:1930-1936` `fr_routed`: routed = any `#<n>` / `/issues/<n>` (`:1933`), OR the words `pr|pull request` + `body|description` (`:1934`). Nothing reads whether the finding reproduces, or whether this branch filed any issue.
  - `joharness.sh:1938-1990` `lint_finding_routes`: for each `wontfix` line (`:1956`) that `fr_out_of_item` flags (`:1960`), `fr_routed` passing = `continue` (`:1961`). It reads lines from `fb_findings` only (`:1972`).
  - `joharness.sh:2266-2273` `fb_findings`: emits bullets between `## Review` and the next `## ` heading, nothing else. The workstream file's other sections and the pull request body are never read.
  - Its own failure text (`:1984-1988`) already names the difference ("a defect that reproduces is filed (§ Defect) and cited, anything else is one line in the pull request body") but the check it prints after cannot tell them apart.
  - `grep -n -i -E 'issue_write|defect: ' joharness.sh` finds only dispatch's park-on-defect timers (`:142-146`, `:6381`, `:7324-7351`, `:9899`): no `finish` step counts filed defect issues.

## Consequence for the queue

A proposal; canonical decides.

- `.agents/docs/manager-reference.md` § Lead and § Defect, and the `finding routes` lint: make a first defect that reproduces need an issue number. Two ways to do it:
  - split the verdict grammar into `defect #<n>` / `defect PR body` (allowed only after a `defect #<n>` in the same file) and `observation PR body`; or
  - have the lint require at least one `#<n>` before any defect `PR body`.
- State that a defect noticed outside `## Review` (in `## Decisions`, `## Rejected`, or the pull request body) escapes the gate. Then either route it into a `## Review` line, or have the lint scan the pull request body's out-of-item section.

## Verification

Read in canonical's checkout at `origin/main` `fbd9e1df`, a context that did not produce the consumer findings (it read the lint source; the consumer had read only the docs).

- **Case 1 — does the lint accept a `PR body` verdict for a first reproduced defect? YES.** GROUNDED. `fr_routed` (`joharness.sh:1934`) passes any verdict naming `PR body`; `lint_finding_routes` `continue`s on it (`:1961`). Run on `(wontfix: pre-existing, reproduces on origin/main, in PR body)`: `fr_out_of_item` → out of item, `fr_routed` → routed, so no red. No `finish` step counts filed issues (grep above).
- **Case 2 — does the lint ever look outside `## Review`? NO.** GROUNDED. Its only input is `fb_findings` (`:1972`), which reads `## Review` alone (`:2266-2273`). Run on a file with a `## Decisions` `wontfix` bullet: output held only the `## Review` line.
- Canonical's doc text equals the consumer's copy: GROUNDED (the two greps above, quoted in Findings).
- The consumer-edge findings (PR #1338, issue #1341, the recovered workstream file): WEAK here — quoted from the consumer's draft, not re-read from this context.

## Graduates to

`.agents/docs/manager-reference.md`: § Defect and § Lead own the route grammar and name the lint that enforces it.
