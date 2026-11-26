---
research: refuted-absence-needs-the-finding-command
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/manager.md
---

## Question

Does `manager.md` §2's `A<n>: refuted — <evidence>` accept a claim that
something is absent when no command that would find it was run, and is that
enough to block on a human?

## Echo

A manager that refutes an assumption by asserting an absence ("nothing holds
X") can turn a false negative into a human question. The gate takes the
words "evidence" and "refuted" at face value. If prose such as code comments
counts as evidence of absence, a grep the manager never ran can park an item
and cost a human's attention.

## Sweep

`goal-directed`: one consumer incident, plus the consumer's own rule for
the same failure.

## What would settle it

Yes: a refutation stating an absence, recorded without the finding command,
that the command then contradicts on the same base. No: the gate already
requires the command for an absence.

## Method

On the consumer (chrsctl/gx). Manager `go-settings-counts`, claim and block
commit 9dc4b9f98, base aa2baa063:

```
$ git show 9dc4b9f98:docs/handover/go-settings-counts.md | grep "A1:"
- A1: refuted — `installed_count` is `offered(adopted_bundles) ∩ live_plugins`, … Nothing under `platform/appform-go/internal` holds a catalogue: `door/records.go` and `records/records.go` defer to Python for exactly that reason, and `plugins` (list_plugins) is not ported. …
$ git grep -n "func (c \*Catalogue) Offered" aa2baa063 -- platform/appform-go/internal
aa2baa063:platform/appform-go/internal/plugins/plugins.go:269:func (c *Catalogue) Offered(bundles []string) []Offered {
$ git grep -n "plugins.Deployed()" aa2baa063 -- platform/appform-go/internal/door
aa2baa063:platform/appform-go/internal/door/sequences.go:30:	cat, err := plugins.Deployed()
$ git grep -n "alone knows the plugin catalogue" aa2baa063 -- platform/appform-go/internal/door
aa2baa063:platform/appform-go/internal/door/records.go:18:// deferred to Python, which alone knows the plugin catalogue behind
aa2baa063:platform/appform-go/internal/door/review_facts.go:22:// does not hold: Python alone knows the plugin catalogue behind
aa2baa063:platform/appform-go/internal/door/review_routes.go:69:// hold: Python alone knows the plugin catalogue behind `not_installed`.
```

## Findings

- **The absence was false on the manager's own base.** The catalogue and `Offered` exist (`plugins.go:269`), and the door already loads it (`sequences.go:30`). The catalogue was ported earlier the same day (consumer PR #2197).
- **The "evidence" was comments that had gone stale.** Three door comments still say "Python alone knows the plugin catalogue". The refutation repeats that reading ("`door/records.go` … defer to Python for exactly that reason") and names no command.
- **It became a human question.** The block was `next: "interface: A1 refuted — Go has no plugin catalogue … Port the catalogue first (new plan), or accept the route stays deferred whole?"`. Both options rest on the false absence.
- **The consumer already carries this rule for libraries.** chrsctl/gx `AGENTS.md` Part 2 § Prohibitions: "Don't record a library's absence without running the command that would find it" (gx ADR 0112). Canonical has no general form of it:

  ```
  $ grep -rn -i -E "absence|refut" AGENTS.md .agents/harness/AGENTS.md .agents/docs/*.md .claude/commands/*.md
  ```

  This finds the refuted-assumption bookkeeping (`manager.md:54`, `manager-reference.md:291`, `plans.md:27`, `research.md:78`) and nothing that requires a finding command for an absence.

## Consequence for the queue

`.claude/commands/manager.md` §2: an `A<n>: refuted` that claims something
does not exist carries the command that would find it and that command's
empty output, on the branch's base. A block that rests on such a refutation
quotes that command in its question. The verifier or plan-checker could also
red an absence claim that has no command under it.

## Verification

Not verified from a second context yet; the commands above are reproducible
on chrsctl/gx.

## Graduates to

`.claude/commands/manager.md`: §2 is where an assumption is recorded as confirmed or refuted.
