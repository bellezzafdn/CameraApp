// BlurOverlayView.swift
import SwiftUI

/// A simple blur overlay that shows a UIVisualEffectView for `duration` seconds.
/// After the delay it calls `completion`.
struct BlurOverlayView: UIViewRepresentable {
    let duration: TimeInterval
    let completion: () -> Void
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blur = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.0
        // Fade‑in animation
        UIView.animate(withDuration: 0.15) {
            view.alpha = 1.0
        }
        // Schedule removal after `duration`
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.15, animations: {
                view.alpha = 0.0
            }) { _ in
                view.removeFromSuperview()
                completion()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No dynamic updates needed
    }
}
