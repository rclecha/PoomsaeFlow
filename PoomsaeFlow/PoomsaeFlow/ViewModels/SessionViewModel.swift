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

    var currentForm: TKDForm? { controller.currentForm }
    var progress: Double     { controller.progress }
    var isComplete: Bool     { controller.isComplete }
    var attempts: [FormAttempt] { controller.attempts }

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
    func userTappedPin() {
        guard let form = currentForm else { return }
        let stored = userPrefs.pinnedForms
        var ids = stored?.formIDs ?? []
        if let index = ids.firstIndex(of: form.id) {
            ids.remove(at: index)
        } else {
            ids.append(form.id)
        }
        let now = Date()
        userPrefs.save(PinnedForms(
            formIDs: ids,
            createdAt: stored?.createdAt ?? now,
            updatedAt: now
        ))
    }

    // MARK: - Private

    private func saveIfComplete() {
        guard controller.isComplete else { return }
        sessionRepo.save(controller.attempts)
    }
}
