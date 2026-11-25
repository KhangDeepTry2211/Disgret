# Feature Specification: Livelier fonts and a Gret launch screen

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "lựa chọn lại cho mình font chữ phù hợp và bắt mắt sinh động hơn … làm luôn
giao diện loading khi mới bấm vào app chứ không đơn thuần chỉ là logo app"; chose font option C
(Baloo 2 for headings and titles, Nunito for text) and launch screen 1 (Gret swims across), and
agreed to download the two font files from github.com/google/fonts (OFL).

## User Scenarios & Testing

### User Story 1 - Livelier text (Priority: P1)

Headings, titles and the main buttons use Baloo 2 (rounded, bold); body text and labels use Nunito.
Vietnamese diacritics render correctly. No network at run time: both fonts are bundled.

### User Story 2 - Gret swims across when DisGret opens (Priority: P1)

After the system splash (logo on #1E88E5), a launch screen on the same blue shows Gret swimming
across with bubbles, "DisGret" and "Đang lặn xuống biển…" for about 1.4 s, then fades into the
app. With "remove animations" on, Gret stays still in the middle and the screen goes away after the
same time.

### Edge Cases

- The launch screen shows once per cold start, not when coming back from the background.
- Small phones: no overflow with the new fonts.

## Requirements

- **FR-001**: Fonts `Baloo2` and `Nunito` MUST be declared in `pubspec.yaml` from variable TTFs in
  `assets/fonts/`, each style selecting its weight with `FontVariation('wght', …)`; their OFL
  licences MUST appear in the app's licence page; Be Vietnam Pro is removed.
- **FR-002**: display, headline, title styles: Baloo 2 (700 for display/headline, 600 for title);
  body: Nunito 400; label: Nunito 700.
- **FR-003**: A launch overlay MUST cover the app for `AppMotion.launch` (1.4 s) then fade out over
  `AppMotion.launchFade` (300 ms); background `AppColors.brand`; Gret in the student's look.
- **FR-004**: Tests can switch the overlay off (`launchScreenProvider`), and `pumpApp` does.
