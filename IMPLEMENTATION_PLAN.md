# PoomsaeFlow — Implementation Plan

## Project overview

Personal iOS poomsae training companion. SwiftUI, iOS 17+, SwiftData, no third-party dependencies. Public GitHub repo. Built with Claude Code as an AI-assisted development portfolio project.

**Author:** Ryan  
**Dojang:** Sparta TKD, Walnut Creek CA  
**Stack:** SwiftUI · iOS 17+ · Xcode 16+ · SwiftData  
**CI:** Xcode Cloud  

---

## Architecture overview

Four strict layers. Dependencies flow downward only. Upper layers never import lower layer types directly.

```
Presentation      Views — zero business logic, bindings and layout only
     ↓
ViewModels +      HomeViewModel · SessionViewModel · FilterViewModel
Controllers       SessionController (owns all mutable session state)
     ↓
Domain            SessionBuilder · FormFilterService · Models
     ↓
Repositories      FormRepository · UserPrefsRepository · SessionRepository (stub)
     ↓
External          FormsDataSource (static) · UserDefaults · SwiftData · YouTube/Safari
```

**Key invariants:**
- Views hold zero business logic
- `SessionController` owns all mutable session state and outcome logic
- `SessionViewModel` is thin — translates taps into controller calls, exposes derived state
- `FormFilterService` and `SessionBuilder` are pure functions — no side effects
- All repositories are protocol-driven for testability
- `CanonicalBelt` is the source of truth for form eligibility across all dojang profiles

---

## Build steps — Historical, v1 complete

### Step 1 — Core value types + static catalog
**Goal:** Compilable foundation. No UI. No logic.

Files created:
- `Domain/Models/CanonicalBelt.swift` — stable enum, source of truth for eligibility
- `Domain/Models/FormFamily.swift`
- `Domain/Models/VideoResource.swift`
- `Domain/Models/TKDForm.swift`
- `Domain/Models/BeltLevel.swift`
- `Domain/Models/DojangProfile.swift` — primary extensibility seam
- `Domain/Models/BeltSystemPreset.swift` — factory only, seeds built-in profiles
- `Domain/Models/SessionScope.swift` — UUID-based, serializable
- `Domain/Models/SessionOrder.swift`
- `Domain/Models/PracticeSession.swift`
- `Domain/Models/FormAttempt.swift` — SwiftData `@Model`
- `Domain/Preferences/TrainingProfile.swift`
- `Domain/Preferences/SessionDefaults.swift`
- `Domain/Preferences/PinnedForms.swift`
- `Domain/Preferences/OnboardingState.swift`
- `Data/DataSources/FormsDataSource.swift` — 29 forms, stable hardcoded UUIDs

---

### Step 2 — Filter and session services (TDD)
**Goal:** Pure business logic. Tests written first.

Files created:
- `PoomsaeFlowTests/FormFilterServiceTests.swift`
- `Domain/Services/FormFilterService.swift`
- `PoomsaeFlowTests/SessionBuilderTests.swift`
- `Domain/Services/SessionBuilder.swift` — sequential + shuffle-without-replacement

`FormFilterService` is completely profile-agnostic. A Sparta TKD "Orange Advanced" belt maps to `.yellow` canonical — sees exactly the same forms as Standard WT Yellow.

---

### Step 3 — SessionController (TDD)
**Goal:** All session state and outcome logic. Tests written first.

Files created:
- `PoomsaeFlowTests/SessionControllerTests.swift`
- `Domain/Controllers/SessionController.swift`

**Retry behavior:** Immediate repeat, not re-queue. `retryCount` tracks per-form retries. Index does not advance on retry. When the user finally passes, outcome is `.passedAfterRetry` if `retryCount > 0`, else `.passed`.

---

### Step 4 — Data layer
**Goal:** Protocol-driven repositories. Repository pattern isolates storage.

