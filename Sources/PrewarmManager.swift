// PrewarmManager.swift
import Foundation
import AVFoundation
import ARKit
import Combine

/// Manages the background pre‑warming of the camera and AR sessions.
/// The manager is a singleton because the app may go to background
/// and come back multiple times.
final class PrewarmManager: ObservableObject {
    static let shared = PrewarmManager()
    private var cancellables = Set<AnyCancellable>()
    private var isWarm = false
    
    private init() {
        // Listen for app lifecycle notifications if needed (handled in MagicCameraApp).
    }
    
    /// Starts the camera and AR sessions in a minimal mode while the app is in background.
    func startIfNeeded() {
        guard !isWarm else { return }
        // Start camera without preview (pre‑warm)
        CameraService.shared.startRunning(withPreview: false)
        // Prepare AR session (no world tracking needed yet)
        ARService.shared.prepareSession()
        isWarm = true
    }
    
    /// Called when the app returns to foreground and we need the full preview.
    func resumeIfNeeded() {
        guard isWarm else { return }
        // Enable preview now that the UI is visible.
        CameraService.shared.startRunning(withPreview: true)
        // AR session is already running; just ensure configuration is active.
        ARService.shared.resumeSession()
    }
    
    /// Called when the app goes to background. We keep the sessions alive
    /// because the trick relies on pre‑warming, but we could optionally pause
    /// after a timeout.
    func pauseIfAllowed() {
        // For this magic‑show use‑case we keep them alive; no‑op.
        // If you ever need to conserve battery you could stop here.
    }
    
    /// Fully stops everything – used when the app quits.
    func stopAll() {
        CameraService.shared.stopRunning()
        ARService.shared.pauseSession()
        isWarm = false
    }
}
