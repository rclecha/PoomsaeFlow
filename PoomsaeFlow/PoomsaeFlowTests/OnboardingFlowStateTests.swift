import XCTest
@testable import PoomsaeFlow

/// Tests that OnboardingFlowState keeps selectedPreset and selectedProfile in sync.
///
/// Bug reproduced: when selectPreset(_:) was missing the `selectedProfile = preset.makeProfile()`
/// line, selectedProfile retained its default (spartaTKD) value while selectedPreset changed.
/// WelcomeView navigated to BeltPickerView immediately after onSelect fired, so the picker
/// received the stale default profile on first selection. Going back and reselecting worked
/// because selectedProfile was now non-nil from the first (silent) update.
@MainActor
final class OnboardingFlowStateTests: XCTestCase {

    // MARK: - selectPreset

    /// selectedProfile must reflect the chosen preset in the same synchronous call,
    /// because WelcomeView appends .belt to the navigation path immediately after
    /// selectPreset returns and the destination view reads selectedProfile before
    /// any further state propagation occurs.
    func test_selectPreset_profileIsUpdatedImmediately() {
        let state = OnboardingFlowState()                // default: spartaTKD
        let preset = BeltSystemPreset.worldTaekwondo

        state.selectPreset(preset)

        XCTAssertEqual(
            state.selectedProfile.id,
            preset.makeProfile().id,
            "selectedProfile.id must equal the chosen preset's profile id immediately after selectPreset(_:)"
        )
    }

    /// Choosing the same preset a second time leaves selectedProfile stable.
    func test_selectPreset_sameTwice_profileUnchanged() {
        let state = OnboardingFlowState(preset: .worldTaekwondo)
        let idBefore = state.selectedProfile.id

        state.selectPreset(.worldTaekwondo)

        XCTAssertEqual(state.selectedProfile.id, idBefore)
    }

    /// selectedPreset is updated alongside selectedProfile.
    func test_selectPreset_updatesSelectedPreset() {
        let state = OnboardingFlowState()
        state.selectPreset(.worldTaekwondo)
        XCTAssertEqual(state.selectedPreset, .worldTaekwondo)
    }

    // MARK: - init

    /// Default initialiser resolves profile from spartaTKD.
    func test_init_default_presetIsSpartaTKD() {
        let state = OnboardingFlowState()
        XCTAssertEqual(state.selectedPreset, .spartaTKD)
    }

    func test_init_default_profileMatchesPreset() {
        let state = OnboardingFlowState()
        XCTAssertEqual(state.selectedProfile.id, BeltSystemPreset.spartaTKD.makeProfile().id)
    }

    /// Custom init with a different preset resolves the correct profile.
    func test_init_customPreset_profileMatchesPreset() {
        let state = OnboardingFlowState(preset: .worldTaekwondo)
        XCTAssertEqual(state.selectedProfile.id, BeltSystemPreset.worldTaekwondo.makeProfile().id)
    }
}
