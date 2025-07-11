import SwiftUI
import Vision

enum VisionError: Error {
    case ocrFailed
}

struct VisionService {
    func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(VisionError.ocrFailed))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(VisionError.ocrFailed))
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            
            DispatchQueue.main.async {
                completion(.success(recognizedStrings.joined(separator: "\n")))
            }
        }
        
        request.recognitionLevel = .accurate
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
//
//  VisionService.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//

