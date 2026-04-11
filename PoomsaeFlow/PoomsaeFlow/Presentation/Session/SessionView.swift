import SwiftUI

struct SessionView: View {
    let sessionViewModel: SessionViewModel
    let onGoAgain: () -> Void
    let onDone: () -> Void

    @State private var showPinHint: Bool
    @State private var showComplete = false
    @Environment(\.openURL) private var openURL

    init(
        sessionViewModel: SessionViewModel,
        hasSeenPinHint: Bool,
        onGoAgain: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.sessionViewModel = sessionViewModel
        self.onGoAgain = onGoAgain
        self.onDone = onDone
        // Derive initial hint visibility from the stored preference so it disappears
        // after the first session where the user has pinned at least one form.
        _showPinHint = State(initialValue: !hasSeenPinHint)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let form = sessionViewModel.currentForm {
                    formContent(form: form)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if sessionViewModel.currentForm != nil {
                        bookmarkButton
                    }
                }
            }
        }
        .onChange(of: sessionViewModel.isComplete) { _, complete in
            if complete { showComplete = true }
        }
        .fullScreenCover(isPresented: $showComplete) {
            SessionCompleteView(
                attempts: sessionViewModel.attempts,
                onGoAgain: {
                    showComplete = false
                    onGoAgain()
                },
                onDone: onDone
            )
        }
    }

    // MARK: - Subviews

    private var bookmarkButton: some View {
        Button {
            showPinHint = false
            sessionViewModel.userTappedPin()
        } label: {
            Image(systemName: sessionViewModel.isCurrentFormPinned ? "bookmark.fill" : "bookmark")
                // Amber fill when pinned matches the iOS bookmarks convention
                .foregroundStyle(sessionViewModel.isCurrentFormPinned ? Color.yellow : Color.secondary)
        }
        .accessibilityIdentifier("pin_button")
    }

    private func formContent(form: TKDForm) -> some View {
        VStack(spacing: 0) {
            // Progress bar + counter
            VStack(spacing: 4) {
                ProgressView(value: sessionViewModel.progress)
                Text("\(sessionViewModel.currentIndex + 1) of \(sessionViewModel.queueCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Hero card
            VStack(spacing: 10) {
                // Family badge
                Text(form.family.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundStyle(.tint)

                Text(form.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let korean = form.koreanName {
                    Text(korean)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Text("Introduced at \(form.introducedAt.rawValue.capitalized) belt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !form.videos.isEmpty {
                    Button {
                        let url = form.videos.first(where: { $0.isPrimary })?.url
                                ?? form.videos.first?.url
                        if let url { openURL(url) }
                    } label: {
                        Label("Watch on YouTube", systemImage: "play.rectangle.fill")
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer()

            // "Tap to pin" hint — shown only until the user pins for the first time
            if showPinHint {
                HStack {
                    Spacer()
                    Label("Tap to pin this form", systemImage: "bookmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // Horizontal padding aligns hint with the bookmark button in the toolbar
                    .padding(.trailing, 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            // Outcome buttons
            HStack(spacing: 12) {
                Button("Retry") {
                    sessionViewModel.userTappedRetry()
                }
                .buttonStyle(.bordered)

                Button("Skip") {
                    sessionViewModel.userTappedSkip()
                }
                .buttonStyle(.bordered)

                Button("Nailed it") {
                    sessionViewModel.userTappedNailed()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}
