# ADR-0007: Accepted risk — bundled Instagram videos in a public repository

- Status: Accepted (risk)
- Date: 2026-11-22

## Context

`assets/reels/` (~13 MB) bundles six videos sourced from Instagram; each reel has a `creditUrl`.
The repository `ltuong0211/Disgret` is public. The team's own risk register rates the copyright
risk as Medium.

## Decision

Keep the videos unchanged for now. Replacing them, and possibly purging them from git history, is
deferred.

## Consequences

- Copyright exposure remains while the repository and APK are distributed.
- Revisit before any public release or before the experiment with external participants.
