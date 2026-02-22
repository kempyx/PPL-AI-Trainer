import Foundation

protocol DatasetCatalogManaging {
    var datasets: [DatasetDescriptor] { get }
    var defaultDataset: DatasetDescriptor { get }
    func dataset(id: String) -> DatasetDescriptor?
}

enum DatasetCatalogError: LocalizedError {
    case manifestNotFound
    case manifestDecodeFailed
    case invalidDatasetId(String)
    case duplicateDatasetId(String)
    case emptyDatasets
    case defaultDatasetMissing(String)

    var errorDescription: String? {
        switch self {
        case .manifestNotFound:
            return "datasets.json was not found in the app bundle."
        case .manifestDecodeFailed:
            return "datasets.json is invalid and could not be decoded."
        case .invalidDatasetId(let id):
            return "Invalid dataset id: \(id). Allowed pattern is [a-z0-9._-]."
        case .duplicateDatasetId(let id):
            return "Duplicate dataset id in datasets.json: \(id)."
        case .emptyDatasets:
            return "datasets.json contains no datasets."
        case .defaultDatasetMissing(let id):
            return "Default dataset id \(id) does not exist in datasets.json."
        }
    }
}

struct BundledDatasetCatalog: DatasetCatalogManaging {
    let datasets: [DatasetDescriptor]
    let defaultDataset: DatasetDescriptor

    init(bundle: Bundle = .main) throws {
        let url = try Self.resolveManifestURL(in: bundle)
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        let manifest: DatasetManifest
        do {
            manifest = try decoder.decode(DatasetManifest.self, from: data)
        } catch {
            throw DatasetCatalogError.manifestDecodeFailed
        }

        try Self.validate(manifest)

        self.datasets = manifest.datasets
        guard let defaultDataset = manifest.datasets.first(where: { $0.id == manifest.defaultDatasetId }) else {
            throw DatasetCatalogError.defaultDatasetMissing(manifest.defaultDatasetId)
        }
        self.defaultDataset = defaultDataset
    }

    func dataset(id: String) -> DatasetDescriptor? {
        datasets.first(where: { $0.id == id })
    }

    private static func resolveManifestURL(in bundle: Bundle) throws -> URL {
        if let url = bundle.url(forResource: "datasets", withExtension: "json", subdirectory: "Datasets") {
            return url
        }
        if let url = bundle.url(forResource: "datasets", withExtension: "json") {
            return url
        }
        throw DatasetCatalogError.manifestNotFound
    }

    private static func validate(_ manifest: DatasetManifest) throws {
        guard !manifest.datasets.isEmpty else {
            throw DatasetCatalogError.emptyDatasets
        }

        var seen = Set<String>()
        let allowed = try NSRegularExpression(pattern: "^[a-z0-9._-]+$")

        for dataset in manifest.datasets {
            let range = NSRange(location: 0, length: dataset.id.utf16.count)
            let matches = allowed.firstMatch(in: dataset.id, range: range) != nil
            guard matches else {
                throw DatasetCatalogError.invalidDatasetId(dataset.id)
            }
            guard seen.insert(dataset.id).inserted else {
                throw DatasetCatalogError.duplicateDatasetId(dataset.id)
            }
        }

        guard manifest.datasets.contains(where: { $0.id == manifest.defaultDatasetId }) else {
            throw DatasetCatalogError.defaultDatasetMissing(manifest.defaultDatasetId)
        }
    }
}
