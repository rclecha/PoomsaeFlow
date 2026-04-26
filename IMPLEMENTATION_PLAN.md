# PoomsaeFlow — Implementation Plan

## Project overview

Personal iOS poomsae training companion. SwiftUI, iOS 17+, SwiftData, no third-party dependencies. Public GitHub repo. Built with Claude Code as an AI-assisted development portfolio project.

**Author:** Ryan  
**Dojang:** Sparta TKD, Walnut Creek CA  
**Stack:** SwiftUI · iOS 17+ · Xcode 16+ · SwiftData  
**CI:** GitHub Actions (macos-26, unit tests on push to main and every PR)  

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
| `anonymousUserID` | UserDefaults | `com.ryan.PoomsaeFlow.anonymousUserID` — stable per-device UUID generated by `AnonymousIdentityProvider` on first access; used as `FormAttempt.userID` |
| `PracticeSession` | In-memory only | Built fresh each session, never persisted |
| `FormsDataSource` | Static / compile-time | 29 forms, stable hardcoded UUIDs |
| Belt presets | Static / compile-time | Seeded from `BeltSystemPreset.makeProfile()` |

---

## Version roadmap

| Version | Focus | Status |
|---|---|---|
| v1 | Solo training loop — core session experience | Complete ✅ |
| v1.1 | Dojang-specific form catalogs, Kukkiwon YouTube fallbacks for black belt forms | Complete ✅ |
| v1.2 | Pinned Forms practice sessions, PinnedFormsView hub screen, bidirectional FormBrowserView | Complete ✅ |
| v1.3 | Session UX (retry badge, shake, haptic), home nav refactor, CI pipeline, summary bug fixes | Complete ✅ |
| v1.4 | CD pipeline — automated TestFlight builds on every merge to main | Complete ✅ |
| v1.5 | Coverage reporting (job summary, 81.0%), 72 new unit tests (164 total), refactor audit + apply, Hwarang bug fix | Complete ✅ |
| v1.6 | Verify Taegeuk Sa Jang in WT green belt preset; poom belt split color (secondaryColorHex + rendering) | Planned |
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

---

## v1.3 — Session UX + bug fixes

### Bug fixes

**`SessionCompleteView.retriedCount`** — changed from `filter { retryCount > 0 }.count` (number of forms that had any retry) to `reduce(0) { $0 + $1.retryCount }` (total retry taps across all forms). Label renamed from "Needed retries" to "Retry attempts".

**`SessionCompleteView.nailedCount`** — changed from `outcome == .passed` to `outcome == .passed || outcome == .passedAfterRetry`. Forms retried then nailed were previously excluded from the "Nailed it" row.

### Session screen UX

**Retry badge** — amber pill overlay (top-trailing) on the form card. Shows "↺ 1 retry" / "↺ N retries" while `currentFormRetryCount > 0`. State is local to `SessionView` (`@State private var currentFormRetryCount`), not read from `SessionController`, and resets to 0 when advancing to the next form via Skip or Nailed it.

**ShakeEffect** — new `GeometryEffect` at `Presentation/Shared/ShakeEffect.swift`. Applied to the form card via `.modifier(ShakeEffect(animatableData: shakeCount))`. `shakeCount` is incremented on each Retry tap and reset on form advance.

**Haptic** — `UIImpactFeedbackGenerator(style: .light).impactOccurred()` fires on every Retry tap.

### Home screen navigation

Removed the top-right toolbar play button. The Full Set card (`SessionTypeCard`) now sets `showSessionConfig = true` on tap, opening `SessionConfigView` directly. The card was already wired to `selectedScope = .fullSet`; adding the config sheet presentation completes the entry point. Pinned Forms and Belt Forms entry points unchanged.

### CI / CD

GitHub Actions workflow on `macos-26`. Unit tests run on every push to `main` and every PR (~5 min). Per-file code coverage printed to the run log via `xcrun xccov`. CD workflow triggers after CI passes but is blocked on provisioning — Automatic signing fails on a fresh runner. Fix deferred to v1.4: export `.p12` + provisioning profile, store as GitHub Secrets, switch to `CODE_SIGN_STYLE=Manual`.

### New tests (86 total, up from 73)

- `SessionCompleteViewTests` — `test_retriedCount_sumsAllRetryTaps`, `test_nailedCount_includesPassedAfterRetry`
- `SessionUITests` — `test_fullSetCard_opensSessionSetup`, `test_homeScreen_hasNoPlayButtonInToolbar`

---

## v1.4 — CD pipeline

CD pipeline fully operational. Manual signing replaces Automatic signing, which fails on headless runners with "No Account for Team".

### Signing setup

