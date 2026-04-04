import Foundation
import Testing
@testable import PitchCircle

struct SettingsServiceTests {
    @Test
    func defaultsToA440() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)

        let service = SettingsService(userDefaults: userDefaults)

        #expect(service.settings.referencePitch == .a440)
    }

    @Test
    func persistsReferencePitchChanges() {
        let suiteName = #function
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let service = SettingsService(userDefaults: userDefaults)
        service.updateReferencePitch(.a432)

        let reloadedService = SettingsService(userDefaults: userDefaults)

        #expect(reloadedService.settings.referencePitch == .a432)
    }

    @Test
    func resetsToDefaults() {
        let suiteName = #function
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let service = SettingsService(userDefaults: userDefaults)
        service.updateReferencePitch(.a432)
        service.resetToDefaults()

        #expect(service.settings.referencePitch == .a440)
    }
}
