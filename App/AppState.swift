import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isSettingsPresented = false
}
