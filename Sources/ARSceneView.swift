// ARSceneView.swift
import SwiftUI
import ARKit
import SceneKit

/// UIViewRepresentable that hosts an ARSCNView.
/// The view is linked to the shared ARService which owns the ARSession.
struct ARSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = ARService.shared
        arView.session = ARService.shared.session
        arView.automaticallyUpdatesLighting = true
        arView.scene = SCNScene()
        return arView
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No dynamic UI updates needed.
    }
}
