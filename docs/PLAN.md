# Agentic Feature Delivery — Plan (v3, autonomous delivery team)

## 1. Rewritten objective

> **Original (unclear):** "I want to create a set of skills/agents that help me deliver features effectively using best practices. Ive heard things such as having a primary coding agents, and individual agents responsible for grading/rating features can be good, but I want to learn more about what is the best practices for this, how to drive it and more. Lets first create the plan and then tell me, once I understand it lets create the resources in this repo. Rewrite this prompt first to make this clear"

> **Rewritten (v3, after user direction):**
> Design and build an **autonomous agentic delivery team** for this repo using OpenCode skills, agents, and commands, based on current best practices (primary coding agent + specialist evaluator/grader agents, generator–critic separation). It must take real work items — **RFEs (feature requests) and CVEs (security vulnerabilities)** — and drive them to completion **with minimal human-in-the-loop**: the team iterates through implement → grade → fix cycles on its own because iteration is cheap, and machine-checkable exit criteria decide when work is done. The team covers the full product lifecycle, not just code: **product management** (is this the right thing to build), **UX critique** (is it usable and well-designed), **engineering review** (is it correct and maintainable), **security analysis** (is it safe), **requirement verification** (did we build what was asked), and **demo production** (can others see it working). Humans appear once, at the end, to review the evidence bundle and merge.

---

## 2. Best practices this design is based on

