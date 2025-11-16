//
//  EmotionDetectService.swift
//  Echoes
//
//  Created by Harry Zhu on 11/16/25.
//

import Foundation
import UIKit
import Vision
import CoreML

class emotion_service {

    static let shared = emotion_service()

    private let visionModel: VNCoreMLModel

    private init() {
        let model = try! EmotionClassifier(configuration: MLModelConfiguration()).model
        visionModel = try! VNCoreMLModel(for: model)
    }

    func predict(from image: UIImage) -> (String, Float)? {
        guard let cgImage = image.cgImage else { return nil }

        var result: (String, Float)? = nil

        let request = VNCoreMLRequest(model: visionModel) { req, _ in
            if let obs = req.results as? [VNClassificationObservation],
               let top = obs.first {
                result = (top.identifier, top.confidence)
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
        return result
    }
}
