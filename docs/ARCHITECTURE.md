# Architecture

Design rationale for the agentic-delivery system. The plan that produced it
is [PLAN.md](PLAN.md) (v3). This document maps principles → decisions, so
future changes stay coherent.

## Principles → decisions

| Principle | Decision in this repo |
|-----------|----------------------|
| Generator–critic separation | The builder writes all code; graders are separate subagents. Subagent mode gives each grader a fresh child session with no builder context, so graders can't be anchored by the implementation narrative. |
| One agent, one responsibility | Six focused roles (pm, ux-critic, implementation-grader, code-reviewer, security-analyst, demo-recorder) instead of one generalist reviewer. Findings attach to a lens, so triage is unambiguous. |
| Ground truth over self-report | Receipts (command output, test runs) are required for every PASS and captured in the evidence bundle. The implementation-grader must run tests itself; "the builder says it works" is never evidence. |
| Grader loop instead of human gates | The builder iterates fix → re-grade autonomously. "Done" is decided by machine-checkable exit criteria in the rubric, not by a human checkpoint. |
| Bounded autonomy | Cycle cap (3). On cap, the run stops and escalates with exactly what's stuck. Prevents unbounded compute burn and forced "passes". |
| Spec-driven development | Every run starts from `deliveries/<slug>/spec.md` with testable acceptance criteria. The spec is the ground truth every grader grades against. CVEs additionally require a failing repro test before any fix. |
| Conditional panel routing | Not every critic runs on every item (ux-critic only on user-facing work). Keeps cycles cheap without weakening coverage where it matters. |
| Least privilege | Critics deny `edit` (and `shell`, except implementation-grader which runs tests, and demo-recorder which needs to start apps). Demo-recorder's `edit` is allow-listed to `deliveries/**`. |
| Single human gate | One decision remains human: merging. The evidence bundle is designed to answer a reviewer's questions: what was asked, what changed, what was verified, how to roll back. |
| Provenance | Per-run `deliveries/<slug>/` directory with spec, report, receipts, grader reports, demo — auditable after the fact. |

## Control flow

```
/rfe | /cve                     (commands — thin entry points)
   └─► builder loads agentic-delivery skill   (the workflow brain)
         Phase 0  intake: classify, slug, branch delivery/<slug>
         Phase 1  spec: draft (spec-writing) → pm grades → revise
         Phase 2  implement: milestones, receipts, small commits
         Phase 3  panel: routed graders, launched in parallel
         Phase 4  fix loop: severity-ordered fixes → re-grade (cap 3)
         Phase 5  demo-recorder → report.md → handoff
```

`/grade` enters at Phase 3 only, for on-demand panel runs.

## Why commands + skills + agents (three layers)

- **Commands** are doorbells: one line of user intent → a prompt.
- **Skills** are the shared brain: the loop, routing, exit criteria live in
  one place (`agentic-delivery`), referenced by all commands. Skills are
  also auto-advertised, so plain-language requests find the workflow without
  a command.
- **Agents** are the specialists: permissions (read-only critics) and fresh
  subagent sessions (unbiased judgment) can only be configured at the agent
  level.

Splitting any of these differently would duplicate workflow logic or weaken
the permission boundary.

## Trust boundaries (honest limits)

- `shell` access cannot be prefix-restricted safely; agents with shell
  (implementation-grader, demo-recorder) are trusted to not modify files by
  prompt, not by permission. The `edit`-deny on critics is the hard boundary.
- The rubric's exit criteria are "machine-checkable" in the sense that the
  builder verifies them from receipts; the builder itself is an LLM. The
  evidence bundle exists precisely so a human can audit the machine's
  judgment at the single gate.
- Demo artifacts are real captures when possible; when the environment
  can't run the app, demo-recorder says so rather than fabricating.

## Extension points

- **New team member**: add `.opencode/agents/<role>.md` (read-only critic
  template: load `grading-rubric`, one lens, rubric report format), then
  add it to the routing table in `agentic-delivery/SKILL.md`.
- **Auto-merge**: when trust is earned, the handoff step can open a PR and
  merge when exit criteria pass. Deliberately not enabled.
- **CI wiring**: the panel's Phase 3 can be run by CI on every PR
  (`/grade` semantics) so human-created changes get the same grading.
- **Tracker integration**: `/rfe`/`/cve` take text today; an intake step
  that pulls from Jira/GitHub Issues is additive (Phase 0).
- **Per-agent models**: add `model:` frontmatter to any agent (e.g., a
  stronger model for security-analyst) — omitted for portability.

## References

- Anthropic, [Building effective agents](https://www.anthropic.com/research/building-effective-agents)
  (generator–critic / evaluator-optimizer patterns, simplicity)
- OpenCode docs: [agents](https://opencode.ai/docs/agents),
  [skills](https://opencode.ai/docs/skills),
  [commands](https://opencode.ai/docs/commands)
