// MotionService.swift
import Foundation
import CoreMotion
import Combine

/// Detects shake gestures by monitoring accelerometer data.
final class MotionService: ObservableObject {
    static let shared = MotionService()
    
    private let motionManager = CMMotionManager()
    private let shakeSubject = PassthroughSubject<Void, Never>()
    private let motionQueue = OperationQueue()
    
    /// Publisher that fires whenever a shake is detected.
    var shakePublisher: AnyPublisher<Void, Never> {
        shakeSubject.eraseToAnyPublisher()
    }
    
    private let shakeThreshold: Double = 2.5 // g-force threshold
    
    private init() {
        motionQueue.name = "motion.queue"
        startMonitoring()
    }
    
    private func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ MotionService: Accelerometer not available")
            return
        }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            let acceleration = data.acceleration
            let totalG = sqrt(acceleration.x * acceleration.x +
                              acceleration.y * acceleration.y +
                              acceleration.z * acceleration.z)
            if totalG > self.shakeThreshold {
                self.shakeSubject.send()
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }
}
