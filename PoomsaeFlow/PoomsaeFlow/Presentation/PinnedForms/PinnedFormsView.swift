import SwiftUI

/// Primary screen for managing the user's training list.
///
/// Shows pinned forms in their stored order, supports swipe-to-delete and drag-to-reorder.
/// Tapping "Edit" reveals delete handles, reorder handles, and an "Add forms" row at the
/// bottom. All mutations route through HomeViewModel — this view holds zero business logic.
struct PinnedFormsView: View {
    var homeVM: HomeViewModel

    @State private var editMode: EditMode = .inactive
    @State private var showBrowser = false

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
        }
        .overlay {
            if homeVM.resolvedPinnedForms.isEmpty && editMode == .inactive {
                ContentUnavailableView(
                    "No Pinned Forms",
                    systemImage: "bookmark",
                    description: Text("Tap Edit to add forms to your training list")
                )
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
