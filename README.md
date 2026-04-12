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
- Xcode Cloud for CI

## Architecture

Four strict layers — dependencies flow downward only:

```
Presentation → ViewModels + Controllers → Domain → Repositories → External
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for full diagrams and [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) for build sequence.

## Development

> **Read `CLAUDE.md` before writing any code.**

v1 is complete. See `IMPLEMENTATION_PLAN.md` for architecture decisions and the version roadmap for what's next.

## Testing

- **Unit tests:** 5 test files — TDD coverage for all services and controllers, `HomeViewModel`, and `OnboardingFlowState`
- **UITests:** 3 test classes covering app launch, onboarding flow, and pinned forms
- Run UITests with the `-uitesting` launch argument — this resets `UserDefaults` for a clean state on each run
- **Total: 42 tests, all passing at v1.0**

## Known v1 limitations

- `BeltSystemPreset.custom` shows "coming soon" — not implemented in v1
- `SessionRepository` is a no-op stub — session history persistence is v2
- Jitae, Cheonkwon, Hansu, and Ilyo have no YouTube video URLs in v1

## Version roadmap

| Version | Focus |
|---|---|
| v1 | Solo training loop |
| v1.1 | Dojang-specific catalogs, Kukkiwon fallbacks |
| v2 | Weakness engine, stats view, custom dojang editor |
| v3+ | Validate before expanding |
