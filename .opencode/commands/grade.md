---
description: Run the delivery-team grader panel against current changes (on-demand, no delivery loop)
---

Load the agentic-delivery skill (id: agentic-delivery), then run only
Phase 3 (the grader panel) against the current working-tree changes.
Assemble the panel per the skill's routing rules (classify the change
first: RFE or CVE, user-facing or not), launch the graders in parallel,
and report their findings in severity order with evidence. Do not fix
anything — this is grading only.

$ARGUMENTS
