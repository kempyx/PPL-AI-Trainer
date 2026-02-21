import Foundation

enum AppExperiment: String, CaseIterable, Identifiable {
    case contextualExplainEntry
    case hintTiming
    case dashboardNextUpPriority

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contextualExplainEntry:
            return "Contextual Explain Entry"
        case .hintTiming:
            return "Hint Timing"
        case .dashboardNextUpPriority:
            return "Dashboard Next-Up Priority"
        }
    }

    var variants: [String] {
        switch self {
        case .contextualExplainEntry:
            return ["control", "floating_cta"]
        case .hintTiming:
            return ["control", "pre_submit_hint"]
        case .dashboardNextUpPriority:
            return ["control", "mastery_first"]
        }
    }
}

struct ExperimentAssignment: Identifiable {
    let experiment: AppExperiment
    let override: String?
    let resolved: String

    var id: String { experiment.rawValue }
}
