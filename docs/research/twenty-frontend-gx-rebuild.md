# Research: Rebuilding the Twenty frontend for GX

**Ask (Chris, 2026-08-27):** Research; rebuild the Twenty frontend but with focus
for GX. Use existing CSS frameworks. UI should be similar to Linear. Focus on
agent runs, workflows etc.

**Date:** 2026-08-27. Twenty findings reflect v2.38.0 (released same day; Twenty
ships near-daily). Design-process guidance follows Anthropic's
[frontend-design skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md).

---

## TL;DR — Recommendation

**Do not fork `twenty-front`. Build GX as a new, thin, purpose-built frontend
against Twenty's backend APIs**, using **Vite + React + Tailwind v4 +
shadcn/ui** (Base UI primitives) restyled with Linear's measured design tokens,
**React Flow UI** for the workflow canvas, **assistant-ui + Vercel AI SDK** for
agent chat, and **TanStack Table + Virtual** for dense Linear-style list views.

Reasons, each expanded below:

1. **`twenty-front` is ~590k LOC of custom, metadata-driven machinery** (custom
   table/kanban/field engine, bespoke Jotai wrapper, Linaria CSS-in-JS,
   Apollo cache hand-maintenance). A "focused" fork means carrying the 90k-LOC
   `object-record` engine and 36 bespoke state utilities for surfaces GX
   doesn't need. It also rots fast: Twenty releases near-daily and just
   completed two sweeping migrations (Recoil→Jotai, Emotion→Linaria).
2. **Licensing pushes the same direction.** `twenty-front` is AGPL-3.0 with 52
   commercial-only files. But Twenty's own "Application Exception" (AGPL §7
   additional permission) explicitly blesses **proprietary apps that talk to
   Twenty only through its APIs, webhooks, and SDKs**. A clean-room GX
   frontend on the API is the legally clean, upstream-sanctioned path.
   `twenty-ui` and `twenty-shared` are MIT if we ever want to lift small
   pieces (types, path enums, icons).
3. **The focus areas are the smallest part of Twenty's frontend.** Workflows +
   AI together are ~47k LOC of their 590k — and the agent-runs surface is the
   weakest part of Twenty's own UI (runs shown as settings-tab "turns/logs",
   not first-class). GX rebuilding *just* agents + workflow surfaces on
   off-the-shelf components is dramatically less work than forking, and can
   leapfrog Twenty's own UX where it matters to GX.
4. **Linear-like is a solved styling problem in 2026.** Measured Linear design
   tokens exist in shadcn-ready form; React Flow ships shadcn-styled workflow
   canvas components through the same CLI; assistant-ui gives streaming
   agent-chat primitives on shadcn. No custom design system needed.

---

## 1. What Twenty's frontend actually is (and why not to fork it)

Findings from `twentyhq/twenty` at v2.38.0 (HEAD `80631cc`, 2026-08-27).

### Stack

| Concern | Twenty's choice |
|---|---|
| Framework | React 19.2, functional components only, ESM |
| State | Jotai 2.17 wrapped in a Recoil-shaped custom layer (`createAtomState`, "component state" scoping, ~36 bespoke utilities; 614 files import jotai) |
| Styling | Linaria (zero-runtime CSS-in-JS) + static CSS variables from `twenty-ui/theme-constants` — Emotion is gone as of v1.19.0 (Mar 2026) |
| Components | `twenty-ui`, in-repo custom kit (~25k LOC, MIT) |
| Routing | react-router 6; almost all pages ride two generic metadata routes (`/objects/:objectNamePlural`, `/object/:objectNameSingular/:objectRecordId`) |
| Data | Apollo Client 4 over two GraphQL schemas (core + metadata), GraphQL Codegen, `graphql-sse` for realtime, Vercel AI SDK message types for AI streaming |
| Build | Nx 22 + Vite + SWC + wyw-in-js (Linaria), oxlint, Storybook 10, Playwright |
| Notable deps | `@xyflow/react` (React Flow) + dagre for workflow canvas, BlockNote, TipTap, Monaco, Nivo charts, dnd-kit, react-grid-layout, Lingui, framer-motion |

