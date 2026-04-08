import SwiftUI

struct FormDetailView: View {
    let form: TKDForm
    @Environment(\.dismiss) private var dismiss
    // openURL is the SwiftUI-idiomatic equivalent of UIApplication.shared.open()
    // and works correctly in sheets and extensions, unlike direct UIKit calls.
    @Environment(\.openURL) private var openURL

    private var primaryVideo: VideoResource? {
        form.videos.first { $0.isPrimary } ?? form.videos.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Family", value: form.family.displayName)
                    LabeledContent("Introduced at", value: form.introducedAt.rawValue.capitalized + " belt")
                    if let korean = form.koreanName {
                        LabeledContent("Korean name", value: korean)
                    }
                    if let notes = form.notes {
                        Text(notes)
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                }

                if !form.videos.isEmpty {
                    Section {
                        Button {
                            if let url = primaryVideo?.url {
                                openURL(url)
                            }
                        } label: {
                            Label("Watch on YouTube", systemImage: "play.rectangle.fill")
                        }
                    }
                }
            }
            .navigationTitle(form.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
