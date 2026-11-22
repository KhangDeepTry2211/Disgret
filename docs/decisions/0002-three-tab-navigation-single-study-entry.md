# ADR-0002: Three-tab navigation with a single entry into studying

- Status: Accepted
- Date: 2026-11-22

## Context

The app has four tabs (Home, Reels, Focus, Habits). Home offers two competing ways to start
("Bắt đầu" goes through Reels, "Bỏ qua, vào học luôn" goes straight to Focus), the same habit
information appears on Home and on the Habits tab, and Reels sits beside Focus as a place to browse.
The MVP is framed by three scenarios: S1 hard to start, S2 distracted mid-session, S3 keeping it up
over several days. Every screen must serve at least one of them.

## Decision

- Bottom tabs: **Hôm nay** (`/today`), **Thói quen** (`/habits`), **Tiến độ** (`/progress`).
- `/motivation`, `/focus` and `/summary` are full-screen routes outside the shell.
- One study flow: Hôm nay "Bắt đầu" → `/motivation?context=start` (skippable) → `/focus` →
  `/summary` → `/today`. While a session runs, Hôm nay shows a "return to session" banner.
- Hôm nay answers only "what do I study now, and for how long": one goal, one start button, a
  small streak.
- Tiến độ hosts the habit report (moved from the Habits app bar) and statistics (moved from
  Settings); the R4.3 card will live here.
- Native actions keep their names; only their targets change (`resume_focus` and `break_ended` →
  `/focus`, `open_reels_distracted` → `/motivation?context=distracted`). No Kotlin change needed.
- Pausing the session clock while watching motivation moves from "Reels tab selected" to entering
  and leaving `/motivation`.

## Consequences

- Navigation tests and every `context.go(AppRoutes.…)` call site must be updated.
- Users lose the free-browsing Reels tab by design.
