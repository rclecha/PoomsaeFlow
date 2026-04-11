import SwiftUI

struct HomeView: View {
    var homeVM: HomeViewModel
    let userPrefs: UserPrefsRepository
    let sessionRepo: SessionRepository

    // MARK: - Local state

    @State private var selectedScope: SessionScope = .fullSet
    @State private var showBeltPicker = false
    @State private var showSessionConfig = false
    @State private var activeSession: ActiveSession? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    beltProfileCard
                    sessionTypeSection
                    beltFormsSection
                }
                .padding()
            }
            .navigationTitle("PoomsaeFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSessionConfig = true
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .disabled(homeVM.eligibleForms.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showBeltPicker) {
            // BeltPickerView is embedded in its own NavigationStack because it's a sheet;
            // the outer NavigationStack ends at the sheet boundary.
            NavigationStack {
                BeltPickerView(
                    profile: homeVM.activeProfile,
                    selectedBeltID: homeVM.activeBeltLevel.id
                ) { belt in
                    homeVM.saveBeltLevel(belt)
                    showBeltPicker = false
                }
            }
        }
        .sheet(isPresented: $showSessionConfig) {
            SessionConfigView(
                eligibleForms: homeVM.eligibleForms,
                initialOrder: homeVM.sessionDefaults.defaultOrder,
                initialFamilies: homeVM.sessionDefaults.enabledFamilies
            ) { order, families in
                startSession(scope: selectedScope, order: order, families: families)
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionView(
                sessionViewModel: session.viewModel,
                hasSeenPinHint: userPrefs.onboardingState?.hasSeenPinHint ?? true,
                onGoAgain: { rebuildSession(config: session.config) },
                onDone:    { activeSession = nil }
            )
        }
    }

    // MARK: - Belt profile card

    private var beltProfileCard: some View {
        Button {
            showBeltPicker = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: homeVM.activeBeltLevel.colorHex))
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                        )
                    Text(homeVM.activeBeltLevel.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(homeVM.activeProfile.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Enabled families shown inline — updates live when SessionDefaults change
                Text(homeVM.sessionDefaults.enabledFamilies.map(\.displayName).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(homeVM.eligibleForms.count) eligible forms")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session type cards

    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Type")
                .font(.headline)

            SessionTypeCard(
                title: "Full set",
                subtitle: "\(homeVM.eligibleForms.count) forms",
                systemImage: "rectangle.stack",
                isSelected: selectedScope == .fullSet,
                isEnabled: !homeVM.eligibleForms.isEmpty
            ) {
                selectedScope = .fullSet
            }

            SessionTypeCard(
                title: "Pinned forms",
                subtitle: homeVM.pinnedForms.formIDs.isEmpty
                    ? "No pinned forms yet"
                    : "\(homeVM.pinnedForms.formIDs.count) pinned",
                systemImage: "bookmark.fill",
                isSelected: selectedScope == .pinned,
                isEnabled: !homeVM.pinnedForms.formIDs.isEmpty
            ) {
                selectedScope = .pinned
            }
            .accessibilityIdentifier("session_card_pinned")
        }
    }

    // MARK: - Belt forms section

    /// Lists each form introduced at the trainee's current belt. Tapping a row immediately
    /// starts a belt form session using the stored session defaults.
    private var beltFormsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Belt Forms")
                .font(.headline)

            if homeVM.formsIntroducedAtCurrentBelt.isEmpty {
                Text("No new forms introduced at this belt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(homeVM.formsIntroducedAtCurrentBelt) { form in
                    BeltFormRow(form: form) {
                        startSession(
                            scope: .single(form.id),
                            order: homeVM.sessionDefaults.defaultOrder,
                            families: homeVM.sessionDefaults.enabledFamilies
                        )
                    }
                }
            }
        }
    }

    // MARK: - Session wiring

    private func startSession(scope: SessionScope, order: SessionOrder, families: [FormFamily]) {
        let practiceSession = homeVM.buildSession(scope: scope, order: order, families: families)
        let controller = SessionController(session: practiceSession)
        let vm = SessionViewModel(controller: controller, sessionRepo: sessionRepo, userPrefs: userPrefs)
        activeSession = ActiveSession(
            viewModel: vm,
            config: SessionConfig(scope: scope, order: order, families: families)
        )
    }

    private func rebuildSession(config: SessionConfig) {
        startSession(scope: config.scope, order: config.order, families: config.families)
    }
}

// MARK: - Supporting types (HomeView-private)

private struct SessionConfig {
    let scope: SessionScope
    let order: SessionOrder
    let families: [FormFamily]
}

private struct ActiveSession: Identifiable {
    let id = UUID()
    let viewModel: SessionViewModel
    let config: SessionConfig
}

// MARK: - BeltFormRow

private struct BeltFormRow: View {
    let form: TKDForm
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(form.name)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(form.family.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("belt_form_row")
    }
}

// MARK: - SessionTypeCard

private struct SessionTypeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                        .foregroundStyle(isEnabled ? .primary : .secondary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // Selected state gets a tinted border so the active card is unambiguous
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
