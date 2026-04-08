import SwiftUI

struct SessionCompleteView: View {
    let attempts: [FormAttempt]
    let onGoAgain: () -> Void
    let onDone: () -> Void

    // "Nailed" = passed on the first attempt (no retries recorded)
    private var nailedCount: Int {
        attempts.filter { $0.outcome == .passed }.count
    }

    // "Retried" = eventually passed after one or more retries
    private var retriedCount: Int {
        attempts.filter { $0.outcome == .passedAfterRetry }.count
    }

    private var skippedCount: Int {
        attempts.filter { $0.outcome == .skipped }.count
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("Session Complete")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("\(attempts.count) form\(attempts.count == 1 ? "" : "s") reviewed")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                SummaryRow(label: "Nailed it", count: nailedCount, color: .green)
                Divider().padding(.leading)
                SummaryRow(label: "Needed retries", count: retriedCount, color: .orange)
                Divider().padding(.leading)
                SummaryRow(label: "Skipped", count: skippedCount, color: .secondary)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onGoAgain()
                } label: {
                    Text("Go again")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Done", action: onDone)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

private struct SummaryRow: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding()
    }
}
