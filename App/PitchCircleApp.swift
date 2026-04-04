import SwiftUI

@main
struct PitchCircleApp: App {
    @StateObject private var appState: AppState
    @StateObject private var settingsService: SettingsService
    @StateObject private var detector: PitchDetectorService

    init() {
        let appState = AppState()
        let settingsService = SettingsService()

        _appState = StateObject(wrappedValue: appState)
        _settingsService = StateObject(wrappedValue: settingsService)
        _detector = StateObject(wrappedValue: PitchDetectorService(settingsService: settingsService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsService)
                .environmentObject(detector)
        }
    }
}