Files created:
- `Data/Repositories/FormRepository.swift` — protocol + implementation (UUID → `TKDForm` lookup)
- `Data/Repositories/UserPrefsRepository.swift` — reads/writes all five preference structs + `DojangProfile`
- `Data/Repositories/SessionRepository.swift` — **stub only** (protocol + empty implementations)

---

### Step 5 — ViewModels
**Goal:** Thin coordination layer. No business logic.

Files created:
- `ViewModels/HomeViewModel.swift`
- `ViewModels/SessionViewModel.swift` — delegates to `SessionController`, exposes derived state
- `ViewModels/FilterViewModel.swift` — **sheet-scoped**: created when the filter sheet opens, discarded on close; not a screen-scoped peer to `HomeViewModel`
- `Presentation/Onboarding/OnboardingFlowState.swift` — extracted into a separate `@Observable` class to enable unit testing of multi-step onboarding state independently of the view

---

### Step 6 — UI (inside-out)
**Goal:** Screens wired to ViewModels. No logic in views.

Build order (inner components first):
1. `BeltPickerView`
2. `FamilyPickerView`
3. `BeltSystemPickerView`
4. `WelcomeView`
5. `FormDetailView`
6. `SessionView`
7. `SessionConfigView`
8. `SessionCompleteView`
9. `HomeView`

---

## Key design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Retry behavior | Immediate repeat, index holds | Trains muscle memory on failed forms |
| Outcome ownership | Self-reported only | No computer grading in v1, v2, or v3 |
| Profile abstraction | `DojangProfile` is central | Primary extensibility seam for dojang-specific behavior |
| Scope serialization | UUID-based `SessionScope` | Serializable without embedding full `TKDForm` objects |
| Video model | `[VideoResource]` per form | Supports multiple sources (dojang + Kukkiwon fallback) |
| Form catalog | Static Swift array | Repository pattern means one-file migration to remote JSON |
| Session history | SwiftData `FormAttempt` | Powers v2 weakness engine — queries by form, date, outcome |
| Belt eligibility | `CanonicalBelt` enum | Profile-agnostic, no special-casing when switching profiles |
| User preferences | Five focused `Codable` structs | Avoids god object, each has its own `UserDefaults` key |
| Timestamps | `createdAt`/`updatedAt` on all persistent types | Schema consistency, required for `FormAttempt` immutability contract |
| Black belt gating | All nine forms flat at `.black` | Dan-level gating is v2; logged as known limitation |
| Dojang catalog gating | `DojangProfile.formIDs: Set<UUID>?` where `nil` = all forms | v1 sentinel meaning "no filter"; populated per-dojang in v1.1 |

---

## What is deliberately not built in v1

- `FormFilter` protocol / composable filters — two `.filter{}` calls suffice; extract when a third axis appears
- Identity/accounts — each device is its own isolated SwiftData store
- `OutcomeDetail` struct — `retryCount: Int` on `FormAttempt` is sufficient
- `queue: [UUID]` in `PracticeSession` — deferred until session restore is a real requirement
- Instructor mode, Android, shared backend — validate solo training loop first

---

## Form catalog — 29 forms

### Keecho (introducedAt: `.white`, family: `.keecho`)
| Form | Video |
|---|---|
| Keecho Il Jang | Sparta TKD YouTube |
| Keecho Ee Jang | Sparta TKD YouTube |
| Keecho Sam Jang | No video — not taught at Sparta TKD |

### Taegeuk (family: `.taegeuk`)
| Form | Belt introduced |
|---|---|
| Il Jang, Ee Jang | `.yellow` |
| Sam Jang, Sa Jang | `.green` |
| Oh Jang, Yuk Jang | `.blue` |
| Chil Jang, Pal Jang | `.red` |

### Palgwe (family: `.palgwe`)
Same belt introduction structure as Taegeuk. All Sparta TKD YouTube videos populated.

### Poom (family: `.poom`)
| Form | Notes |
|---|---|
| Hwarang (`.poom`) | PDF only on Sparta TKD site, videos = [] |

