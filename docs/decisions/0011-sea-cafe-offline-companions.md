# ADR-0011: Quán San Hô — offline sea friends now, real people later

- Status: Accepted (project lead, chat 2026-11-24)
- Date: 2026-11-24
- Related: constitution Principles I and II, ADR-0002, ADR-0003, ADR-0009, ADR-0010, spec 006,
  design `docs/superpowers/specs/2026-11-24-sea-cafe-design.md`

## Context

The lead wants students not to feel that they study alone, inspired by an online "Phòng trà" study
room where several people sit at tables and greet each other with ready-made phrases. Showing real
people needs a backend, accounts and network calls, which Principle II forbids, and users include
students under 18.

## Decision

- Build the café offline now. The companions are Gret's sea friends (an owner and three friends),
  characters with names that are never presented as real users; no "N người đang học" count.
- The café is a place for the focus session chosen in the session plan, not a screen of its own,
  so "Bắt đầu" stays the only way into a session (ADR-0002). It is the default place.
- Each student keeps their own plan; there is no shared room clock.
- Greetings are ready-made phrases only; nothing typed, stored or sent.
- The seats come from one provider so that a later online feature can add real users' Grets.
  That feature needs a constitution amendment (Principle II), its own ADR and a safety review
  (ready-made phrases only, no profiles, no free text) before any code.

## Consequences

- New pure logic `lib/data/sea_cafe.dart`, a `study_place` profile key and an optional `place` on
  saved sessions (old sessions read as `sea`).
- Two new species drawings (turtle, starfish) used only in the café; they are not added to the Góc
  của Gret catalog.
- The focus screen gains a second scene; widget tests that assert on the sea set the place to
  `sea`.
