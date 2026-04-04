import Foundation

enum ReferencePitch: Double, CaseIterable, Identifiable {
    case a440 = 440.0
    case a432 = 432.0

    var id: String {
        label
    }

    var label: String {
        switch self {
        case .a440:
            return "A440"
        case .a432:
            return "A432"
        }
    }

    var statusLabel: String {
        label.lowercased()
    }
}

struct AppSettings: Equatable {
    var referencePitch: ReferencePitch = .a440

    static let `default` = AppSettings()
}
