// ARService.swift
import Foundation
import ARKit
import SceneKit
import Combine
import AVFoundation

/// Central service that owns the ARSession, handles plane anchors, and places random filter nodes.
final class ARService: NSObject, ObservableObject, ARSCNViewDelegate {
    static let shared = ARService()
    let session = ARSession()
    private var cancellables = Set<AnyCancellable>()
    private var currentFilterNode: SCNNode?
    private var planeAnchor: ARPlaneAnchor?
    
    private override init() {
        super.init()
        // Listen to stable rectangle corners from VisionProcessor.
        VisionProcessor.shared.$stableCorners
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] corners in
                self?.handleStableCorners(corners)
            }
            .store(in: &cancellables)
        // Listen to shake events.
        MotionService.shared.shakePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.removeCurrentFilter()
            }
            .store(in: &cancellables)
    }
    
    // MARK: Session configuration
    func prepareSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [] // we do not need horizontal/vertical planes; we will add custom anchor.
        config.isLightEstimationEnabled = true
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func resumeSession() {
        // In case the session was paused, just run again with same config.
        if let frame = session.currentFrame {
            switch frame.camera.trackingState {
            case .normal:
                return // already tracking fine
            default:
                prepareSession()
            }
        } else {
            prepareSession()
        }
    }
    
    func pauseSession() {
        session.pause()
    }
    
    // MARK: Anchor handling
    private func handleStableCorners(_ corners: [CGPoint]) {
        // Convert normalized view coordinates (0‑1) to AR world coordinates using hitTest on the current frame.
        guard let currentFrame = session.currentFrame else { return }
        // Assuming the preview view size equals screen size – we will map using the frame's size later.
        // For simplicity, we perform a hitTest from screen center.
        // In a real implementation you would map each corner to a 3‑D point via unprojectPoint.
        // Here we just create a plane at a fixed distance in front of camera.
        let transform = currentFrame.camera.transform
        // Position the plane 0.3 m in front of the camera.
        var planeTransform = matrix_identity_float4x4
        planeTransform.columns.3.z = -0.3
        let anchor = ARAnchor(transform: planeTransform)
        session.add(anchor: anchor)
        planeAnchor = anchor as? ARPlaneAnchor
        // Add a random filter node.
        addRandomFilter(to: anchor)
    }
    
    private func addRandomFilter(to anchor: ARAnchor) {
        removeCurrentFilter()
        let node = FilterManager.shared.nextRandomFilter()
        currentFilterNode = node
        // The node's scale should match the physical size of the card (≈ 8.5 cm × 5.5 cm).
        node.scale = SCNVector3(0.085, 0.055, 0.001)
        // Position the node at the anchor's origin.
        node.position = SCNVector3Zero
        // Attach via delegate method.
        // We'll store the anchor ID to retrieve later in renderer(_:nodeFor:).
    }
    
    private func removeCurrentFilter() {
        currentFilterNode?.removeFromParentNode()
        currentFilterNode = nil
        if let anchor = planeAnchor {
            session.remove(anchor: anchor)
            planeAnchor = nil
        }
    }
    
    // MARK: ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Return a container node for our custom anchor.
        let node = SCNNode()
        if let filter = currentFilterNode, anchor.identifier == planeAnchor?.identifier {
            node.addChildNode(filter)
        }
        return node
    }
    
    // MARK: Live camera calibration (optional – sample implementation)
    func updateFilterLighting() {
        guard let device = CameraService.shared.currentDevice,
              let filter = currentFilterNode?.geometry?.firstMaterial else { return }
        // Pull exposure and white balance values.
        let exposureTargetBias = device.exposureTargetBias
        let iso = device.iso
        // Adjust material properties (brightness, temperature) – simplistic mapping.
        filter.lightingModel = .physicallyBased
        filter.diffuse.contents = UIColor(white: CGFloat(0.5 + exposureTargetBias/10.0), alpha: 1.0)
        // For a real implementation you would map white‑balance temperature to a color temperature.
    }
}
