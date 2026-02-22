import Foundation

struct DatasetExamSubject: Codable, Hashable {
    let name: String
    let categoryCodes: [String]
    let questionCount: Int
    let timeMinutes: Int
}

struct DatasetExamMapping: Codable, Hashable {
    let technicalLegal: [DatasetExamSubject]
    let humanEnvironment: [DatasetExamSubject]
    let planningNavigation: [DatasetExamSubject]

    func subjects(for leg: ExamLeg) -> [DatasetExamSubject] {
        switch leg {
        case .technicalLegal:
            return technicalLegal
        case .humanEnvironment:
            return humanEnvironment
        case .planningNavigation:
            return planningNavigation
        }
    }
}

struct DatasetDescriptor: Codable, Identifiable, Hashable {
    let id: String
    let familyId: String
    let languageCode: String
    let version: String
    let displayName: String
    let databaseResourceName: String
    let databaseExtension: String
    let imagesDirectory: String
    let categoryIconsDirectory: String?
    let examMapping: DatasetExamMapping?

    var resolvedCategoryIconsDirectory: String {
        categoryIconsDirectory ?? imagesDirectory
    }

    func subjects(for leg: ExamLeg) -> [DatasetExamSubject] {
        (examMapping ?? .defaultValue).subjects(for: leg)
    }
}

struct DatasetManifest: Codable, Hashable {
    let defaultDatasetId: String
    let datasets: [DatasetDescriptor]
}

extension DatasetExamMapping {
    static let defaultValue = DatasetExamMapping(
        technicalLegal: [
            DatasetExamSubject(name: "Aircraft General Knowledge", categoryCodes: ["21", "22"], questionCount: 20, timeMinutes: 35),
            DatasetExamSubject(name: "Principles of Flight", categoryCodes: ["81"], questionCount: 20, timeMinutes: 45),
            DatasetExamSubject(name: "Air Law", categoryCodes: ["10"], questionCount: 20, timeMinutes: 45)
        ],
        humanEnvironment: [
            DatasetExamSubject(name: "Meteorology", categoryCodes: ["50"], questionCount: 20, timeMinutes: 45),
            DatasetExamSubject(name: "Human Performance", categoryCodes: ["40"], questionCount: 20, timeMinutes: 30),
            DatasetExamSubject(name: "Communications", categoryCodes: ["91"], questionCount: 20, timeMinutes: 30)
        ],
        planningNavigation: [
            DatasetExamSubject(name: "Navigation", categoryCodes: ["61", "62"], questionCount: 20, timeMinutes: 65),
            DatasetExamSubject(name: "Flight Performance & Planning", categoryCodes: ["31", "32", "33"], questionCount: 20, timeMinutes: 95),
            DatasetExamSubject(name: "Operational Procedures", categoryCodes: ["70"], questionCount: 20, timeMinutes: 30)
        ]
    )
}
