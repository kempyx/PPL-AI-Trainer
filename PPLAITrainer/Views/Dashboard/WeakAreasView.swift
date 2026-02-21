import SwiftUI

struct WeakAreasView: View {
    let weakAreas: [WeakArea]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Weak Areas", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            if weakAreas.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Start answering questions to see weak areas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                VStack(spacing: 1) {
                    ForEach(weakAreas, id: \.id) { area in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(area.subcategoryName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(area.parentCategoryName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer(minLength: 8)

                            Text("\(area.totalAnswered) answered")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("\(Int(area.correctPercentage))%")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundColor(area.correctPercentage < 50 ? .red : .orange)
                                .frame(width: 36, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    WeakAreasView(weakAreas: [
        WeakArea(id: 1, subcategoryName: "Meteorology", parentCategoryName: "General Navigation", correctPercentage: 42.2, totalAnswered: 45),
        WeakArea(id: 2, subcategoryName: "Radio Navigation", parentCategoryName: "Navigation", correctPercentage: 47.4, totalAnswered: 38),
        WeakArea(id: 3, subcategoryName: "Flight Planning", parentCategoryName: "Flight Performance", correctPercentage: 51.9, totalAnswered: 52)
    ])
    .environment(\.dependencies, Dependencies.preview)
}
