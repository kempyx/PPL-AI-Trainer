import SwiftUI
import Charts

struct MockExamTrendChart: View {
    let results: [MockExamResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Trend")
                .font(.headline)
            
            Chart {
                ForEach(results, id: \.id) { result in
                    LineMark(
                        x: .value("Date", result.completedAt),
                        y: .value("Score", result.percentage)
                    )
                    .foregroundStyle(.blue)
                    
                    PointMark(
                        x: .value("Date", result.completedAt),
                        y: .value("Score", result.percentage)
                    )
                    .foregroundStyle(result.percentage >= 75 ? .green : .red)
                }
                
                RuleMark(y: .value("Pass", 75))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [5, 5]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("75%")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    MockExamTrendChart(results: [])
}
