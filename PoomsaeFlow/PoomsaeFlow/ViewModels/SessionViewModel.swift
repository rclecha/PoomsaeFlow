import Foundation
import Observation

/// Thin translation layer between session views and SessionController.
///
/// Contains no outcome logic — that lives entirely in SessionController. This type exists
/// so that session views bind to a single @Observable object rather than holding direct
/// references to a controller and two repositories with different lifetimes. If any method
/// here grows beyond one line of delegation, the logic belongs in SessionController instead.
@Observable
final class SessionViewModel {

    // MARK: - Dependencies

    private let controller: SessionController
    private let sessionRepo: SessionRepository
    private let userPrefs: UserPrefsRepository

    // MARK: - Derived State

    var currentForm: TKDForm?    { controller.currentForm }
    var progress: Double          { controller.progress }
    var isComplete: Bool          { controller.isComplete }
    var attempts: [FormAttempt]   { controller.attempts }
    var currentIndex: Int         { controller.session.currentIndex }
    var queueCount: Int           { controller.session.queue.count }
    var retryCount: Int           { controller.retryCount }

    /// True when the current form's ID is in the stored pinned set.
    /// Reads `userPrefs` directly so the value reflects any pin toggle without
    /// requiring HomeViewModel to propagate a refresh.
    var isCurrentFormPinned: Bool {
        guard let form = currentForm else { return false }
        return userPrefs.pinnedForms?.formIDs.contains(form.id) ?? false
    }

    // MARK: - Init

    init(
        controller: SessionController,
        sessionRepo: SessionRepository,
        userPrefs: UserPrefsRepository
    ) {
        self.controller = controller
        self.sessionRepo = sessionRepo
        self.userPrefs = userPrefs
    }

    // MARK: - User Actions

    func userTappedNailed() {
        controller.recordOutcome(.passed)
        saveIfComplete()
    }

    func userTappedRetry() {
        // .retry is non-terminal — the form stays current, nothing to persist yet
        controller.recordOutcome(.retry)
    }

    func userTappedSkip() {
        controller.recordOutcome(.skipped)
        saveIfComplete()
    }

    /// Toggles the pin state of the currently displayed form and persists the updated set.
    /// Also marks `hasSeenPinHint = true` on the first interaction so the tutorial
    /// hint never appears again after the user has discovered the feature.
    func userTappedPin() {
        guard let form = currentForm else { return }
        let stored = userPrefs.pinnedForms ?? .empty
        let updated = stored.formIDs.contains(form.id)
            ? stored.removing(form.id)
            : stored.adding(form.id)
        userPrefs.save(updated)
        if let onboarding = userPrefs.onboardingState, !onboarding.hasSeenPinHint {
            let now = Date()
            userPrefs.save(OnboardingState(
                isOnboarded: onboarding.isOnboarded,
                hasSeenPinHint: true,
                createdAt: onboarding.createdAt,
                updatedAt: now
            ))
        }
    }

    // MARK: - Private

    private func saveIfComplete() {
        guard controller.isComplete else { return }
        sessionRepo.save(controller.attempts)
    }
}
