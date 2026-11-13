import SwiftUI
import AVFoundation

@main
struct PomegranateKitchenApp: App {
    init() {
        // Game sounds mix with any music you already have playing, and follow the silent switch.
        // To hear the sounds even when your phone is on silent, change .ambient to .playback.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .background(Color(red: 21 / 255, green: 18 / 255, blue: 19 / 255))
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                // Rubbing arils near the bottom edge shouldn't send you to the home screen.
                .defersSystemGestures(on: .bottom)
        }
    }
}
