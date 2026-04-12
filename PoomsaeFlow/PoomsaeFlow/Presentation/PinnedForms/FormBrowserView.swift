import SwiftUI

/// Form Browser — subordinate flow launched from PinnedFormsView via "Add Forms".
///
/// Shows all forms the user is eligible to practice (dojang-catalog-scoped, belt-capped,
/// no family filter), grouped by the belt level at which each form is introduced.
/// Already-pinned forms appear with a checkmark and disabled button so the user can
/// see at a glance what they've already added.
struct FormBrowserView: View {
    var homeVM: HomeViewModel

    var body: some View {
        let groups = buildGroups()
        List {
            ForEach(groups, id: \.canonical) { group in
                Section(group.headerName) {
                    ForEach(group.forms) { form in
                        FormBrowserRow(
                            form: form,
                            isPinned: homeVM.pinnedForms.formIDs.contains(form.id)
                        ) {
                            homeVM.pinForm(form.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Add Forms")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView(
                    "No Forms Available",
                    systemImage: "doc.text",
                    description: Text("No additional forms are available for your belt and school")
                )
            }
        }
    }

    // MARK: - Grouping

    private struct BeltGroup {
        let canonical: CanonicalBelt
        let headerName: String
        let forms: [TKDForm]
    }

    private func buildGroups() -> [BeltGroup] {
        // Dictionary keyed by CanonicalBelt so membership tests are O(1).
        let beltNameMap: [CanonicalBelt: String] = Dictionary(
            uniqueKeysWithValues: homeVM.activeProfile.beltLevels.map {
                ($0.canonical, $0.name)
            }
        )

        // Group by introducedAt, preserving CanonicalBelt order.
        var grouped: [CanonicalBelt: [TKDForm]] = [:]
        for form in homeVM.browsableForms {
            grouped[form.introducedAt, default: []].append(form)
        }

        return grouped
            .sorted { $0.key.order < $1.key.order }
            .map { canonical, forms in
                BeltGroup(
                    canonical: canonical,
                    headerName: beltNameMap[canonical] ?? canonical.displayName,
                    forms: forms
                )
            }
    }
}

// MARK: - FormBrowserRow

private struct FormBrowserRow: View {
    let form: TKDForm
    let isPinned: Bool
    let onPin: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(form.name)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(form.family.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onPin) {
                Image(systemName: isPinned ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(isPinned ? Color.accentColor : Color.secondary)
            }
            .disabled(isPinned)
            .buttonStyle(.plain)
            .accessibilityIdentifier("form_browser_pin_button_\(form.id)")
        }
        .padding(.vertical, 2)
        // .contain exposes child elements (including the pin button) as separate
        // accessibility nodes, preventing the List cell from collapsing them.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("form_browser_form_row_\(form.id)")
    }
}

// MARK: - CanonicalBelt display name

private extension CanonicalBelt {
    /// Human-readable fallback when the canonical belt has no matching entry in the
    /// active profile's belt ladder (e.g. a WT user whose catalog has forms introduced
    /// at intermediate Sparta TKD canonicals).
    var displayName: String {
        switch self {
        case .white:     return "White"
        case .yellow:    return "Yellow"
        case .yellowAdv: return "Yellow Advanced"
        case .orange:    return "Orange"
        case .orangeAdv: return "Orange Advanced"
        case .green:     return "Green"
        case .greenAdv:  return "Green Advanced"
        case .blue:      return "Blue"
        case .blueAdv:   return "Blue Advanced"
        case .red:       return "Red"
        case .redAdv:    return "Red Advanced"
        case .poom:      return "Poom"
        case .black:     return "Black Belt"
        }
    }
}
