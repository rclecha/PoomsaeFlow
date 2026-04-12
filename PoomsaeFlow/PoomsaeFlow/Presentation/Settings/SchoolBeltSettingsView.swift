import SwiftUI

/// Settings sheet for changing the active school and belt.
///
/// Mirrors the onboarding school→belt flow (Welcome step omitted). Reuses the existing
/// `BeltSystemPickerView` and `BeltPickerView` so the two flows stay visually consistent.
/// All profile writes route through `homeVM.switchProfile(profile:belt:)` — never directly
/// to UserPrefsRepository — so orphan detection and the single write-path invariant are
/// always enforced.
struct SchoolBeltSettingsView: View {
    var homeVM: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    private enum Step: Hashable {
        case belt
    }

    @State private var path: [Step] = []
    @State private var flowState: OnboardingFlowState
    @State private var showOrphanWarning = false

    init(homeVM: HomeViewModel) {
        self.homeVM = homeVM
        // Seed the picker to reflect the user's current school selection.
        // OnboardingFlowState.init() defaults to .spartaTKD; we override it here
        // so the checkmark lands on the actual current profile when the sheet opens.
        // BeltSystemPreset is looked up by matching the stored profile ID — if no match
        // is found (e.g. a future custom profile), we fall back to .spartaTKD.
        let currentPreset = BeltSystemPreset.allCases.first {
            $0.makeProfile().id == homeVM.activeProfile.id
        } ?? .spartaTKD
        _flowState = State(initialValue: OnboardingFlowState(preset: currentPreset))
    }

    var body: some View {
        NavigationStack(path: $path) {
            BeltSystemPickerView(selectedPreset: flowState.selectedPreset) { preset in
                flowState.selectPreset(preset)
                path.append(.belt)
            }
            .navigationDestination(for: Step.self) { _ in
                BeltPickerView(
                    profile: flowState.selectedProfile,
                    selectedBeltID: nil
                ) { belt in
                    homeVM.switchProfile(profile: flowState.selectedProfile, belt: belt)
                    if homeVM.pendingSchoolSwitch != nil {
                        // Pop back to the school picker root before presenting the dialog.
                        // SwiftUI batches both mutations into a single render pass, so the
                        // dialog presents on BeltSystemPickerView (the now-visible root)
                        // rather than on an obscured navigation destination.
                        path = []
                        showOrphanWarning = true
                    } else {
                        dismiss()
                    }
                }
            }
            // Use .alert rather than .confirmationDialog — on iOS 26, confirmationDialog
            // is rendered as a SwiftUI-native component whose buttons are not reliably
            // surfaced in the XCTest accessibility tree. Alert buttons are consistently
            // accessible via app.buttons["label"] across all iOS versions.
            .alert(
                orphanDialogTitle,
                isPresented: $showOrphanWarning
            ) {
                Button("Switch School", role: .destructive) {
                    homeVM.confirmSchoolSwitch()
                    dismiss()
                }

                Button("Keep Current School", role: .cancel) {
                    homeVM.cancelSchoolSwitch()
                }
            } message: {
                Text(orphanDialogMessage)
            }
        }
        .accessibilityIdentifier("settings_sheet")
    }

    // MARK: - Dialog strings

    private var orphanDialogTitle: String {
        let count = homeVM.pendingSchoolSwitch?.orphanedForms.count ?? 0
        return "Switching schools will remove \(count) pinned \(count == 1 ? "form" : "forms")"
    }

    private var orphanDialogMessage: String {
        let names = homeVM.pendingSchoolSwitch?.orphanedForms.map(\.name) ?? []
        return names.joined(separator: ", ")
    }
}
