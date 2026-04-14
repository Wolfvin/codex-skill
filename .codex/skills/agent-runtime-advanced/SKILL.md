---
name: agent-runtime-advanced
description: >
  Use for advanced agentic execution patterns adapted from clean-room
  architectures: context compaction, dependency task graph, worker loop,
  session recovery, and council-style parallel review.
---

# Agent Runtime Advanced

## Trigger
- User asks for advanced/auto workflow, long-session stability, or high-velocity execution.
- Task has many steps and risks context bloat.
- User asks for multi-agent style collaboration.

## Protocol

1. Build dependency graph first
- Create explicit task nodes with `blocked_by` references.
- Execute only tasks with no unresolved blockers.
- Re-evaluate graph after each completed task.

2. Use context compaction checkpoints
- After major milestone, write a short durable summary into `.codex/memory/`.
- Keep: decisions, changed files, risks, and pending blockers.
- Drop verbose logs and repeated reasoning.
- If `MEMORY.md` grows too long, archive detail into `session_log_archive_*.md` and keep hot memory concise.

3. Worker loop execution
- Pick next ready task from dependency graph.
- Implement + verify immediately.
- Mark done and move to next ready task.
- If scope is fuzzy, run a short brainstorm phase first, then convert to executable tasks.

4. Session recovery discipline
- Maintain a latest status snapshot in memory so interrupted sessions can resume fast.
- Snapshot format: current goal, done, next, blockers.
- Recommended command:
  - `bash .codex/tools/agentic-hub.sh checkpoint --goal "<...>" --done "<...>" --next "<...>" --blockers "<...>"`

5. Council-style review (without unsafe code import)
- For critical changes, run independent review pass after implementation.
- Separate implementation judgment from verification judgment.
- If consensus fails, revise plan before more edits.

## Output Contract
Always return:
- Task graph (or simplified ready queue)
- What was compacted into memory
- What was implemented
- Verification status and residual risks
- If archival happened: include archive file path.

## Constraints
- Never import leaked/proprietary code.
- Reuse only legal high-level patterns and workflows.
- Keep changes surgical and traceable to user request.
