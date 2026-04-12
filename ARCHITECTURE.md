# PoomsaeFlow — Architecture Diagrams

## Layer architecture

```mermaid
graph TD
    subgraph Presentation["Presentation Layer"]
        WV[WelcomeView]
        BSP[BeltSystemPickerView]
        BP[BeltPickerView]
        FP[FamilyPickerView]
        HV[HomeView]
        SCV[SessionConfigView]
        SV[SessionView]
        SCO[SessionCompleteView]
        FDV[FormDetailView]
    end

    subgraph VMC["ViewModels + Controllers"]
        HVM[HomeViewModel]
        SVM[SessionViewModel]
        FVM[FilterViewModel]
        SC[SessionController]
        OFS[OnboardingFlowState]
    end

    subgraph Domain["Domain Layer"]
        FFS[FormFilterService]
        SB[SessionBuilder]
        subgraph Models["Models"]
            CB[CanonicalBelt]
            DP[DojangProfile]
            TF[TKDForm]
            PS[PracticeSession]
            FA[FormAttempt]
        end
    end

    subgraph Repos["Repositories"]
        FR[FormRepository]
        UPR[UserPrefsRepository]
        SR[SessionRepository stub — both methods no-ops, full SwiftData impl is v2]
    end

    subgraph External["External / Data Sources"]
        FDS[FormsDataSource static]
        UD[UserDefaults]
        SD[SwiftData]
        YT[YouTube / Safari]
    end

    Presentation --> VMC
    VMC --> Domain
    Domain --> Repos
    Repos --> External
```

---

## Session state machine

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Configuring : user taps Start
    Configuring --> Active : session built by SessionBuilder
    Active --> Active : Retry — index holds, retryCount++
    Active --> Active : Skip — index advances, outcome = skipped
    Active --> Active : Nailed it — index advances, outcome = passed / passedAfterRetry
    Active --> Complete : currentIndex >= queue.count
    Complete --> Idle : Done
    Complete --> Active : Go again — new session built
```

---

## Data flow — session lifecycle

```mermaid
sequenceDiagram
    participant User
    participant SessionViewModel
    participant HomeViewModel
    participant SessionController
    participant SessionBuilder
    participant FormRepository
    participant SessionRepository

    User->>SessionViewModel: taps Start
    SessionViewModel->>HomeViewModel: buildSession()
    HomeViewModel->>SessionBuilder: build(scope, order, belt, profile)
    SessionBuilder->>FormRepository: resolve(UUIDs)
    FormRepository-->>SessionBuilder: [TKDForm]
    SessionBuilder-->>HomeViewModel: PracticeSession
    HomeViewModel->>SessionController: init(session)
    HomeViewModel-->>SessionViewModel: SessionController

    loop Per form
        User->>SessionViewModel: userTappedRetry()
        SessionViewModel->>SessionController: recordOutcome(.retry)
        Note over SessionController: retryCount++, index holds

        User->>SessionViewModel: userTappedNailed()
        SessionViewModel->>SessionController: recordOutcome(.passed)
        Note over SessionController: resolves to .passedAfterRetry if retryCount > 0
        SessionController-->>SessionViewModel: index advances
    end

    SessionController-->>SessionViewModel: isComplete = true
    SessionViewModel->>SessionRepository: save(attempts)
```

---

## Belt eligibility — CanonicalBelt mapping

```mermaid
graph LR
    subgraph SpartaTKD["Sparta TKD belts"]
        W[White]
        Y[Yellow]
        YA[Yellow Advanced]
        O[Orange]
        OA[Orange Advanced]
        G[Green]
        GA[Green Advanced]
        B[Blue]
        BA[Blue Advanced]
        R[Red]
        RA[Red Advanced]
        P[Poom]
        BK[Black]
    end

    subgraph Canonical["CanonicalBelt"]
        CW[.white]
        CY[.yellow]
        CG[.green]
        CB[.blue]
        CR[.red]
        CP[.poom]
        CBK[.black]
    end

    W --> CW
    Y --> CY
    YA --> CY
    O --> CY
    OA --> CY
    G --> CG
    GA --> CG
    B --> CB
    BA --> CB
    R --> CR
    RA --> CR
    P --> CP
    BK --> CBK