### Black belt (family: `.blackBelt`, all introducedAt: `.black`)
| Form | Video |
|---|---|
| Koryo, Keumgang, Taebaek, Pyongwon, Sipjin | Kukkiwon YouTube |
| Jitae, Cheonkwon, Hansu, Ilyo | videos = [] — **needs Kukkiwon URLs** |

**Known gap:** Jitae through Ilyo still need YouTube URLs — source from official Kukkiwon channel.

---

## Storage map

| Type | Storage | Notes |
|---|---|---|
| `FormAttempt` | SwiftData | Powers v2 weakness engine |
| `TrainingProfile` | UserDefaults | `com.ryan.PoomsaeFlow.trainingProfile` |
| `SessionDefaults` | UserDefaults | `com.ryan.PoomsaeFlow.sessionDefaults` |
| `PinnedForms` | UserDefaults | `com.ryan.PoomsaeFlow.pinnedForms` |
| `OnboardingState` | UserDefaults | `com.ryan.PoomsaeFlow.onboardingState` |
| `DojangProfile?` (activeProfile) | UserDefaults | `com.ryan.PoomsaeFlow.activeProfile` — stores full encoded value; preset factory not available at read time |
| `PracticeSession` | In-memory only | Built fresh each session, never persisted |
| `FormsDataSource` | Static / compile-time | 29 forms, stable hardcoded UUIDs |
| Belt presets | Static / compile-time | Seeded from `BeltSystemPreset.makeProfile()` |

---

## Version roadmap

| Version | Focus | Status |
|---|---|---|
| v1 | Solo training loop — core session experience | Complete ✅ |
| v1.1 | Dojang-specific form catalogs, Kukkiwon YouTube fallbacks for black belt forms | In progress |
| v2 | Weakness engine (frequency-weighted selection), stats view, custom dojang editor | Planned |
| v3+ | Validate before expanding — no instructor mode, no Android, no shared backend | Planned |

---

## Onboarding flow (4 screens)

1. **Welcome** — app value prop, three feature bullets, "Get started" CTA
2. **Belt system** — Standard WT (default) / Sparta TKD / Custom (coming soon)
3. **Your belt** — belt picker populated from chosen profile, shows form count per belt
4. **Your forms** — family toggles (Keecho on, Taegeuk on, Palgwe off, Poom off, Black belt off), live form count

After onboarding → Home screen. Belt card on Home is always tappable to re-enter belt/profile picker as a sheet.

---

## Pin affordance

Bookmark icon in the top-right of the session card. One tap pins/unpins — no navigation required. Filled amber bookmark = pinned. Outlined gray bookmark = unpinned. Brief toast confirms the action ("Pinned" / "Unpinned"). Haptic feedback on tap (`.impactOccurred()`). First session only: "Tap to pin" hint label appears below the icon, hidden after `OnboardingState.hasSeenPinHint` is set.

---

## Patterns to enforce

- Write tests for `FormFilterService` and `SessionBuilder` **before** implementing them
- Write tests for `SessionController` **before** implementing it
- `SessionRepository.save()` and `fetchHistory()` exist as stubs in v1 — do not implement
- `FormAttempt.userID` is always a local anonymous UUID in v1 — field must exist
- `BeltSystemPreset.custom` shows "coming soon" in UI — no implementation in v1
- All persistent types carry `createdAt` and `updatedAt`
- `ContentView` checks for `-uitesting` launch argument at startup and wipes `UserDefaults` — all UITest classes must pass this argument for clean test runs

## Patterns to avoid

- Do not use `@StateObject` or `@ObservableObject`
- Do not put `URLSession`, `UserDefaults`, or SwiftData calls in Views or ViewModels
- Do not hardcode YouTube URLs in Views — they come from `TKDForm.videos`
- Do not put business logic in `SessionViewModel` — it belongs in `SessionController`
- Do not use raw integers for belt comparison — always use `CanonicalBelt.order`
- Do not pass `TKDForm` objects into `SessionScope` — use UUIDs
- Do not reference `BeltSystemPreset` in service or presentation layers — use `DojangProfile`
