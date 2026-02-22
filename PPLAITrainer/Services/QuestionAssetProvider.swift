import Foundation
import UIKit

protocol QuestionAssetProviding {
    func uiImage(filename: String) -> UIImage?
    func imageDataURL(filename: String) -> String?
    func categoryIcon(categoryId: Int64) -> UIImage?
}

struct BundleQuestionAssetProvider: QuestionAssetProviding {
    let dataset: DatasetDescriptor
    private let bundle: Bundle

    init(dataset: DatasetDescriptor, bundle: Bundle = .main) {
        self.dataset = dataset
        self.bundle = bundle
    }

    func uiImage(filename: String) -> UIImage? {
        guard let path = resolvePath(for: filename, directory: dataset.imagesDirectory) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }

    func imageDataURL(filename: String) -> String? {
        guard let path = resolvePath(for: filename, directory: dataset.imagesDirectory),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return "data:\(mimeType(for: filename));base64,\(data.base64EncodedString())"
    }

    func categoryIcon(categoryId: Int64) -> UIImage? {
        let png = "\(categoryId).png"
        if let path = resolvePath(for: png, directory: dataset.resolvedCategoryIconsDirectory),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        let jpg = "\(categoryId).jpg"
        if let path = resolvePath(for: jpg, directory: dataset.resolvedCategoryIconsDirectory),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return nil
    }

    private func resolvePath(for filename: String, directory: String) -> String? {
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension

        if let path = bundle.path(forResource: name, ofType: ext, inDirectory: directory) {
            return path
        }
        if let path = bundle.path(forResource: name, ofType: ext) {
            return path
        }
        return nil
    }

    private func mimeType(for filename: String) -> String {
        switch (filename as NSString).pathExtension.lowercased() {
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "webp":
            return "image/webp"
        default:
            return "application/octet-stream"
        }
    }
}
