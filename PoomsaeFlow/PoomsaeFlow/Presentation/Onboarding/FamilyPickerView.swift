import SwiftUI

/// A `Section` containing a toggle row per form family plus a live form-count footer.
///
/// Designed as a `Section` (not a standalone `List`) so it can be dropped into any
/// `Form` or `List` without creating nested scroll views. Callers wrap it with
/// `Form { FamilyPickerView(...) }` for standalone use or embed it among other
/// sections in an existing `Form`.
struct FamilyPickerView: View {
    @Binding var enabledFamilies: [FormFamily]
    /// Total eligible form count given the current family selection.
    /// Passed in by the caller so this view never computes it independently.
    let formCount: Int

    var body: some View {
        Section {
            ForEach(FormFamily.allCases, id: \.self) { family in
                HStack {
                    Text(family.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    if enabledFamilies.contains(family) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggle(family)
                }
            }
        } footer: {
            Text("\(formCount) forms selected")
        }
    }

    private func toggle(_ family: FormFamily) {
        if let index = enabledFamilies.firstIndex(of: family) {
            enabledFamilies.remove(at: index)
        } else {
            enabledFamilies.append(family)
        }
    }
}