| # | Principle | What it means here |
|---|-----------|-------------------|
| 1 | **Generator–critic separation** | The agent that writes code never grades it. Graders run in **fresh child sessions** with no context from the implementation. |
| 2 | **One agent, one responsibility** | Each specialist owns one lens (product, UX, security, code quality, requirements, demo). A generalist reviewer sees everything shallowly; specialists see their domain deeply. |
| 3 | **Ground truth over self-report** | Verification means receipts — test output, git state, executed commands — never an agent's claim about what it "did". |
| 4 | **Grader loop instead of human gates** | Quality is enforced by *autonomous fix–regrade cycles* against machine-checkable exit criteria, not by stopping to ask a human. |
| 5 | **Bounded autonomy** | The loop is capped (max fix–regrade cycles). If exit criteria still fail at the cap, the run stops and reports exactly what's stuck. |
| 6 | **Spec-driven development** | Every work item starts as a written spec with testable acceptance criteria — CVEs get a **reproducing test before the fix**. The spec is ground truth. |
| 7 | **Conditional panel routing** | Not every specialist reviews every item (a backend CVE doesn't need UX critique). The master workflow routes the right panel per item type, keeping cycles cheap. |
| 8 | **Least privilege via permissions** | Critics are read-only (deny `edit`) enforced by permissions; producers (demo recorder) can write only to their output area. |
| 9 | **Single human gate, with evidence** | Agents propose (branch + evidence bundle + demo); the human merges. |
| 10 | **Small batches + provenance** | Milestone-by-milestone commits; every run leaves a durable delivery report, auditable after the fact. |

---

## 3. Architecture

One autonomous orchestrating coder (the "builder"), surrounded by a **delivery team** of specialist critics and producers. You hand it work; it hands you a finished branch, evidence bundle, and demo.

```
                 YOU (once, at the end: review evidence, demo & merge)
                   ▲
                   │ branch/PR + evidence bundle + demo
   ┌───────────────┴───────────────────────────────────────────┐
   │   AUTONOMOUS LOOP  (primary builder agent + master skill) │
   │                                                           │
   │   intake ─► PM refines into spec ─► PM grades spec        │
   │      ▲                            │ fail → revise spec    │
   │      └────────────────────────────┘                       │
   │   implement milestone ─► run tests (receipts)             │
   │      ▼                                                    │
   │   SPECIALIST PANEL (fresh, parallel, routed by item type) │
   │   ┌─────────────────┬──────────────┬────────────────┐     │
   │   │ implementation- │ code-        │ security-      │     │
   │   │ grader (did we  │ reviewer     │ analyst (CVE   │     │
   │   │ build the ask?) │ (bugs/reg.)  │ lead)          │     │
   │   └─────────────────┴──────────────┴────────────────┘     │
   │   + ux-critic (user-facing items only, spec & impl)       │
   │      ▼                                                    │
   │   findings? ─► fix ─► re-grade  (max N cycles)            │
   │      ▼ exit criteria met                                  │
   │   demo-recorder produces demo artifacts                   │
   │   ─► write delivery report ─► hand off to you             │
   └───────────────────────────────────────────────────────────┘
```

### The delivery team

| Agent | Lens | When it runs | Outputs |
|-------|------|--------------|---------|
| **pm** | Product | Every item, twice: (1) intake — refines RFE/CVE into a spec with acceptance criteria, challenges scope and value; (2) grades the spec for completeness/testability | Refined spec; spec score + fixes |
| **ux-critic** | Usability | User-facing items only: critiques the spec (flows, error states, edge UX) then the implementation (walks the flows, checks copy, consistency, accessibility) | Severity-ordered UX findings |
| **implementation-grader** | Requirements | Every item: grades impl against spec, criterion-by-criterion PASS/FAIL with evidence; runs tests for ground truth | Coverage table + evidence |
| **code-reviewer** | Engineering | Every item: bugs, regressions, maintainability on the diff | Severity-ordered findings, file:line |
| **security-analyst** | Security | Every item (diff threat-model, CWE checks); **leads the CVE track** (triage, exploitability, fix completeness, bypass hunting) | Threat notes / CVE verdict |
| **demo-recorder** | Showcase | End of run, after exit criteria: produces demo artifacts — screenshots/GIFs or scripted walkthrough for UI, example transcripts/snippets for CLI/API | Demo artifacts in the evidence bundle |

### Panel routing (keeps cycles cheap)

- **RFE, user-facing**: pm → (spec: pm + ux-critic) → impl panel: implementation-grader + code-reviewer + security-analyst + ux-critic → demo-recorder
- **RFE, non-UI**: pm → (spec: pm) → impl panel: implementation-grader + code-reviewer + security-analyst → demo-recorder (example-based demo)
- **CVE**: pm (scope guard: minimal fix only) → security-analyst leads (triage, repro-first) → impl panel: security-analyst + implementation-grader + code-reviewer → evidence includes fail-before/pass-after receipts

### Two intake tracks (unchanged from v2)

- **`/rfe "add rate limiting to login"`** — spec → audit → implement → panel → fix loop → demo → evidence bundle
- **`/cve "CVE-2026-12345 in lodash"`** — triage → reproduce first → minimal fix → verify → panel → evidence bundle

### Exit criteria (machine-checkable, defined in the rubric)

- Every acceptance criterion: **PASS with evidence**
- Findings: **zero blockers** (any panel member), **zero majors** (from pm / implementation-grader / security-analyst; UX majors block on user-facing items)
- Full test suite: **green** (receipt)
- CVEs: repro test **fails before / passes after** (both receipts)
- Stop-and-report when: fix–regrade cycles hit the cap (default 3), or a blocker is unfixable within scope

### Evidence bundle — `deliveries/<work-item-slug>/`

- `spec.md` — ground truth
- `report.md` — what was asked, what changed and why, per-cycle grader scores, receipts, remaining minors/nits, rollback scope
- `demo/` — screenshots, GIFs, walkthrough, or example transcripts
- final grader reports from each panel member

---

## 4. Resources to create

### Agents — `.opencode/agents/` (6 subagents)

| File | Role | Key permissions |
|------|------|-----------------|
| `pm.md` | Product: intake refinement, spec authorship coaching, spec grading, scope/value challenge | read-only |
| `ux-critic.md` | Usability critique of spec + implementation for user-facing surfaces | read-only |
| `implementation-grader.md` | Criterion-by-criterion spec coverage with evidence; runs tests | deny edit; shell allowed |
| `code-reviewer.md` | Bugs, regressions, maintainability on the diff | read-only |
| `security-analyst.md` | Diff threat modeling, CWE checks; CVE track lead | read-only |
| `demo-recorder.md` | Demo artifacts: screenshots/GIFs (browser automation where available), walkthroughs, example transcripts | write limited to `deliveries/**` |

### Skills — `.opencode/skills/`

| Skill | Purpose |
|-------|---------|
| `agentic-delivery/` | **Master workflow**: both tracks, panel routing rules, the autonomous loop, delegation, receipts, exit criteria, cycle caps, evidence bundle format, escalation. |
| `spec-writing/` | RFE + CVE spec formats: goal, non-goals, testable acceptance criteria, milestones; CVE: triage notes, repro plan, minimal-fix scope. |
| `grading-rubric/` | Shared rubric: severity levels, evidence requirements, scoring, **machine-checkable exit criteria + thresholds**, per-role blocking rules. |

### Commands — `.opencode/commands/`

| Command | What it does |
|---------|--------------|
| `/rfe <description>` | Autonomous RFE track end-to-end → branch + evidence bundle + demo. |
| `/cve <advisory-or-description>` | Autonomous CVE track end-to-end → branch + evidence bundle. |
| `/grade [spec]` | On-demand panel run against current changes. |

### Documentation

| File | Purpose |
|------|---------|
| `README.md` | What this is, team overview, how to use `/rfe` `/cve` `/grade`, how to read the evidence bundle. |
| `docs/ARCHITECTURE.md` | Design rationale: principles → decisions, panel routing, exit criteria, how to add team members. |

---

## 5. What this intentionally does NOT include (yet)

- **No auto-merge** — single human gate stays; easy to flip later.
- **No parallel coders** — one builder; the panel already runs in parallel.
- **No CI wiring** — receipts are local; graders-in-CI is the next step.
- **No model pinning** — inherit session model; add per-agent `model:` when wanted.
- **No issue-tracker integration** — commands take descriptions; Jira/GitHub ingestion later.

---

## 6. Build order

1. `grading-rubric` skill (foundation: severities, evidence rules, exit criteria, cycle caps)
2. `spec-writing` skill (RFE + CVE formats)
3. Six team agents (pm, ux-critic, implementation-grader, code-reviewer, security-analyst, demo-recorder)
4. `agentic-delivery` master skill (loop + routing)
5. Three commands (`/rfe`, `/cve`, `/grade`)
6. `README.md` + `docs/ARCHITECTURE.md`
7. Dry-run both tracks on a tiny sample to verify the loop runs end-to-end

---

*Plan status: v3 — approved and built. All resources verified registered in OpenCode (agents, commands, skills). See README.md for usage.*
