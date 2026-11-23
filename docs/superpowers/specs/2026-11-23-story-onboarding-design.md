# Story onboarding with Gret — short design

Date: 2026-11-23 · Status: approved by the project lead (chat, 2026-11-23) · Feature: spec 003
(amends FR-011, user story 2).

## Intent

The lead asked for the first screen a new user sees to work "like a story": Gret introduces the
app in a lively way, then asks only the questions the app needs. Real users decide in the first
minute whether to keep the app (spec 003 US2), and a short story explains the one idea behind
DisGret (scrolling clouds Gret's sea, studying clears it, Gret calls you back) better than a static
welcome screen.

## Goals, non-goals, anti-goals

- Goals: a story-style sequence with Gret narrating; the existing questions presented one per page;
  one new question, "Which apps pull you away most?", stored in the existing blocked-apps list.
- Non-goals: questions for features that do not exist yet (usual study time for reminders, daily
  scroll time); a separate goal page and habit page; swiping between pages.
- Anti-goals: anything that blames the user; a story that cannot be skipped; losing the current
  guarantees (data saved only at the end, Back goes to the previous page, replay from Settings
  never duplicates the goal).

## Approaches considered

1. **One onboarding screen with an ordered list of pages (chosen).** Keeps the current state
   (answers, controllers) in one place, Back is a page index, no new dependency.
2. A story package such as `story_view`: a new dependency the constitution asks to justify, and
   its pages are media, not forms or answer cards.
3. One route per page: answers would have to travel between routes and Back handling with
   go_router becomes harder for no gain.

## Design (as approved)

Pages, in order:

| # | Page | Sea and Gret |
|---|---|---|
| 1 | Logo + "DisGret", headline "Bớt lướt. / Học nhiều hơn.", Gret says hello | clear sea, happy |
| 2 | "Scrolling reels too long clouds my sea" | murky sea with litter, sad |
| 3 | "Every minute you study clears it" | the same sea clears (colour animates), happy |
| 4 | "Pulled away mid-session? I'll call you back" | clear sea, focused |
| 5 | Question: reel length (three pills) | Gret asks in a thought bubble |
| 6–9 | The four motivation questions (unchanged quiz view) | as in T019 |
| 10 | New: "Which apps pull you away most?" — chips TikTok, YouTube, Instagram, Facebook, Chrome, preselected from the current list | Android only |
| 11 | First goal, reason, habit and minutes (one page, as before) | only when there is no goal |
| 12 | "Biển của bạn đã sẵn sàng" | unchanged (T018) |

Story behaviour:

- A row of progress segments at the top, one per page; the current story segment fills over 4 s.
- Story pages advance by themselves after 4 s, on "Tiếp tục", or on a tap on the right two thirds;
  a tap on the left third goes back; holding a finger pauses. "Bỏ qua" jumps to the first question.
- Question pages wait for an answer; no swiping between pages.
- System Back goes one page back; on page 1 it leaves the app.
- With "remove animations" on, story pages do not advance by themselves.

Data:

- Saved only when the last page is confirmed, as before. The app choice is written to the existing
  blocked-apps list (no new field or box); only the five offered apps are toggled, other packages
  in the list are kept.
- Replay from Settings with a goal: story, questions and the app page; no goal page, no finale.

## Left to the builder

Exact Vietnamese wording of the four story lines, layout spacing, and the progress-bar look, within
`app_theme.dart` tokens.
