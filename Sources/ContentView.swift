// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var prewarm = PrewarmManager.shared
    @State private var showBlur = false
    
    var body: some View {
        ZStack {
            // 1. Full-screen Camera preview (Front camera)
            CameraView()
                .edgesIgnoringSafeArea(.all)
            
            // 2. Blur overlay that mimics the native camera launch blur
            if showBlur {
                BlurOverlayView(duration: 0.3) {
                    prewarm.resumeIfNeeded()
                }
            }
        }
        .onAppear {
            prewarm.startIfNeeded()
        }
    }
}
