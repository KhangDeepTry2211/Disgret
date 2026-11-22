@AGENTS.md

# Claude Code specifics

Shared rules live in `AGENTS.md` (imported above) and the constitution. Add here only what is
specific to Claude Code.

## Spec Kit skills

- Use the project skills in `.claude/skills/`: `/speckit-specify`, `/speckit-clarify`,
  `/speckit-plan`, `/speckit-checklist`, `/speckit-tasks`, `/speckit-analyze`,
  `/speckit-implement`, `/speckit-converge`, `/speckit-constitution`.
- Before running `/speckit-plan`, `/speckit-tasks` or `/speckit-implement`, check that
  `.specify/feature.json` points at the intended `specs/NNN-*` folder (it is per-checkout and not
  committed).
- `/speckit-analyze` is read-only: report findings and ask before applying fixes.
- Do not edit files under `.specify/templates/`, `.specify/scripts/` or `.claude/skills/speckit-*`
  by hand; they are managed by `specify` (upgrade with `specify integration upgrade claude`).

## Working style

- When implementing a task, read its spec section, `plan.md`, `research.md` and the relevant
  `contracts/` file first; cite the task ID (e.g. `001-T009`) in the commit message.
- Run `dart format`, `flutter analyze` and `flutter test` yourself after code edits and report the
  actual output; do not ask the user to run them.
- Path-specific rules are in `.claude/rules/` and load automatically for matching files.
- The `## graphify` section below is managed by Graphify. Its "query before grep" rule applies,
  but for Dart symbols always confirm dependents with `grep` as well (see AGENTS.md).
- If the `grill-me` / `grilling` skills are installed (user-level, not part of this repo), use them
  only when the user asks to be interviewed about a plan.
- Answer the project lead in Vietnamese; write repository artifacts in English (UI text stays
  Vietnamese).

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. When the answer is under a Markdown heading, `graphify section "<heading>"` prints that section's text, so the .md need not be opened. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
