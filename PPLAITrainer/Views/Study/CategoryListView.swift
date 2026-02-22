import SwiftUI

struct CategoryListView: View {
    @State var viewModel: StudyViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.displayCategories) { item in
                    if item.isGroup {
                        NavigationLink {
                            GroupDetailView(viewModel: viewModel, group: item)
                        } label: {
                            DisplayCategoryCard(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            SubcategoryListView(
                                viewModel: viewModel,
                                parentId: item.primaryCategoryId,
                                parentName: item.name
                            )
                        } label: {
                            DisplayCategoryCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .navigationTitle("Categories")
    }
}

// MARK: - Group Detail View

struct GroupDetailView: View {
    @State var viewModel: StudyViewModel
    let group: DisplayCategory

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(group.memberCategories, id: \.category.id) { member in
                    NavigationLink {
                        SubcategoryListView(
                            viewModel: viewModel,
                            parentId: member.category.id,
                            parentName: member.category.name
                        )
                    } label: {
                        MemberCategoryCard(item: member)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .navigationTitle(group.name)
    }
}

// MARK: - Display Category Card (top-level list)

private struct DisplayCategoryCard: View {
    @Environment(\.dependencies) private var deps
    let item: DisplayCategory

    var body: some View {
        HStack(spacing: 14) {
            categoryIcon

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 12) {
                    Label("\(item.subcategoryCount)", systemImage: "folder")
                    Label("\(item.stats.totalQuestions)", systemImage: "doc.text")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                QuizProgressBar(
                    total: item.stats.totalQuestions,
                    correct: item.stats.correctAnswers,
                    incorrect: item.stats.answeredQuestions - item.stats.correctAnswers
                )
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text(progressPercentage)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundColor(progressColor)
                Text("correct")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var categoryIcon: some View {
        let categoryId = item.primaryCategoryId
        if let uiImage = deps?.questionAssetProvider.categoryIcon(categoryId: categoryId) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "book.closed")
                        .foregroundColor(.accentColor)
                }
        }
    }

    private var progressPercentage: String {
        guard item.stats.totalQuestions > 0 else { return "—" }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions) * 100
        return "\(Int(pct))%"
    }

    private var progressColor: Color {
        guard item.stats.totalQuestions > 0, item.stats.answeredQuestions > 0 else { return .secondary }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions)
        if pct >= 0.75 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Member Category Card (inside a group)

private struct MemberCategoryCard: View {
    @Environment(\.dependencies) private var deps
    let item: CategoryWithStats

    var body: some View {
        HStack(spacing: 14) {
            categoryIcon

            VStack(alignment: .leading, spacing: 6) {
                Text(item.category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 12) {
                    Label("\(item.subcategoryCount)", systemImage: "folder")
                    Label("\(item.stats.totalQuestions)", systemImage: "doc.text")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                QuizProgressBar(
                    total: item.stats.totalQuestions,
                    correct: item.stats.correctAnswers,
                    incorrect: item.stats.answeredQuestions - item.stats.correctAnswers
                )
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text(progressPercentage)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundColor(progressColor)
                Text("correct")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var categoryIcon: some View {
        if let uiImage = deps?.questionAssetProvider.categoryIcon(categoryId: item.category.id) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "book.closed")
                        .foregroundColor(.accentColor)
                }
        }
    }

    private var progressPercentage: String {
        guard item.stats.totalQuestions > 0 else { return "—" }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions) * 100
        return "\(Int(pct))%"
    }

    private var progressColor: Color {
        guard item.stats.totalQuestions > 0, item.stats.answeredQuestions > 0 else { return .secondary }
        let pct = Double(item.stats.correctAnswers) / Double(item.stats.totalQuestions)
        if pct >= 0.75 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Progress Bar

struct QuizProgressBar: View {
    let total: Int
    let correct: Int
    let incorrect: Int

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let correctWidth = total > 0 ? width * CGFloat(correct) / CGFloat(total) : 0
            let incorrectWidth = total > 0 ? width * CGFloat(incorrect) / CGFloat(total) : 0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 6)

                HStack(spacing: 0) {
                    if correctWidth > 0 {
                        Capsule()
                            .fill(Color.green)
                            .frame(width: max(correctWidth, 3), height: 6)
                    }
                    if incorrectWidth > 0 {
                        Capsule()
                            .fill(Color.red)
                            .frame(width: max(incorrectWidth, 3), height: 6)
                    }
                }
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    let deps = Dependencies.preview
    CategoryListView(viewModel: StudyViewModel(databaseManager: deps.databaseManager))
        .environment(\.dependencies, deps)
}
