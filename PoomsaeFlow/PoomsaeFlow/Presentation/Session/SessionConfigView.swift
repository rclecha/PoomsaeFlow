import SwiftUI

struct SessionConfigView: View {
    /// Belt-and-profile-filtered forms passed in by the parent; used to compute the
    /// live form count as the user toggles families. No filtering logic lives here —
    /// the view only counts what it receives.
    let eligibleForms: [TKDForm]
    let onStart: (SessionOrder, [FormFamily]) -> Void

    @State private var selectedOrder: SessionOrder
    @State private var selectedFamilies: [FormFamily]
    @Environment(\.dismiss) private var dismiss

    /// Live count updates as `selectedFamilies` changes — used as the formCount input
    /// for FamilyPickerView's footer label.
    private var liveFormCount: Int {
        let enabled = Set(selectedFamilies)
        return eligibleForms.filter { enabled.contains($0.family) }.count
    }

    init(
        eligibleForms: [TKDForm],
        initialOrder: SessionOrder,
        initialFamilies: [FormFamily],
        onStart: @escaping (SessionOrder, [FormFamily]) -> Void
    ) {
        self.eligibleForms = eligibleForms
        self.onStart = onStart
        _selectedOrder = State(initialValue: initialOrder)
        _selectedFamilies = State(initialValue: initialFamilies)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Order") {
                    Picker("Order", selection: $selectedOrder) {
                        Text("Sequential").tag(SessionOrder.sequential)
                        Text("Randomized").tag(SessionOrder.randomized)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                FamilyPickerView(enabledFamilies: $selectedFamilies, formCount: liveFormCount)
            }
            .navigationTitle("Session Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onStart(selectedOrder, selectedFamilies)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(liveFormCount == 0)
                }
            }
        }
    }
}
