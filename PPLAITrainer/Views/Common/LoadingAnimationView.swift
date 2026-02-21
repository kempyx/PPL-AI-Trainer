import SwiftUI

struct LoadingAnimationView: View {
    let requestCount: Int
    @State private var messageIndex = 0

    private let messages = [
        "Checking the charts...",
        "Cross-checking instruments...",
        "Asking your flight instructor..."
    ]

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
            if requestCount < 3 {
                Text(messages[messageIndex])
                    .foregroundStyle(.secondary)
                    .onAppear {
                        messageIndex = (requestCount % messages.count)
                    }
            }
        }
        .padding()
    }
}