```

---

## File structure

```
PoomsaeFlow/
├── App/
│   └── PoomsaeFlowApp.swift
├── ContentView.swift                          ← composition root — instantiates concrete repos,
│                                                wires ViewModels, handles -uitesting flag
├── Domain/
│   ├── Models/
│   │   ├── CanonicalBelt.swift
│   │   ├── BeltLevel.swift
│   │   ├── BeltSystemPreset.swift
│   │   ├── DojangProfile.swift
│   │   ├── TKDForm.swift
│   │   ├── VideoResource.swift
│   │   ├── FormFamily.swift
│   │   ├── PracticeSession.swift
│   │   ├── SessionScope.swift
│   │   ├── SessionOrder.swift
│   │   └── FormAttempt.swift
│   ├── Preferences/
│   │   ├── TrainingProfile.swift
│   │   ├── SessionDefaults.swift
│   │   ├── PinnedForms.swift
│   │   └── OnboardingState.swift
│   ├── Services/
│   │   ├── FormFilterService.swift
│   │   └── SessionBuilder.swift
│   └── Controllers/
│       └── SessionController.swift
├── Data/
│   ├── Repositories/
│   │   ├── FormRepository.swift
│   │   ├── UserPrefsRepository.swift
│   │   └── SessionRepository.swift
│   └── DataSources/
│       └── FormsDataSource.swift
├── Presentation/
│   ├── Common/
│   │   └── Color+Hex.swift
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── BeltSystemPickerView.swift
│   │   ├── BeltPickerView.swift
│   │   ├── FamilyPickerView.swift
│   │   └── OnboardingFlowState.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Session/
│   │   ├── SessionConfigView.swift
│   │   ├── SessionView.swift
│   │   └── SessionCompleteView.swift
│   └── FormDetail/
│       └── FormDetailView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── SessionViewModel.swift
│   └── FilterViewModel.swift
├── Resources/
│   └── Assets.xcassets
├── PoomsaeFlowTests/
│   ├── FormFilterServiceTests.swift
│   ├── SessionBuilderTests.swift
│   ├── SessionControllerTests.swift
│   ├── HomeViewModelTests.swift
│   └── OnboardingFlowStateTests.swift
└── PoomsaeFlowUITests/
    ├── AppLaunchTests.swift
    ├── OnboardingUITests.swift
    ├── PinnedFormsUITests.swift           ← intentionally failing — documents known bug
    └── XCUIApplication+Helpers.swift
```

---

## Build order (Step 1 → 6) — Historical, v1 complete

```mermaid
gantt
    title PoomsaeFlow — Build sequence
    dateFormat X
    axisFormat Step %s

    section Step 1
    Core models + FormsDataSource    :s1, 0, 1

    section Step 2
    FormFilterService (TDD)          :s2, 1, 2
    SessionBuilder (TDD)             :s2b, 1, 2

    section Step 3
    SessionController (TDD)          :s3, 2, 3

    section Step 4
    FormRepository                   :s4, 3, 4
    UserPrefsRepository              :s4b, 3, 4
    SessionRepository stub           :s4c, 3, 4

    section Step 5
    HomeViewModel                    :s5, 4, 5
    SessionViewModel                 :s5b, 4, 5
    FilterViewModel                  :s5c, 4, 5

    section Step 6
    UI — inside-out                  :s6, 5, 6
```

---

## DojangProfile — form catalog gating

`DojangProfile.formIDs` is `Set<UUID>?`:
- `nil` — no filter, all catalog forms are visible (Standard WT behavior in v1)
- non-nil `Set` — only the listed UUIDs are eligible; membership tests dominate over iteration, which is why `Set` is used over `Array`
- empty `Set` — no forms visible (different from `nil`; do not conflate the two)

This nil-as-sentinel is the gating mechanism for v1.1 dojang-specific catalogs. When building a `DojangProfile` for a dojang that teaches all WT forms, set `formIDs` to `nil`, not to a full set of all UUIDs.

---

## Accessibility identifier convention

Pattern: `<context>_<element_type>_<value>`

Examples:
- `belt_system_row_spartaTKD`
- `belt_row_White`
- `belt_form_row`
- `pin_button`

All UITest queries use this convention. Apply it to any new identifiers added for v1.1 UITests.
