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
        SR[SessionRepository stub]
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
    participant SessionController
    participant SessionBuilder
    participant FormRepository
    participant SessionRepository

    User->>SessionViewModel: taps Start
    SessionViewModel->>SessionBuilder: build(scope, order, belt, profile)
    SessionBuilder->>FormRepository: resolve(UUIDs)
    FormRepository-->>SessionBuilder: [TKDForm]
    SessionBuilder-->>SessionViewModel: PracticeSession
    SessionViewModel->>SessionController: init(session)

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
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── BeltSystemPickerView.swift
│   │   ├── BeltPickerView.swift
│   │   └── FamilyPickerView.swift
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
└── Tests/
    ├── FormFilterServiceTests.swift
    ├── SessionBuilderTests.swift
    └── SessionControllerTests.swift
```

---

## Build order (Step 1 → 6)

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
