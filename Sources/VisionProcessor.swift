// VisionProcessor.swift
import Foundation
import AVFoundation
import Vision
import Combine

final class VisionProcessor: ObservableObject {
    static let shared = VisionProcessor()
    private let request = VNDetectRectanglesRequest()
    private var cancellables = Set<AnyCancellable>()
    
    // Published stable corners (in view coordinates)
    @Published var stableCorners: [CGPoint]? = nil
    
    private var lastCorners: [CGPoint]? = nil
    private var stableCount = 0
    private let requiredStableFrames = 2
    
    private init() {
        // Configure request for high accuracy
        request.minimumAspectRatio = VNAspectRatio(0.5)
        request.maximumAspectRatio = VNAspectRatio(1.0)
        request.minimumSize = 0.2
        request.quadratureTolerance = 20.0 // degrees
    }
    
    func process(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([request])
            guard let observation = request.results?.first as? VNRectangleObservation else { return }
            // Convert normalized coordinates to view space (0‑1 -> we'll map later)
            let corners = [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft].map { CGPoint(x: $0.x, y: $0.y) }
            evaluateStability(current: corners)
        } catch {
            // ignore errors for now
        }
    }
    
    private func evaluateStability(current: [CGPoint]) {
        if let last = lastCorners, areCornersSimilar(last, current) {
            stableCount += 1
        } else {
            stableCount = 0
        }
        lastCorners = current
        if stableCount >= requiredStableFrames {
            // Publish on main thread for UI/AR consumption
            DispatchQueue.main.async { self.stableCorners = current }
        }
    }
    
    private func areCornersSimilar(_ a: [CGPoint], _ b: [CGPoint]) -> Bool {
        guard a.count == b.count else { return false }
        let tolerance: CGFloat = 0.02 // ~2% of normalized space
        for (p1, p2) in zip(a, b) {
            if abs(p1.x - p2.x) > tolerance || abs(p1.y - p2.y) > tolerance {
                return false
            }
        }
        return true
    }
}
