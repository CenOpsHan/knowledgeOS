import Foundation
import Vision
import UIKit

class OCRService {
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "OCRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            let request = VNRecognizeTextRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "it"]
            request.usesLanguageCorrection = true

            if #available(iOS 16.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }

    func recognizeTexts(from images: [UIImage]) async -> [(image: UIImage, text: String?, error: Error?)] {
        await withTaskGroup(of: (Int, UIImage, String?, Error?).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    do {
                        let text = try await self.recognizeText(from: image)
                        return (index, image, text, nil)
                    } catch {
                        return (index, image, nil, error)
                    }
                }
            }

            var results: [(index: Int, image: UIImage, text: String?, error: Error?)] = []
            for await result in group {
                results.append(result)
            }

            return results
                .sorted { $0.index < $1.index }
                .map { ($0.image, $0.text, $0.error) }
        }
    }
}
