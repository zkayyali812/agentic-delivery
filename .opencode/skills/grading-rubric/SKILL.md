---
name: Grading Rubric
description: Shared severity levels, evidence rules, report format, and machine-checkable exit criteria used by all delivery-team agents when grading specs, implementations, and security fixes
---

# Grading Rubric

Single source of truth for how the delivery team grades work. Every grader
loads this skill before grading and applies it consistently. The builder uses
the exit criteria below to decide — without human input — when a work item is
done.

## Severity levels

| Level | Definition | Blocks exit? |
|-------|-----------|--------------|
| **Blocker** | The work item is not delivered as specified: a spec criterion FAILs, a confirmed security vulnerability, tests red, crash, data loss, auth bypass, or the CVE is not actually fixed | Yes — always |
| **Major** | Significant defect or gap that should be fixed before merge: broken edge case with real user impact, missing error handling on a primary path, regression risk, incomplete fix, misleading behavior | Yes — always |
| **Minor** | Small defect, inconsistency, or tech debt that is safe to ship; must be listed in the delivery report | No |
| **Nit** | Style, naming, preference | No |

All findings from **any** routed panel member count. Blockers and majors must
reach zero before exit; minors and nits are recorded, not fixed by mandate.

## Evidence rules

These are non-negotiable:

1. **Every finding** states: severity, title, location (`file:line` or artifact
   path), why it matters, and a concrete suggested fix.
2. **Every PASS/FAIL** on a spec criterion cites evidence: a command and its
   output snippet (receipt), or an exact `file:line` reference.
3. **No finding without evidence. No pass without a receipt.**
4. **Never trust the implementer's claims.** Graders verify from disk, git,
   and test output — not from the builder's summary.
5. Graders grade *only* what is in scope for the current work item. Pre-existing
   issues outside the diff are noted as `MINOR (pre-existing)` at most.

## Report format

Every grader returns exactly this structure (Markdown):

```markdown
## <Role> Report — cycle <N>

Verdict: PASS | FAIL | CANNOT-RUN

### Findings
- [BLOCKER] <title> — <file:line> — <why it matters> — <suggested fix>
- [MAJOR] ...
- [MINOR] ...
- [NIT] ...

### Criterion coverage (implementation-grader only)
| # | Criterion (from spec) | Verdict | Evidence |
|---|----------------------|---------|----------|
| 1 | ... | PASS | <receipt> |
```

`Verdict: PASS` means zero blockers and zero majors in this report. Anything
else is `FAIL`.

`Verdict: CANNOT-RUN` means a capability the lens requires was unavailable —
the model cannot analyze images, browser tools are missing, the test runner
is absent. The report must name the missing capability, state exactly what
could not be verified, and still return any findings gathered up to that
point. CANNOT-RUN is **never** equivalent to PASS. Graders never silently
skip part of their lens: if you couldn't check it, say so.

## Exit criteria (machine-checkable)

A delivery run is **DONE** when all of the following hold:

1. Every acceptance criterion in the spec: **PASS with evidence**.
2. Final grader reports from every routed panel member: **zero blockers,
   zero majors** (minors/nits allowed, listed in the report).
3. Full test suite: **green**, with output captured as a receipt.
4. CVE track only: the reproducing test **fails on the pre-fix code and
   passes on the post-fix code** — both outputs captured as receipts.

A `CANNOT-RUN` from a routed panel member does not by itself block exit,
but only after the builder has tried to restore the capability (start the
app, fix the pinned model). If it cannot be restored, the run may exit
with the lens recorded as **unverified**: it must appear in the delivery
report's grading summary and be named explicitly in the handoff. An
unverified lens is never silently dropped.

A delivery run **STOPS AND ESCALATES** when:

- The fix–regrade cycle count reaches **3** and exit criteria still fail. The
  final report must state exactly which criteria/findings are stuck, what was
  tried, and what decision is needed from the human.
- Any blocker is judged unfixable within the spec's scope (e.g., it requires a
  product decision or an architectural change).

## Cycle discipline

- One cycle = full panel grades the current state → builder fixes all
  blockers+majors → panel re-grades.
- Between cycles the builder fixes findings in severity order (blockers,
  majors, then optionally minors) and commits each fix separately.
- Graders re-grade the *whole* item each cycle, not just the fixes — a fix for
  one finding must not introduce another.
