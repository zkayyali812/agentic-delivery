---
name: Spec Writing
description: How to write delivery specs for RFEs (feature requests) and CVEs (security fixes) — goal, non-goals, testable acceptance criteria, milestones, and CVE repro-first/minimal-fix scoping
---

# Spec Writing

The spec is the ground truth for the whole delivery run: the builder
implements it, and the graders grade against it. A vague spec makes every
downstream grade meaningless. Write it carefully.

Save specs to `deliveries/<work-item-slug>/spec.md`.

## RFE spec format

```markdown
# Spec: <short title>

- Type: RFE
- User-facing: yes | no
- Slug: <kebab-case-slug>

## Goal
One paragraph: what problem this solves, for whom, and why it matters.

## Non-goals
Explicitly out of scope. This is the scope-creep firewall — list anything
adjacent that a reasonable implementer might be tempted to include.

## Acceptance criteria
Numbered, each independently observable and verifiable. Every criterion will
be graded PASS/FAIL with evidence, so write them testable:

1. When <condition>, then <observable behavior>.
2. ...

Bad: "login should be fast". Good: "a login attempt under normal load
responds in < 500ms (measured by the test in <test file>)".
Bad: "rate limiting works". Good: "the 11th request within 60s from one IP
gets HTTP 429; the first 10 succeed (verified by integration test)".

## Edge cases
Known edges the implementation must handle (and what correct behavior is):
empty input, concurrent access, failure modes, boundaries.

## Milestones
2–5 ordered, independently committable chunks. Each milestone ends with the
suite green.
```

## CVE spec format

```markdown
# Spec: <CVE-id or short title>

- Type: CVE
- User-facing: yes | no
- Slug: <kebab-case-slug>

## Advisory
CVE id / advisory link / description of the vulnerability.

## Triage
- Affected component(s) and code paths
- Vulnerability class (CWE if known)
- Exploitability and blast radius in *this* codebase
- Is the vulnerable path actually reachable here?

## Reproduction plan
The failing test that demonstrates the vulnerability. Written BEFORE the fix.
State exactly: test file, what it does, what failure output proves the vuln.

## Minimal-fix scope
The smallest change that eliminates the vulnerability. Security fixes do not
refactor, rename, or "improve" anything they don't strictly need to. List
explicit non-goals.

## Acceptance criteria
1. Repro test fails on pre-fix code (receipt required).
2. Repro test passes on post-fix code (receipt required).
3. Full existing suite stays green.
4. <Any behavior that must be preserved — the fix must not break legitimate use.>
```

## Rules for all specs

- **Testable or it doesn't exist.** If a criterion can't be verified with a
  command, a test, or a direct observation, rewrite it until it can.
- **Non-goals are mandatory.** They are how the pm and the graders detect
  scope creep.
- **Small specs.** If a spec needs more than ~5 milestones, it should
  probably be split into multiple delivery runs.
- **No implementation detail.** Specs say *what* and *how verified*, not
  *how to code it*.
