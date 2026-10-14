// CameraView.swift
import SwiftUI
import AVFoundation
import Combine

/// UIViewRepresentable that hosts an AVCaptureVideoPreviewLayer.
/// The preview layer is attached/detached by PrewarmManager.
struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        // Obtain the shared CameraService and set its preview layer on this view.
        CameraService.shared.attachPreview(to: view)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        // No dynamic updates needed.
    }
}

// CameraService.swift
import AVFoundation
import Combine

final class CameraService: NSObject {
    static let shared = CameraService()
    private let session = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoQueue = DispatchQueue(label: "camera.video.queue")
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        configureSession()
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("⚠️ Unable to access back camera")
            session.commitConfiguration()
            return
        }
        if session.canAddInput(videoInput) { session.addInput(videoInput) }
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        session.commitConfiguration()
    }
    
    // Called by CameraView to attach the preview layer to a container view.
    func attachPreview(to container: UIView) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = container.bounds
        container.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }
    
    func startRunning(withPreview: Bool = true) {
        if !session.isRunning { session.startRunning() }
        // If preview has been previously detached, re‑attach it.
        if withPreview, previewLayer == nil {
            // The preview will be re‑attached by the next CameraView creation.
        }
    }
    
    func stopRunning() {
        if session.isRunning { session.stopRunning() }
    }
    
    // Expose the current video device for exposure/white‑balance values.
    var currentDevice: AVCaptureDevice? { session.inputs.compactMap { ($0 as? AVCaptureDeviceInput)?.device }.first }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Forward frames to VisionProcessor.
        VisionProcessor.shared.process(sampleBuffer: sampleBuffer)
    }
}
