# PoomsaeFlow

## Stack
- SwiftUI, iOS 17+, Xcode 16+
- @Observable macro (NOT ObservableObject / @Published)
- SwiftData for FormAttempt persistence
- No third-party dependencies

## Architecture
Four layers: Presentation → ViewModels+Controllers → Domain → Repositories/DataSources
- Views hold zero business logic — only bindings and layout only
- SessionController owns all mutable session state and outcome logic
- SessionViewModel is thin — translates taps into controller calls, exposes derived state
- FormFilterService and SessionBuilder are pure functions — no side effects
- All repositories are protocol-driven for testability

## Core types
- CanonicalBelt: source of truth for form eligibility across all dojang profiles
- TKDForm.introducedAt is CanonicalBelt — never a raw integer
- BeltLevel.canonical maps any dojang-specific belt to CanonicalBelt
- DojangProfile owns both the belt ladder and the form catalog — primary extensibility seam
- BeltSystemPreset is a factory enum only — call makeProfile() to get a DojangProfile
- UserPreferences is split into five Codable structs: TrainingProfile, SessionDefaults,
  PinnedForms, OnboardingState, and activeProfile: DojangProfile? — all carry createdAt
  and updatedAt. activeProfile stores the full DojangProfile value (not just an ID)
  because the preset factory is not available at decode time.
- SessionScope carries UUIDs, not TKDForm objects — resolved by SessionBuilder via FormRepository
- TKDForm.videos is [VideoResource], not a single URL — supports multiple sources

## Patterns to enforce
- Write tests for FormFilterService and SessionBuilder BEFORE implementing them
- Write tests for SessionController BEFORE implementing it
- FormAttempt.userID is always a local anonymous UUID in v1 — field must exist
- All persistent types carry createdAt and updatedAt

## Patterns to avoid
- Do not use @StateObject or @ObservableObject
- Do not put URLSession, UserDefaults, or SwiftData calls in Views or ViewModels
- Do not hardcode YouTube URLs in Views — they come from TKDForm.videos
- Do not put business logic in SessionViewModel — it belongs in SessionController
- Do not use raw integers for belt comparison — always use CanonicalBelt.order
- Do not pass TKDForm objects into SessionScope — use UUIDs
- Do not reference BeltSystemPreset in service or presentation layers — use DojangProfile
- Do not implement SessionRepository.save() or fetchHistory() — they are v1 stubs (see v1 intentional stubs below)

## Composition root
Concrete repos are instantiated in ContentView. All new repos and ViewModels must be
wired there. Do not instantiate repos in Views or ViewModels.

## UITest patterns
- All UITest classes must launch with app.launchArguments = ["-uitesting"] — ContentView
  checks this flag and wipes UserDefaults for a clean test state
- Accessibility identifier convention: <context>_<element_type>_<value> — e.g.
  belt_system_row_spartaTKD, belt_row_White, pin_button
- PinnedFormsUITests intentionally has failing tests — they document a known bug where
  pin state does not update the Pinned card subtitle in real time. Do not delete them.

## @Observable patterns
- All observable classes are final class
- reloadPinnedForms() is called explicitly from HomeView.onChange(of:) after a session
  ends — this is intentional design, not dead code or a bug. The ViewModel does not
  observe session state directly.
- FilterViewModel is sheet-scoped — instantiate it in the sheet, not at screen scope.
  It is created when the filter sheet opens and discarded when it closes.
- Multi-step state accumulation should be extracted to a separate @Observable class
  (see OnboardingFlowState) so it can be unit tested independently of the view

## Core type notes
- DojangProfile.formIDs is Set<UUID>? — nil means "all catalog forms, no filter."
  An empty Set means "no forms visible." Never set formIDs to an empty set when you
  mean all forms. This distinction is critical for v1.1 dojang catalog work.

## v1 intentional stubs — do not implement
These are deliberately incomplete in v1. Do not implement them unless explicitly
scoped for v2:
- SessionRepository.save() and SessionRepository.fetchHistory() — no-op stubs, full
  SwiftData implementation is v2
- BeltSystemPreset.custom — shows "coming soon," no implementation in v1
- Dan-level gating within .black — all nine black belt forms visible to any black belt
  in v1; per-dan gating is v2

## v1.1 scope (shipped)
- Dojang-specific catalogs (major — touches data model, onboarding, new UI surface —
  plan carefully before implementing)
- Kukkiwon YouTube fallbacks for Jitae, Cheonkwon, Hansu, Ilyo
- Expanded UITest suite

## v1.2 scope (shipped)
- Pinned Forms made fully functional for practice sessions via a bottom toolbar
  "Start session" button triggering SessionConfigView
- PinnedFormsView redesigned as a hub screen (navigate from HomeView, practice or
  manage from within)
- FormBrowserView made bidirectional — tapping a pinned form unpins it
- Start session button disabled in edit mode and when no forms are pinned
- EditButton() replaced with manual editMode state (unreliable on device in iOS 26)
- 73 tests passing (up from 71)

## v1.3 scope (shipped)
- SessionCompleteView: retriedCount now sums total retry taps across all attempts
  (reduce over retryCount) — label renamed from "Needed retries" to "Retry attempts"
- SessionCompleteView: nailedCount now includes .passedAfterRetry — forms retried
  then nailed were previously uncounted
- Session screen: amber retry badge (top-trailing overlay) shows "↺ N retry/retries"
  when the current form has been retried one or more times
- Session screen: card shakes on each Retry tap via ShakeEffect (GeometryEffect);
  haptic (.light) fires on every Retry tap; badge and shake state reset on advance
- Home screen: Full Set card is now tappable and navigates to Session Setup; toolbar
  play button removed
- New file: PoomsaeFlow/Presentation/Shared/ShakeEffect.swift
- CI pipeline shipped: GitHub Actions on macos-26, unit tests on every push to main
  and every PR (~5m runs), per-file code coverage via xcrun xccov
- CD pipeline wired but blocked on Manual signing — fix deferred to v1.4
- 86 tests passing (up from 73)

## v1.4 scope (shipped)
- CD pipeline fully operational: Manual signing with .p12 + provisioning profile stored
  as GitHub Secrets (CODE_SIGN_STYLE=Manual), TestFlight upload on every merge to main,
  first build installed on device

## v1.5 scope (planned)
- PR coverage comments: post xcrun xccov summary as a comment on each PR
  (coverage.json already generated by CI; needs a posting step)
- Coverage audit: report only — identify gaps in unit test coverage
- Add missing tests: address gaps found in coverage audit
- Refactor audit: report only — identify structural improvements
- Apply refactors: human review gate required before this step proceeds

## CD Pipeline — Annual Maintenance

The following secrets expire annually and must be rotated before the CD pipeline will work:

- **DISTRIBUTION_CERTIFICATE_P12** and **DISTRIBUTION_CERTIFICATE_PASSWORD** — expires ~April 2027.
  To rotate: open Keychain Access → My Certificates → export new Apple Distribution .p12 → base64 encode → update GitHub Secrets.
- **PROVISIONING_PROFILE** — expires 2027/04/25.
  To rotate: developer.apple.com → Profiles → regenerate "PoomsaeFlow iOS AppStore Distribution" → download → base64 encode → update GitHub Secret.

Set a calendar reminder for March 2027 to rotate both before they expire.

## v2 scope (do not build yet)
- Weakness engine
- Stats view
- Custom dojang editor
- Full SwiftData SessionRepository implementation
