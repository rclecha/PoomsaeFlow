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
- SwiftData for session history persistence
- No third-party dependencies
- Xcode Cloud for CI

## Architecture

Four strict layers — dependencies flow downward only:

```
Presentation → ViewModels + Controllers → Domain → Repositories → External
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for full diagrams and [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) for build sequence.

## Development

Read `CLAUDE.md` before writing any code. Start with Step 1 of the build sequence in `IMPLEMENTATION_PLAN.md`.

## Version roadmap

| Version | Focus |
|---|---|
| v1 | Solo training loop |
| v1.1 | Dojang-specific catalogs, Kukkiwon fallbacks |
| v2 | Weakness engine, stats view, custom dojang editor |
| v3+ | Validate before expanding |
