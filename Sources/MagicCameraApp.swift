import SwiftUI

@main
struct MagicCameraApp: App {
    // Observe app lifecycle to handle pre‑warm
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var prewarm = PrewarmManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        // app came to foreground – resume camera if needed
                        prewarm.resumeIfNeeded()
                    case .background:
                        // app goes to background – keep session warm (optional)
                        prewarm.pauseIfAllowed()
                    default:
                        break
                    }
                }
        }
    }
}
