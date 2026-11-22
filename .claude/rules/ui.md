---
paths:
  - "lib/screens/**"
  - "lib/widgets/**"
  - "lib/router/**"
---

# UI

- One primary action per screen; no second entry into a study session (ADR-0002); no feed, likes,
  comments, shares or counts (ADR-0003); parked features stay unreachable (ADR-0004).
- Colours, fonts, radii, spacing only from `lib/theme/app_theme.dart`; text for new or modified
  screens from `lib/l10n/app_strings.dart` (Vietnamese).
- Screens read state through providers; never open Hive boxes or call the MethodChannel here.
- Visual rules: `docs/architecture/design-system.md`. Route table: the current feature's
  `contracts/` file. Changed flows need widget tests and a README demo-script update.
