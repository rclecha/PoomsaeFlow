import SwiftUI

/// Primary screen for managing and practicing pinned forms.
///
/// A "Start session" button lives in the bottom toolbar — disabled when no forms are
/// pinned or when edit mode is active. Pinned forms are shown in their stored order
/// with swipe-to-delete and drag-to-reorder. Tapping "Edit" reveals delete handles,
/// reorder handles, and an "Add forms" row at the bottom. All mutations route through
/// HomeViewModel — this view holds zero business logic.
struct PinnedFormsView: View {
    var homeVM: HomeViewModel
    /// Called when the user confirms Session Setup. The parent (HomeView) owns the
    /// active session state and fullScreenCover — this view only triggers the flow.
    let onStartSession: (SessionScope, SessionOrder, [FormFamily]) -> Void

    @State private var editMode: EditMode = .inactive
    @State private var showBrowser = false
    @State private var showSessionConfig = false

    var body: some View {
        List {
            ForEach(homeVM.resolvedPinnedForms) { form in
                PinnedFormRow(form: form)
                    .accessibilityIdentifier("pinned_form_row_\(form.id)")
            }
            .onDelete { offsets in
                for index in offsets {
                    let id = homeVM.resolvedPinnedForms[index].id
                    homeVM.unpinForm(id)
                }
            }
            .onMove { from, to in
                homeVM.reorderPinnedForms(fromOffsets: from, toOffset: to)
            }

            if editMode == .active {
                Button {
                    showBrowser = true
                } label: {
                    Label("Add forms", systemImage: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityIdentifier("add_forms_button")
            }
        }
        .environment(\.editMode, $editMode)
        .overlay {
            if homeVM.resolvedPinnedForms.isEmpty && editMode == .inactive {
                ContentUnavailableView(
                    "No Pinned Forms",
                    systemImage: "bookmark",
                    description: Text("Tap Edit to add forms to your training list")
                )
            }
        }
        .navigationDestination(isPresented: $showBrowser) {
            FormBrowserView(homeVM: homeVM)
        }
        .navigationTitle("Pinned Forms")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(editMode == .inactive ? "Edit" : "Done") {
                    editMode = editMode == .inactive ? .active : .inactive
                }
                .accessibilityIdentifier("edit_pinned_forms_button")
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showSessionConfig = true
                } label: {
                    Label("Start session", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(homeVM.resolvedPinnedForms.isEmpty || editMode == .active)
                .accessibilityIdentifier("start_pinned_session_button")
            }
        }
        .sheet(isPresented: $showSessionConfig) {
            SessionConfigView(
                eligibleForms: homeVM.resolvedPinnedForms,
                initialOrder: homeVM.sessionDefaults.defaultOrder,
                initialFamilies: homeVM.sessionDefaults.enabledFamilies
            ) { order, families in
                onStartSession(.pinned, order, families)
            }
        }
    }
}

// MARK: - PinnedFormRow

private struct PinnedFormRow: View {
    let form: TKDForm

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(form.name)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(form.family.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