### Size and shape

- **~9,150 files / ~517k code LOC** in `twenty-front` alone; ~588k across the
  frontend packages. 57 feature modules.
- The center of gravity is `object-record` (**~90k LOC**): a fully custom
  virtualized record table, kanban, calendar, per-`FieldMetadataType`
  display/input resolvers, filter/sort/group engine, and a hand-maintained
  Apollo cache layer — all required because the schema differs per workspace.
- `workflow` is ~32k LOC / 629 files; `ai` is ~15k LOC / 390 files. **The two
  modules GX cares about are <8% of the frontend.**

### Why a fork is the wrong move

- **Everything is custom and interlocked.** Components assume the metadata
  store, context-store, and component-state providers around them. You cannot
  lift the workflow builder without the record engine underneath it.
- **Idiosyncratic conventions with real carrying cost.** Twenty's own
  contributor docs spend most of their length on re-render management rules
  ("sidecar effect components", one `useEffect` at root, no useRef for state)
  — evidence the atom architecture needs constant discipline. Agent chat alone
  has 15+ effect components.
- **Churn.** Near-daily releases; two 1000+-file migrations landed in one
  release (v1.19.0); another architectural migration is in flight right now
  (workflows moving to "core" tables behind
  `IS_WORKFLOW_CORE_INDEX_PAGE_ENABLED`). A fork starts diverging on day one
  and the merge cost compounds.
- **Licensing.** `twenty-front/src` is AGPL-3.0; 52 files are marked
  `@license Enterprise` (commercial-only — SSO/SAML, custom domains,
  billing). Forking pulls GX into AGPL §13 network copyleft; using their APIs
  does not (see §2).

### What Twenty's UI already does for workflows and agents (the bar to clear)

- **Workflows — mature.** React Flow canvas with dagre auto-layout
  (editable + readonly variants), step config in a side panel, three trigger
  families (record events, manual, cron, webhook), **13 action types**
  (ai-agent, code w/ Monaco, logic-function, HTTP, form/human-in-the-loop,
  filter, if-else, iterator, delay, find-records, pick-record, record CRUD,
  email), TipTap-based variable/expression editor, first-class **versions**
  (draft → activate lifecycle), and **run replay**: the executed diagram with
  per-step status and per-step input / output / logs tabs, updating live over
  SSE.
- **Agents — younger, and the gap.** Two chat surfaces (full page
  `/chat/:threadId?` and side-panel "Ask AI") with streaming over GraphQL SSE,
  tool-call rendering, thinking steps, attachments, context-compaction
  indicator. Agent admin lives in Settings (tabs: Settings, Role, Tools,
  Skills, Evals, Logs) with per-turn inspection at
  `/settings/ai/agents/:agentId/turns/:turnId`. **Agent runs get a
  settings-tab treatment — logs and turns — not the rich diagram/timeline
  treatment workflow runs get.** That is precisely where a GX frontend can be
  meaningfully better, not just restyled.

## 2. Consuming Twenty's backend from a new frontend

*(Pending — backend/API research agent still running; this section is filled in
from its report: workflow/agent data model, GraphQL core + metadata APIs, REST,
webhooks, SSE subscriptions, auth, headless feasibility.)*

## 3. The UI stack: existing frameworks that get to "Linear" fastest

### What "Linear-like" concretely means (measured from production linear.app)

- **Type:** Inter Variable, ~13px base UI size, weights 450–600 with Linear's
  signature 510; `font-feature-settings: "cv01","ss03"`; Inter Display for
  headings; negative tracking above 16px only; 13px mono for IDs.
- **Color:** dark-first, LCH-based, almost achromatic. Surface ladder
  `#08090a → #0f1011 → #141516 → #18191a`; ink `#f7f8f8`, muted `#8a8f98`;
  **one accent** `#5e6ad2`; color otherwise reserved for status/priority.
- **Depth:** hairline borders (`#23252a`/`#34343a`, 0.5–1px) instead of
  shadows; surface ladder carries elevation.
- **Density/shape:** strict 4px grid; radii 4/6/12px; single-line list rows
  ~36–40px; sidebar ~220–240px, never remounts.
