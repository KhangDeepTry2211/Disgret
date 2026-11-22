# Codebase Graph (Graphify)

Graphify builds a knowledge graph of the code (functions, classes, providers, imports, calls,
navigation) so agents can find dependents before changing shared code. The graph is an **aid,
never a source of truth**: confirm every finding in the source files.

## Setup (each developer, once)

```bash
uv tool install graphifyy==0.9.115     # PyPI package name has two "y"; CLI is `graphify`
uv tool update-shell                   # puts ~/.local/bin on PATH (restart the terminal / app)
graphify --version                     # expect: graphify 0.9.115
```

The project is already configured (committed):

| File | Purpose |
|---|---|
| `.claude/skills/graphify/` | Claude Code `/graphify` skill (installed by `graphify install --project`) |
| `.claude/CLAUDE.md` | skill registration written by Graphify |
| `CLAUDE.md` → `## graphify` | Graphify's managed instructions for Claude Code (do not hand-edit; `graphify claude install --project` rewrites it) |
| `.claude/settings.json` → `hooks` | `graphify hook-guard` PreToolUse (Bash/Grep, Read/Glob) and SessionStart (compact) hooks, soft mode |
| `.graphifyignore` | excludes unsupported platforms, assets, tool folders |

The hooks call the bare `graphify` command. If it is not on PATH, Claude Code shows a hook error on
tool calls (non-blocking): install Graphify or remove the hooks with `graphify claude uninstall`.

## Build and refresh

```bash
GRAPHIFY_BACKEND=none graphify update .   # code-only AST build: offline, no LLM, ~seconds
```

- Output: `graphify-out/` (`graph.json`, `GRAPH_REPORT.md`, `graph.html`). It is **git-ignored**;
  each developer rebuilds locally.
- Rebuild after `git pull`, after switching branches, and after significant code changes (new or
  moved files, renamed symbols, router/provider changes). Optional: `graphify hook install` adds
  local git hooks that rebuild on commit and checkout (not committed).
- After a refactor that deletes code, use `graphify update . --force`.
- `GRAPHIFY_BACKEND=none` keeps the build local and stops community naming from calling an LLM.
  Code never leaves the machine in this mode. Avoid `/graphify .` with docs unless you want the
  assistant to read the Markdown docs into the graph.
- Query logs go to `~/.cache/graphify-queries.log` (local); set `GRAPHIFY_QUERY_LOG_DISABLE=1` to
  turn them off.

## Querying

```bash
graphify explain "FocusSessionNotifier"            # a node and its neighbours
graphify path "TodayScreen" "FocusSessionNotifier" # how two things connect
graphify query "which screens start a focus session?"
```

Names that match several nodes are refused with candidates (exit 3); no match exits 4.

## Investigating dependents before changing a shared component

1. `graphify explain "<Symbol>"` and note every incoming edge (`<--`).
2. **Always also run** `grep -rn "<Symbol>" lib test` and union the results. Verified on
   2026-11-22 (first graph: 151 files, 2659 nodes, 3985 edges): the Dart extractor **missed**
   `focusHabitChoiceProvider` in `lib/widgets/habit_today_card.dart` and the `HabitCard(...)` use
   in `lib/screens/home_screen.dart` and its test. Symbol-level Dart edges are incomplete;
   file-level imports are more reliable.
3. Read each dependent at the located lines; list them in the plan/research ("dependents") or the
   commit message.
4. After the change, run `graphify update .` and re-check the same symbol.

## When the first graph was generated

The repository already had code, so a real graph was generated during project setup on
2026-11-22 (not committed). Regenerate it with the command above on any fresh clone.
