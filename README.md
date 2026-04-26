# PoomsaeFlow

A personal Taekwondo poomsae training companion for iOS. Built with SwiftUI and Claude Code as part of an AI-assisted development portfolio.

**Author:** Ryan  
**Dojang:** Sparta TKD, Walnut Creek CA

## What it does

- Onboarding flow to select dojang profile and belt level
- Practice session with configurable scope (full set, pinned forms, single form) and order
- Immediate retry on failed forms — same form repeats, index does not advance
- Self-reported outcome tracking (Nailed it / Retry / Skip)
- YouTube deep links to watch form videos
- Pin/unpin forms during a session to build a "tricky forms" subset
- iPhone + iPad support

## Stack

- SwiftUI, iOS 17+, Xcode 16+
- `@Observable` macro (not `ObservableObject`)
- SwiftData for `FormAttempt` persistence (session history queries are v2 — `SessionRepository` is currently a stub)
- No third-party dependencies
- GitHub Actions for CI (macos-26, unit tests on push to main and every PR)

## Architecture

Four strict layers — dependencies flow downward only:

```
Presentation → ViewModels + Controllers → Domain → Repositories → External
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for full diagrams and [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) for build sequence.

## Development

> **Read `CLAUDE.md` before writing any code.**

v1 through v1.5 are complete. See `IMPLEMENTATION_PLAN.md` for architecture decisions and the version roadmap for what's next.

## Testing

- **Unit tests:** 12 test files — TDD coverage for all services and controllers, `HomeViewModel`, `OnboardingFlowState`, `SessionCompleteView`, `FormFamily`, `FormsDataSource`, `FormRepository`, `PracticeSession`, `PinnedForms`, and `UserPrefsRepository`
- **UITests:** 8 test classes — `AppLaunchTests`, `OnboardingUITests`, `PinnedFormsUITests`, `PinnedFormsManagerUITests`, `FormBrowserUITests`, `SettingsSchoolSwitchUITests`, `VideoResourceUITests`, `SessionUITests`
- Run UITests with the `-uitesting` launch argument — this resets `UserDefaults` for a clean state on each run
- **Logic-layer coverage: 81.0%** — reported to the GitHub Actions job summary on every CI run
- **Total: 164 tests, all passing**

## Changelog

| Version | Summary |
|---|---|
| v1.5 | Coverage reporting (81.0%, job summary), 72 new unit tests (164 total), refactor audit + apply, Hwarang bug fix |
| v1.4 | CD pipeline — automated TestFlight builds on every merge to main |
| v1.3 | Session UX (retry badge, shake, haptic), home screen navigation, CI pipeline, summary bug fixes |
| v1.2 | Pinned Forms practice sessions, PinnedFormsView hub screen, bidirectional FormBrowserView |
| v1.1 | Dojang-specific form catalogs, Kukkiwon YouTube fallbacks for black belt forms |
| v1 | Solo training loop — core session experience |

## Known v1 limitations

- `BeltSystemPreset.custom` shows "coming soon" — not implemented in v1
- `SessionRepository` is a no-op stub — session history persistence is v2

## Version roadmap

| Version | Focus | Status |
|---|---|---|
| v1 | Solo training loop | Complete ✅ |
| v1.1 | Dojang-specific catalogs, Kukkiwon fallbacks | Complete ✅ |
| v1.2 | Pinned Forms practice sessions, UX polish, and UITest expansion | Complete ✅ |
| v1.3 | Session UX (retry badge, shake, haptic), home screen navigation, CI pipeline, bug fixes | Complete ✅ |
| v1.4 | CD pipeline — automated TestFlight builds on every merge to main | Complete ✅ |
| v1.5 | Coverage reporting, 72 new unit tests, refactor audit + apply | Complete ✅ |
| v1.6 | Verify Taegeuk Sa Jang in WT green belt; poom belt split color | Planned |
| v2 | Weakness engine, stats view, custom dojang editor | Planned |
| v3+ | Validate before expanding | Planned |