- **Interaction:** Cmd+K palette, single-letter and G-prefixed chords,
  shortcuts shown in every tooltip, `Space` peek panels, hover-revealed
  actions, skeletons instead of spinners, <100ms view transitions.
- **The half no CSS framework supplies:** Linear's feel is ~50% performance
  engineering — local-first data, optimistic updates, instant transitions.
  Budget for it in the data layer, not the component layer.

Paste-ready token sources: [shadcn.io/design/linear](https://www.shadcn.io/design/linear)
(shadcn/Tailwind scalars), [VoltAgent DESIGN.md](https://github.com/voltagent/awesome-design-md/blob/main/design-md/linear.app/DESIGN.md),
[Fudge measured tokens](https://design.withfudge.com/tokens/linear.app),
[Linear's own redesign write-ups](https://linear.app/now/how-we-redesigned-the-linear-ui).
Caution: don't copy marketing-site tokens (16px body, display faces) into the
app shell — the app is Inter 13px on a 4px grid.

### Recommended stack (the 2026 consensus for exactly this kind of app)

| Layer | Pick | Why |
|---|---|---|
| App framework | **Vite + React 19** (or Next.js if SSR/marketing pages share the repo) | Twenty's API is a separate backend; GX frontend is a pure SPA — Vite keeps it simple |
| Styling | **Tailwind v4 + CSS variables** | Token-driven restyling to Linear values in one place |
| Components | **shadcn/ui** (Base UI primitives — shadcn's default since Jul 2026, after Radix maintenance slowed post-WorkOS) | Code is copied into the repo → full pixel control; largest ecosystem; best AI-tooling fluency; ships Sidebar, Command (cmdk), Data Table (TanStack), Charts, Kbd, Spinner |
| Command palette | **cmdk** via shadcn Command | The Cmd+K surface is table stakes for Linear-feel |
| Lists/tables | **TanStack Table v8 (headless) + TanStack Virtual** | shadcn's data-table pattern is already TanStack; virtualization proven at 100k+ rows |
| Workflow canvas | **React Flow (@xyflow/react) + React Flow UI** | Same engine Twenty uses; React Flow UI distributes shadcn-styled nodes/edges/controls **through the shadcn CLI**, plus official Workflow Editor and AI Workflow Editor templates |
| Agent chat | **assistant-ui + Vercel AI SDK** (`useChat`) | assistant-ui is headless chat primitives built on shadcn/Tailwind (auto-scroll, streaming states, tool-call rendering, retries); Twenty's backend already streams Vercel AI SDK UI-message parts (see §2) — a direct fit |
| Run logs | **@melloware/react-logviewer** (ANSI, lazy-loads 100MB+, WebSocket/static); study **Langfuse** (MIT) for trace-waterfall UI | No dominant off-the-shelf "agent run timeline" exists; Langfuse is the best open reference to crib from |
| Charts (usage/analytics) | **shadcn charts** (Recharts) — Tremor blocks (now free) for prebuilt KPI sections | Matches shadcn aesthetics |
| Icons / font | **Lucide** + **Inter Variable** (+ Inter Display headings) | shadcn default; renders very Linear at 13–16px |
| Polish | **sonner** (toasts), **vaul** (drawers), Motion sparingly (~100–150ms) | Both by an ex-Linear designer; ship in shadcn |
| Theme tooling | **tweakcn** visual theme editor | Fine-tune the Linear palette on live shadcn components |

### Alternatives considered (and why not)

- **Mantine** (+ Spotlight): fastest to a working dense app, but its own
  styling system fights pixel-level Linear matching, and Tailwind-based pieces
  (React Flow UI, assistant-ui) integrate awkwardly. Pick only if speed beats
  fidelity.
- **Raw Base UI / React Aria + own token layer:** maximum fidelity, but
  rebuilds everything shadcn gives free. Only if the design system is the
  product.
- **Ark UI / Park UI (Panda):** for multi-framework teams; smaller ecosystem,
  no React Flow UI / assistant-ui equivalents.
- **daisyUI:** wrong aesthetic (themed/rounded), no keyboard/overlay behavior.
- **Reusing `twenty-ui` (MIT):** possible, but it drags in the Linaria/wyw
  build step and Twenty's own look — conflicts with the Linear direction.
  Lift ideas (json-visualizer) rather than the package.

Worth studying, not adopting: open-source Linear clones
([tuan3w/linearapp_clone](https://github.com/tuan3w/linearapp_clone),
[TheBoyWhoLivedd/linear-clone](https://github.com/TheBoyWhoLivedd/linear-clone) —
Next + shadcn), **Huly** (production-grade Linear-style tracker, but Svelte +
custom kit — patterns only), and the
[Nicelydone Linear screenshot gallery](https://nicelydone.club/apps/linear)
(539 app screens).

## 4. Design process for GX (per the frontend-design skill)

The skill's rule: where the brief pins a direction, follow it exactly — and
this brief pins "similar to Linear." So the token system is *derived from
Linear's measured values* (§3), and the skill governs execution: ground in the
subject, pick one signature element, critique against defaults, write copy from
the user's side.

**Ground it in the subject.** GX's subject is *agents doing work*: runs,
workflows, tools, outcomes over CRM records. The audience is an operator
watching and steering automated work. The primary job of the app: *answer "what
are my agents doing right now, what did they do, and did it work?" in one
glance, then let me intervene.* Every layout decision serves that.

**Proposed token plan (first pass, to be critiqued before build):**

- **Color (dark-first):** canvas `#08090a`; surfaces `#0f1011 / #141516 /
  #18191a`; hairlines `#23252a / #34343a`; ink `#f7f8f8`, secondary `#8a8f98`,
  tertiary `#62666d`; accent `#5e6ad2` (hover `#828fff`). Status is the only
  other color in the app: running (accent, animated), succeeded (muted green),
  failed (red), waiting/paused (amber), skipped (gray) — status dots and step
  nodes only, never washes.
- **Type:** Inter Variable 13px base, weight 510 for emphasis, 590 semibold;
  Inter Display for the few real headings; 13px mono (e.g. JetBrains Mono or
  Geist Mono) for run IDs, payloads, logs. `"cv01","ss03"` globally.
- **Layout:** fixed 230px sidebar (Agents / Runs / Workflows / Threads /
  Settings) that never remounts; content area = dense virtualized list views
  with saved filters; `Space`/click opens a **peek panel** for a run without
  losing list position; Cmd+K everywhere; every action has a shortcut shown in
  its tooltip.
- **Signature element (the one place to spend boldness):** the **run
  timeline** — a live, Langfuse-style waterfall fused with the workflow
  diagram: each step a hairline-bordered row with duration bar, streaming
  tool-calls unfolding in place, statuses propagating live over SSE onto both
  the timeline and the mini-canvas. This is the thing GX will be remembered
  by, and it is exactly the surface Twenty under-serves (settings-tab logs).
  Everything else stays quiet and disciplined.
- **Skill's calibration warning applied:** "near-black + single accent" is a
  known AI-default look — the brief pins it anyway (Linear). Differentiation
  must come from the signature element and density discipline, not from the
  palette. Do not add a second accent, gradients, or decorative numbering.

**Writing rules for GX copy (from the skill, applied):** name things by what
operators control — "Runs", "Steps", "Approvals", not "executions of workflow
version entities". Active voice on controls ("Retry step", "Cancel run",
"Approve"); the same verb survives the flow (button "Retry" → toast
"Retried"). Errors say what failed and what to do next ("Step 3 failed:
HTTP 429 from HubSpot. Retry now or edit the rate limit."). Empty states are
invitations ("No runs yet. Trigger a workflow or ask an agent to start one.").
Quality floor without announcing it: keyboard focus visible, reduced motion
respected, responsive to laptop widths (this is an operator tool; phone is
read-only at best).

**Process:** brainstorm token plan (above) → critique vs. generic defaults →
build → screenshot-critique again. Two passes minimum before shipping any
surface.

## 5. Proposed GX surfaces (focused scope)

Priority-ordered; each maps to backend capabilities in §2.

1. **Runs** (the signature): global runs list (virtualized, filter by agent /
   workflow / status / time) → run detail = timeline + mini-canvas + per-step
   input/output/logs, live over SSE. Covers workflow runs *and* agent turns in
   one model — the unification Twenty itself lacks.
2. **Agents:** roster with live status and last-run health; agent detail =
   config (model, tools, skills, role) + its runs + its threads; chat with
   streaming (assistant-ui), tool-call and thinking rendering, human-approval
   moments surfaced as first-class cards.
3. **Workflows:** list with version/active state; builder on React Flow UI
   (start read-only + light editing: reorder, retitle, toggle, edit step
   configs; full drag-drop authoring later); versions with draft→activate.
4. **Command layer:** Cmd+K (jump to agent/run/workflow, trigger run, create),
   G-chords, `Space` peek.
5. **Settings (thin):** connection to Twenty backend, API keys, models,
   notification rules. Twenty's own app remains the admin fallback for
   everything else (CRM data model, records, marketing surfaces) — GX does not
   rebuild the CRM.

## 6. Risks and open questions

- **API stability:** Twenty ships daily; GX must pin API versions where
  possible and integration-test against upgrades. (§2 details what's public
  API vs. internal.)
- **Realtime:** Twenty's realtime is SSE (`graphql-sse`), not WebSocket;
  community has asked for WS (#14671). GX's live-run UX depends on what SSE
  exposes headlessly — verify early with a spike.
- **Workflow authoring depth:** full builder parity (variables/expression
  editor, 13 action configs, iterators) is the most expensive surface;
  recommendation is read/run/inspect first, author later.
- **Performance budget:** Linear-feel demands optimistic updates and instant
  navigation; plan the data layer (normalized cache or local-first store) as
  deliberately as the components.
- **"GX" definition:** not defined in this repo; assumed to be the product
  name for this agent-operations frontend. If GX implies a broader scope
  (e.g. full CRM replacement), §1's fork-vs-rebuild math changes — flag
  before build.

## Sources

Twenty: repo clone at v2.38.0 (`80631cc`, 2026-08-27) — `packages/twenty-front`,
`twenty-ui`, `twenty-shared`, `LICENSE`;
[v1.19.0 release notes](https://github.com/twentyhq/twenty/releases/tag/v1.19.0)
(Jotai + Linaria migrations);
[frontend contributor docs](https://github.com/twentyhq/twenty/tree/main/packages/twenty-docs/developers/contribute/capabilities/frontend-development);
[WS issue #14671](https://github.com/twentyhq/twenty/issues/14671);
[HN Jun 2024](https://news.ycombinator.com/item?id=40648082),
[HN Feb 2026](https://news.ycombinator.com/item?id=46922213).

Linear/UI: [Linear redesign write-up](https://linear.app/now/how-we-redesigned-the-linear-ui);
[shadcn.io/design/linear](https://www.shadcn.io/design/linear);
[VoltAgent Linear DESIGN.md](https://github.com/voltagent/awesome-design-md/blob/main/design-md/linear.app/DESIGN.md);
[Fudge tokens](https://design.withfudge.com/tokens/linear.app);
[925studios breakdown](https://www.925studios.co/blog/linear-design-breakdown-saas-ui-2026);
[shadcn changelog](https://ui.shadcn.com/docs/changelog);
[Radix vs Base UI](https://www.shadcndeck.com/blog/radix-vs-base-ui);
[React Flow UI](https://reactflow.dev/ui) +
[AI Workflow Editor template](https://reactflow.dev/ui/templates/ai-workflow-editor);
[assistant-ui](https://www.assistant-ui.com/docs/integrations/frameworks/ai-sdk);
[TanStack virtualized rows](https://tanstack.com/table/v8/docs/framework/react/examples/virtualized-rows);
[Langfuse](https://github.com/langfuse/langfuse);
[react-logviewer](https://www.npmjs.com/package/@melloware/react-logviewer);
[tweakcn](https://tweakcn.com/); [Huly](https://github.com/hcengineering/huly-selfhost);
[Nicelydone Linear gallery](https://nicelydone.club/apps/linear).

Design process: [Anthropic frontend-design skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md).
