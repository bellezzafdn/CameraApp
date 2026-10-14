import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var prewarm = PrewarmManager.shared
    @StateObject private var vision = VisionProcessor.shared
    @StateObject private var arService = ARService.shared
    @State private var showBlur = false
    @State private var isActive = false // true when fake‑camera icon tapped
    
    var body: some View {
        ZStack {
            // Camera preview (hidden when blur is active, but we keep the view)
            CameraView()
                .edgesIgnoringSafeArea(.all)
            // AR overlay – renders the filter on top of camera frames
            ARSceneView()
                .edgesIgnoringSafeArea(.all)
            // Blur overlay that mimics the native camera blur
            if showBlur {
                BlurOverlayView(duration: 0.3) {
                    // Blur finished – start camera processing
                    prewarm.resumeIfNeeded()
                }
            }
            // Fake‑camera icon – simple button in bottom‑right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // User taps the fake icon
                        isActive.toggle()
                        // Show blur then let the pre‑warm resume the session
                        showBlur = true
                    }) {
                        Image(systemName: "camera")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            // Start pre‑warm when the app launches (background session)
            prewarm.startIfNeeded()
        }
    }
}
