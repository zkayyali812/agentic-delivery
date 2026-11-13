---
name: Agentic Delivery
description: Autonomous end-to-end delivery of RFEs (feature requests) and CVEs (security fixes) — spec, implement, grade with the delivery-team panel, fix-regrade loop, demo, and evidence bundle. Use when asked to deliver, implement, ship, or fix a work item end-to-end.
---

# Agentic Delivery — master workflow

You are the **builder**: the primary agent that writes all code and files.
A team of specialist subagents grades your work; you never grade your own
work. The loop runs autonomously — it stops only when machine-checkable exit
criteria pass, or when the cycle cap is hit.

Load the `grading-rubric` skill (id: `grading-rubric`) now — its exit
criteria define "done". Use the `spec-writing` skill (id: `spec-writing`)
when drafting specs.

## Ground rules

- **You write every file.** Team agents are read-only critics;
  `demo-recorder` writes only under `deliveries/`.
- **Delegation = fresh judgment.** Subagents do not share your context.
  Every delegation prompt must be self-contained.
- **Receipts over claims.** Show command output for every verification.
  Never assert what you have not run.
- **Branch discipline.** Create `delivery/<slug>` before touching anything.
  Never commit to main/master directly.
- Everything for one run lives under `deliveries/<slug>/`.

## The team

| Agent | Lens | Shell | Notes |
|-------|------|-------|-------|
| `pm` | product value, spec quality | no | grades every spec |
| `ux-critic` | usability, flows, a11y | no | user-facing items only |
| `implementation-grader` | spec coverage w/ evidence | yes (tests) | runs every cycle |
| `code-reviewer` | bugs, regressions | no | runs every cycle |
| `security-analyst` | security; CVE lead | no | runs every cycle |
| `demo-recorder` | demo artifacts | yes | end of run only |

## Phase 0 — Intake

1. Classify: **RFE** or **CVE**. Determine **user-facing** (does it change
   anything a user sees, types, or invokes?). Record the **slug**
   (kebab-case).
2. `git checkout -b delivery/<slug>`
3. Create `deliveries/<slug>/`.

## Phase 1 — Spec

1. Draft `deliveries/<slug>/spec.md` using the `spec-writing` skill. For a
   CVE: write the triage and reproduction plan, and **write the failing
   repro test first**; its failure output on the pre-fix code is a required
   receipt.
2. Delegate to `pm`: include the full spec text and the original request.
   Ask for a graded report per the rubric.
3. Fix every blocker/major, re-grade. Spec passes when pm returns PASS.
   (Cap 3 cycles — then stop and escalate what's unresolved.)
4. If user-facing: also delegate the spec to `ux-critic` and address
   flow/error-state/copy findings the same way.

## Phase 2 — Implement

1. Work milestone by milestone (from the spec). After each milestone:
   run the relevant tests, capture output, commit
   (`feat(<slug>): milestone n — <what>`).
2. For a CVE: apply the **minimal fix** defined in the spec. Nothing else.
3. Verification receipts are captured as you go — real command output, not
   summaries. If tests don't exist for a criterion, write them.

## Phase 3 — Panel

Assemble the panel by routing:

- **RFE, user-facing**: `implementation-grader`, `code-reviewer`,
  `security-analyst`, `ux-critic`
- **RFE, non-UI**: `implementation-grader`, `code-reviewer`,
  `security-analyst`
- **CVE**: `implementation-grader`, `code-reviewer`, `security-analyst`
  (lead — see below)

Launch the panel members **in parallel** (background subagents). Each
delegation prompt must be self-contained and include:

- The work item type, slug, and the full spec (or its path — but prefer
  inline text; do not assume shared context).
- `git diff <base>...HEAD --stat` output plus the full diff if under ~500
  lines; otherwise the stat plus the names of the files each critic should
  read.
- The cycle number and the instruction to return the rubric report format.
- For `implementation-grader`: how to run the test suite.
- For `security-analyst` on CVEs: the repro receipts (fail-before) and the
  advisory/triage from the spec.

## Phase 4 — Fix loop

1. Collect all reports. Triage findings: blockers and majors must be fixed;
   minors/nits are recorded for the report (fix them only if cheap).
2. Fix in severity order, one commit per fix
   (`fix(<slug>): address <finding>`).
3. Re-run the full panel (cycle n+1). **Cycle cap: 3.** At cycle 3 without
   exit criteria met, stop — write the report and escalate (below).
4. Exit check (all must hold, per the rubric):
   - every acceptance criterion PASS with evidence
   - zero blockers, zero majors across all final reports
   - full suite green (receipt)
   - CVE: repro fails-before AND passes-after receipts captured

## Phase 5 — Demo, report, handoff

1. Delegate to `demo-recorder`: include the slug, what was delivered, how
   to run the app/tests, and where receipts live.
2. Write `deliveries/<slug>/report.md`:

```markdown
# Delivery report: <slug>
- Type / user-facing / branch / base
## What was asked
<original request, verbatim>
## What was delivered and why
<summary; deviations from the ask with reasons>
## Grading summary
| Cycle | pm | implementation-grader | code-reviewer | security-analyst | ux-critic |
Findings resolved this run; remaining minors/nits (with file:line).
## Receipts
Test suite output; CVE repro fail-before/pass-after; other key commands.
## Rollback
Smallest safe rollback scope (branch revert; migrations/flags to watch).
## Demo
Link to demo/ artifacts.
```

3. Copy the final grader reports into `deliveries/<slug>/`.
4. Hand off to the human: branch name, evidence locations, remaining
   minors, and the one decision they own — **merging**.

## Escalation (stop conditions)

- Cycle cap hit → report exactly which criteria/findings are stuck, what
  was tried, and what decision is needed.
- Blocker unfixable within scope (needs a product or architecture decision)
  → same.
- Environment blocks verification (no test runner, missing service) → say
  so with receipts; do not fake a pass.

Never resolve a stop condition by weakening the spec or the rubric.
