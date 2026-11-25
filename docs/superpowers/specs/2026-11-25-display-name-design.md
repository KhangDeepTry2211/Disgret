# Tên gọi (display name) — short design

Date: 2026-11-25 · Status: approved by the project lead in chat ("duyệt luôn") · Feature: spec
`specs/007-display-name` · Decision record: ADR-0012.

## Intent

The lead wants the Hôm nay header to read "DisGret" with "Chào buổi sáng, <tên>" under it, and
the student to enter their name. The name is used only for that greeting.

## Decisions taken with the lead

- Only a name ("tên gọi"; a nickname is fine), used only for the greeting.
- Optional, at most 20 characters, kept only on the phone.

## Approaches

1. **A `displayName` field on the existing profile (chosen)**, asked in onboarding and editable in
   Cài đặt.
2. A separate storage key: duplicates the profile for one string.
3. Only in Cài đặt: new students would not know it exists.

## Design

- Header: line 1 "DisGret", line 2 the time-of-day greeting, followed by ", <tên>" when a name is
  set; one line, ellipsis.
- Onboarding: a page right after the four story pages; Gret asks "Bạn muốn Gret gọi bạn là gì?"
  in a thought bubble; one text field (hint: a nickname is fine, may stay empty); "Tiếp tục" works
  with or without a name (builder's call: no separate skip button). Replaying the introduction
  pre-fills the current name.
- Cài đặt: a "Tên gọi" row at the top; tapping it opens a dialog with the field, "Hủy" and "Lưu".
- Rule: trim, collapse inner spaces, keep the first 20 characters (grapheme clusters).
- Privacy: never in events or exports; cleared with "Xóa toàn bộ dữ liệu"; ADR-0012.
- Non-goals: other profile data; using the name in Gret's or the café friends' lines.

## Left to the builder

Exact hint and dialog wording, icon.
