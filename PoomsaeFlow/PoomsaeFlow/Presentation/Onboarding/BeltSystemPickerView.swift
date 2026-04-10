import SwiftUI

/// Onboarding-only picker — the one place in the presentation layer that names
/// `BeltSystemPreset` directly. Once onboarding completes, the rest of the app
/// works exclusively with the resulting `DojangProfile`; this view is the entry
/// gate that converts a preset choice into a profile.
struct BeltSystemPickerView: View {
    let selectedPreset: BeltSystemPreset?
    let onSelect: (BeltSystemPreset) -> Void

    var body: some View {
        List(BeltSystemPreset.allCases, id: \.self) { preset in
            if preset == .custom {
                // Custom is a v2 feature — visible to communicate the roadmap but not tappable
                HStack {
                    Text(preset.displayName)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Coming soon")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Text(preset.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    if preset == selectedPreset {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(preset)
                }
            }
        }
        .navigationTitle("Select School")
        .navigationBarTitleDisplayMode(.inline)
    }
}
