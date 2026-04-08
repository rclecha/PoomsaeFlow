import SwiftUI

/// Root view: checks onboarding state and routes to WelcomeView or HomeView.
///
/// Dependencies are created here (the composition root) and passed down — no view
/// below this point constructs a DefaultXxxRepository directly.
struct ContentView: View {
    // Concrete types appear only at the composition root; everything below depends
    // on the protocols, so substituting test doubles requires no view changes.
    private let userPrefs = DefaultUserPrefsRepository()
    private let formRepo  = DefaultFormRepository()
    private let sessionRepo = DefaultSessionRepository()

    @State private var isOnboarded: Bool
    @State private var homeVM: HomeViewModel

    init() {
        let prefs = DefaultUserPrefsRepository()
        let repo  = DefaultFormRepository()
        _isOnboarded = State(initialValue: prefs.onboardingState?.isOnboarded ?? false)
        _homeVM      = State(initialValue: HomeViewModel(userPrefs: prefs, formRepo: repo))
    }

    var body: some View {
        if isOnboarded {
            HomeView(homeVM: homeVM, userPrefs: userPrefs, sessionRepo: sessionRepo)
        } else {
            WelcomeView(userPrefs: userPrefs, formRepo: formRepo) {
                // Rebuild HomeViewModel from fresh prefs so it picks up the profile
                // and belt the user just selected during onboarding.
                homeVM = HomeViewModel(userPrefs: userPrefs, formRepo: formRepo)
                isOnboarded = true
            }
        }
    }
}

#Preview {
    ContentView()
}
