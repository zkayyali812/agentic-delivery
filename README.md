# agentic-delivery

An autonomous **delivery team** for [OpenCode](https://opencode.ai): one
builder agent that writes code, surrounded by specialist agents that grade
it. Hand it an RFE (feature request) or a CVE (security vulnerability); it
runs spec → implement → grade → fix → demo autonomously and hands you a
branch plus a complete evidence bundle. You make one decision: merge.

## Quickstart

In this repo (or copy `.opencode/` into your project):

```
/rfe add rate limiting to the login endpoint — 10 req/min per IP, 429 on excess
/cve CVE-2026-12345 — ReDoS in the lodash dependency used by package-parser
/grade
```

- `/rfe <description>` — deliver a feature end-to-end
- `/cve <advisory or description>` — deliver a security fix end-to-end
- `/grade` — run the grader panel on current changes, on demand

You can also just ask in plain language ("deliver this feature: …") — the
`agentic-delivery` skill is auto-discovered — or reference it explicitly
with `@agentic-delivery`.

## The team

| Agent | Lens | Runs when |
|-------|------|-----------|
| `pm` | product value, spec quality, scope discipline | every item |
| `ux-critic` | flows, error states, copy, accessibility | user-facing items |
| `implementation-grader` | spec coverage, criterion-by-criterion, with evidence | every item |
| `code-reviewer` | bugs, regressions, maintainability | every item |
| `security-analyst` | threat model, CWE, secrets; CVE track lead | every item |
| `demo-recorder` | screenshots, walkthroughs, example transcripts | end of run |

All critics are **read-only** (permissions deny `edit`; most also deny
`shell`) and run in **fresh subagent sessions**, so they never share the
builder's context or biases. The builder never grades its own work.

## What you get back

Everything lands under `deliveries/<slug>/`:

```
deliveries/login-rate-limiting/
├── spec.md          # ground truth the graders graded against
├── report.md        # what/why/verified/rollback
├── demo/            # screenshots, walkthrough, example transcripts
└── <grader reports> # final-cycle panel output
```

The report answers: what was asked, what changed and why, per-cycle grader
verdicts, receipts (real test/command output), remaining minors, and the
smallest safe rollback. Your only job is to read it and merge (or not).

## How "done" is decided

No human gates mid-run. A run exits when — per the
[grading rubric](.opencode/skills/grading-rubric/SKILL.md):

1. every acceptance criterion PASSes with evidence,
2. zero blockers and zero majors remain across the panel,
3. the full test suite is green (receipt captured), and
4. for CVEs: the repro test fails-before / passes-after (both receipts).

If the fix–regrade loop hits its cap (3 cycles) without meeting those, the
run stops and reports exactly what's stuck and what it needs from you.

## Repo layout

```
.opencode/
├── agents/           # the 6 team agents
├── skills/           # agentic-delivery (master), spec-writing, grading-rubric
└── commands/         # /rfe, /cve, /grade
docs/
├── PLAN.md           # the design plan (v3)
└── ARCHITECTURE.md   # rationale: principles → decisions
```

## Extending

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the design rationale
and how to add team members, wire graders into CI, or flip on auto-merge.
