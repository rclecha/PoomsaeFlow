import SwiftUI

/// Manages the full onboarding flow: Welcome → School → Belt → Families → done.
///
/// All navigation state is private. The parent receives a single `onComplete` callback
/// and never needs to know which step the user is on — it only cares that onboarding
/// finished and preferences were written.
struct WelcomeView: View {
    let userPrefs: UserPrefsRepository
    let formRepo: FormRepository
    let onComplete: () -> Void

    // MARK: - Navigation

    private enum Step: Hashable {
        case beltSystem
        case belt
        case family
    }

    @State private var path: [Step] = []

    // MARK: - Onboarding selections (accumulated across steps)

    @State private var flowState = OnboardingFlowState()
    @State private var selectedBelt: BeltLevel? = nil
    @State private var enabledFamilies: [FormFamily] = FormFamily.allCases

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            welcomeScreen
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .beltSystem: beltSystemStep
                    case .belt:       beltStep
                    case .family:     familyStep
                    }
                }
        }
    }

    // MARK: - Steps

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("PoomsaeFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 14) {
                    FeatureBullet(text: "Practice the right forms for your belt")
                    FeatureBullet(text: "Track what you nail, retry what you don't")
                    FeatureBullet(text: "Pin tricky forms to focus your training")
                }
            }

            Spacer()

            Button {
                path.append(.beltSystem)
            } label: {
                Text("Get started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(32)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var beltSystemStep: some View {
        BeltSystemPickerView(selectedPreset: flowState.selectedPreset) { preset in
            flowState.selectPreset(preset)
            path.append(.belt)
        }
    }

    private var beltStep: some View {
        BeltPickerView(profile: flowState.selectedProfile, selectedBeltID: selectedBelt?.id) { belt in
            selectedBelt = belt
            path.append(.family)
        }
    }

    private var familyStep: some View {
        Group {
            if let belt = selectedBelt {
                let count = FormFilterService.eligibleForms(
                    userBelt: belt,
                    profile: flowState.selectedProfile,
                    allForms: formRepo.all,
                    enabledFamilies: enabledFamilies
                ).count

                Form {
                    FamilyPickerView(enabledFamilies: $enabledFamilies, formCount: count)
                }
                .navigationTitle("Form Families")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            finish(profile: flowState.selectedProfile, belt: belt)
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Completion

    private func finish(profile: DojangProfile, belt: BeltLevel) {
        let now = Date()
        userPrefs.save(profile)
        userPrefs.save(TrainingProfile(
            selectedProfileID: profile.id,
            selectedBeltLevelID: belt.id,
            createdAt: now,
            updatedAt: now
        ))
        userPrefs.save(SessionDefaults(
            defaultOrder: .sequential,
            enabledFamilies: enabledFamilies,
            createdAt: now,
            updatedAt: now
        ))
        userPrefs.save(OnboardingState(
            isOnboarded: true,
            hasSeenPinHint: false,
            createdAt: now,
            updatedAt: now
        ))
        onComplete()
    }
}

// MARK: - FeatureBullet

private struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
            Text(text)
        }
    }
}
