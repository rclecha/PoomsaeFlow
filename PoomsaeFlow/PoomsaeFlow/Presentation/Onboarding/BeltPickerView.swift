import SwiftUI

struct BeltPickerView: View {
    let profile: DojangProfile
    let selectedBeltID: UUID?
    let onSelect: (BeltLevel) -> Void

    var body: some View {
        // Sort defensively — makeProfile() already produces displayOrder-sorted belts,
        // but a future custom profile may not guarantee order.
        let sorted = profile.beltLevels.sorted { $0.displayOrder < $1.displayOrder }
        List(sorted) { belt in
            Button {
                onSelect(belt)
            } label: {
                HStack(spacing: 12) {
                    // Swatch uses a subtle stroke so white belts remain visible on any background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: belt.colorHex))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                        )

                    Text(belt.name)
                        .foregroundStyle(.primary)

                    Spacer()

                    if belt.id == selectedBeltID {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Select Belt")
        .navigationBarTitleDisplayMode(.inline)
    }
}
