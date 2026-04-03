import SwiftUI

@main
struct PitchCircleApp: App {
    @StateObject private var detector = PitchDetectorService()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(detector).onAppear { detector.start() }
        }
    }
}
