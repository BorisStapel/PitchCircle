import Foundation
import Combine

final class SettingsService: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let userDefaults: UserDefaults
    private let referencePitchKey = "settings.referencePitch"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let storedValue = userDefaults.object(forKey: referencePitchKey) as? Double,
           let referencePitch = ReferencePitch(rawValue: storedValue) {
            settings = AppSettings(referencePitch: referencePitch)
        } else {
            settings = .default
        }
    }

    func updateReferencePitch(_ referencePitch: ReferencePitch) {
        guard settings.referencePitch != referencePitch else { return }

        settings.referencePitch = referencePitch
        persist()
    }

    func resetToDefaults() {
        settings = .default
        persist()
    }

    private func persist() {
        userDefaults.set(settings.referencePitch.rawValue, forKey: referencePitchKey)
    }
}
