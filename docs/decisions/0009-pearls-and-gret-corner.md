# ADR-0009: Pearls earned by studying, and Góc của Gret

- Status: Accepted (project lead, chat 2026-11-23)
- Date: 2026-11-23
- Related: ADR-0004 (gamification parked), ADR-0008 (Gret is feedback), spec 004, design
  `docs/superpowers/specs/2026-11-23-gret-corner-design.md`

## Context

ADR-0004 parked points, badges and levels because they pulled attention away from studying.
ADR-0008 kept Gret and the sea as feedback, not rewards. The lead now wants students to have a
reason to return for days (scenario S3): a wardrobe for Gret, seas to unlock and new mascots, with
some items later sold for real money.

## Decision

- Allow one cosmetic economy: **pearls**, earned only from focused study time (1 per 5 focused
  minutes of a saved session) and computed from saved sessions, never stored as a balance.
- Pearls can never be bought, and are never taken away for a distraction. They are spent only when
  the user chooses an item.
- Items are cosmetic only (outfits, seas, mascots). They give no advantage, no ranking, no
  comparison between users, no timers or limited offers.
- Some items unlock at a streak length; the best streak ever counts, so nothing locks again.
- Premium items are listed with "Sắp có". Selling them needs Google Play Billing, network access
  and a payment flow suitable for users under 18; that is a separate, later ADR. Until then the app
  stays offline.
- The parked gamification of ADR-0004 (levels, badges, points shown as scores) stays parked.

## Consequences

- New pure logic (pearl earning, balance, unlock rules) with unit tests; choices are stored in the
  existing profile box, so older data stays readable and nothing migrates.
- Every new item needs vector art on Gret's shared 240×200 canvas.
- The summary can show "+N ngọc trai" for a session (feature 003, user story 4).
