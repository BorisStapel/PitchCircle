import SwiftUI

@main
struct PitchCircleApp: App {
    @StateObject private var settingsService: SettingsService
    @StateObject private var detector: PitchDetectorService

    init() {
        let settingsService = SettingsService()

        _settingsService = StateObject(wrappedValue: settingsService)
        _detector = StateObject(wrappedValue: PitchDetectorService(settingsService: settingsService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsService)
                .environmentObject(detector)
        }
    }
}
