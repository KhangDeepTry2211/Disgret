# Hôm nay on a full-screen sea — short design

Date: 2026-11-25 · Status: approved by the project lead in chat ("Duyệt, làm luôn") · Feature: spec
`specs/010-today-fullscreen-sea`.

## Intent

The lead wants Gret's sea to fill the whole Hôm nay screen, with the existing cards floating on
top of it, like the unrot home screen (reference screenshot). Today the sea covers the top 46% and
the cards sit on a plain sheet below it.

## Decision taken with the lead

Approach **A**: the sea stands still and fills the screen; the cards float over it and scroll; the
tab bar becomes a floating rounded bar.

## Approaches considered

- A (chosen): fixed full-screen sea, floating cards, floating tab bar.
- B: one long sea that scrolls with the content (sky, water, sandy bottom); Gret scrolls away and
  the seabed needs new drawing.
- Keep the current half-screen sea on a plain sheet.

## Design

- The sea (`SeaScene`, full variant) fills Hôm nay behind everything and does not scroll. Gret
  swims in the upper part (about 30% of the height) instead of the scene's usual 72%, so the sky
  is behind the transparent header and deep water is behind the cards (white cards read well on
  it; at night the night sea).
- The content scrolls over the sea: a transparent space first (about 44% of the height, so Gret is
  in full view; tapping there still taps Gret), then the existing cards unchanged in content —
  Biển trong and chuỗi ngày, Mục tiêu hôm nay, Học tiếp, then "Bắt đầu" — each floating with 16 px
  margins; the plain sheet is removed. Scrolling slides the cards over Gret.
- The header stays as it is (transparent over the sky, surface colour once content scrolls under
  it).
- The tab bar of all three tabs becomes a floating rounded bar (16 px from the sides and bottom,
  surface colour, hairline border); content scrolls behind it and gets bottom padding so nothing
  is hidden. The running-session banner stays just above it.
- The empty states of Hôm nay (no goal, no habit) use the same full-screen sea.
- Reduced motion and dark mode behave as today.

## Non-goals

A list of today's habits with a play button each (a second way into a study session, ADR-0002); a
pearl card like unrot's coin card; changing the other tabs' backgrounds.

## Left to the builder

Exact spacing, the bar's height and shadow, the Gret tap area.
