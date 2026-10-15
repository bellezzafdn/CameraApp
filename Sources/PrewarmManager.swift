// PrewarmManager.swift
import Foundation
import AVFoundation
import Combine

/// Manages the background pre‑warming of the camera session.
final class PrewarmManager: ObservableObject {
    static let shared = PrewarmManager()
    private var isWarm = false
    
    private init() {}
    
    /// Starts the camera session when the app launches.
    func startIfNeeded() {
        guard !isWarm else { return }
        CameraService.shared.startRunning(withPreview: true)
        isWarm = true
    }
    
    /// Called when the app returns to foreground.
    func resumeIfNeeded() {
        CameraService.shared.startRunning(withPreview: true)
    }
    
    /// Called when the app goes to background.
    func pauseIfAllowed() {}
    
    /// Fully stops the camera.
    func stopAll() {
        CameraService.shared.stopRunning()
        isWarm = false
    }
}
