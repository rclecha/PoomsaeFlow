import Foundation

/// Accumulates the user's selections across the multi-step onboarding flow.
///
/// Extracted from WelcomeView so the preset → profile coupling can be unit-tested
/// independently of SwiftUI's state-batching and navigation lifecycle.
@Observable
final class OnboardingFlowState {
    private(set) var selectedPreset: BeltSystemPreset
    private(set) var selectedProfile: DojangProfile

    init(preset: BeltSystemPreset = .spartaTKD) {
        self.selectedPreset = preset
        self.selectedProfile = preset.makeProfile()
    }

    /// Updates both the selected preset and its resolved profile atomically.
    ///
    /// Both must change together — callers navigate to the belt picker immediately
    /// after this returns, and `selectedProfile` must be current before that view appears.
    func selectPreset(_ preset: BeltSystemPreset) {
        selectedPreset = preset
        selectedProfile = preset.makeProfile()
    }
}