Distribution certificate (`.p12`) and provisioning profile stored as GitHub Secrets (`DISTRIBUTION_CERTIFICATE_P12`, `DISTRIBUTION_CERTIFICATE_PASSWORD`, `PROVISIONING_PROFILE`). The "Import Distribution Certificate" step creates a temporary keychain, imports the cert, grants codesign partition access, and exports `KEYCHAIN_PATH`/`KEYCHAIN_PASSWORD` to `$GITHUB_ENV` for use in the archive step.

### xcodebuild flags

`CODE_SIGN_STYLE=Manual`, `CODE_SIGN_IDENTITY="Apple Distribution: Ryan Lecha (57UUVGRX22)"`, `PROVISIONING_PROFILE=$PROFILE_UUID` (UUID extracted from the installed profile at runtime).

### ExportOptions.plist

`method: app-store-connect`, `signingStyle: manual`, `provisioningProfiles` dict keyed by bundle ID `com.ryan.PoomsaeFlow`.

### Trigger

Fires after CI passes (`workflow_run` on CI completion, gated on `conclusion == 'success'`). Annual secret rotation required: certificate and profile expire April 2027 — see CLAUDE.md for rotation steps.

---

## v1.5 — Coverage, tests, and refactors

### Coverage reporting
Code coverage now posts to the GitHub Actions job summary on every CI run via `xcrun xccov` + a Python 3 parsing step. Coverage filter excludes View files, App file, test files, Helpers, and ShakeEffect. Overall logic-layer coverage: **81.0%**.

### New unit tests (164 total, up from 86)
72 new tests across six new test files plus extensions to `HomeViewModelTests`:

| File | Coverage area |
|---|---|
| `FormFamilyTests` | `FormFamily.displayName`, `allCases`, Codable |
| `FormsDataSourceTests` | Catalog count, family distribution, UUID uniqueness, video completeness |
| `FormRepositoryTests` | `all`, `forms(for:)` — empty, valid, mixed, unknown IDs |
| `PracticeSessionTests` | `isComplete`, `currentForm` — boundary conditions |
| `PinnedFormsTests` | `adding`, `removing`, `removingAll`, `reordering`, Codable |
| `UserPrefsRepositoryTests` | nil before first save, round-trips, overwrite, corrupted data |
| `HomeViewModelTests` extensions | Pin mutations, `buildSession`, `eligibleForms` |

`DefaultUserPrefsRepository` gained `init(defaults: UserDefaults)` to enable test injection without touching the production `UserDefaults.standard` suite.

### Refactors applied
- `TransientOutcome` extracted from `AttemptOutcome` — transient (`.retry`, `.passed`, `.skipped`) and persistent (`.passed`, `.passedAfterRetry`, `.skipped`) outcomes are now separate types; `SessionController.recordOutcome(_:)` accepts `TransientOutcome`
- `UserIdentityProvider` protocol + `AnonymousIdentityProvider` added (`Data/Repositories/UserIdentityProvider.swift`); `SessionController.userID` is injected via `init(session:userID:)` rather than generated inline — zero callsite changes in production, test isolation via the new overload
- `SessionController.isComplete` and `currentForm` delegate to `PracticeSession`; duplicate bounds logic and private `[safe:]` subscript removed
- `SessionViewModel.userTappedPin` routes through `PinnedForms.adding`/`removing`; `retryCount` forwarding property added
- `PinnedForms.empty` static var and `removingAll(_:)` single-pass batch removal added; `HomeViewModel.confirmSchoolSwitch` uses `removingAll`
- `HomeViewModel`: `formsByID` computed property and `makeTrainingProfile(belt:)` extracted — eliminates two duplicate `Dictionary(uniqueKeysWithValues:)` constructions and one duplicated `TrainingProfile` construction
- `BeltSystemPreset.spartaFormIDs` now references `FormsDataSource.FormID` constants — compile-time UUID safety; `FormsDataSource.FormID` promoted from `private` to `internal`
- `precondition` guard in `HomeViewModel.init` prevents crash if a custom profile (zero belt levels) is ever stored as the active profile
- `DefaultUserPrefsRepository`: `encoder`/`decoder` promoted to `private static let`; `FormRepository.forms(for:)` uses `self.all`; `SessionBuilder.familyRank` promoted to `private static let`

### Bug fixed
`BeltSystemPreset.spartaFormIDs` previously included Hwarang via a silently wrong raw UUID literal. Hwarang is not taught at Sparta TKD. Now correctly excluded. Sparta TKD catalog: **27 forms** (2 Keecho + 8 Taegeuk + 8 Palgwe + 9 Black Belt). Switching `spartaFormIDs` to `FormsDataSource.FormID` constants prevents this class of bug going forward.

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
