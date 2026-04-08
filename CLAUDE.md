# PoomsaeFlow

## Stack
- SwiftUI, iOS 17+, Xcode 16+
- @Observable macro (NOT ObservableObject / @Published)
- SwiftData for FormAttempt persistence
- No third-party dependencies

## Architecture
Four layers: Presentation → ViewModels+Controllers → Services → Repositories/DataSources
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
- UserPreferences is split into four Codable structs: TrainingProfile, SessionDefaults,
  PinnedForms, OnboardingState — all carry createdAt and updatedAt
- SessionScope carries UUIDs, not TKDForm objects — resolved by SessionBuilder via FormRepository
- TKDForm.videos is [VideoResource], not a single URL — supports multiple sources

## Patterns to enforce
- Write tests for FormFilterService and SessionBuilder BEFORE implementing them
- Write tests for SessionController BEFORE implementing it
- SessionRepository.save() and fetchHistory() exist as stubs in v1 — do not implement
- FormAttempt.userID is always a local anonymous UUID in v1 — field must exist
- BeltSystemPreset.custom shows "coming soon" in UI — no implementation in v1
- All persistent types carry createdAt and updatedAt

## Patterns to avoid
- Do not use @StateObject or @ObservableObject
- Do not put URLSession, UserDefaults, or SwiftData calls in Views or ViewModels
- Do not hardcode YouTube URLs in Views — they come from TKDForm.videos
- Do not put business logic in SessionViewModel — it belongs in SessionController
- Do not use raw integers for belt comparison — always use CanonicalBelt.order
- Do not pass TKDForm objects into SessionScope — use UUIDs
- Do not reference BeltSystemPreset in service or presentation layers — use DojangProfile
