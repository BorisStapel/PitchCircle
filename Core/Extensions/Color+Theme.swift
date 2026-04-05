import SwiftUI

extension Color {
    static let bgApp = Color(hex: "#F5F2EA")
    static let bgSegment = Color(hex: "#E6E0D4")
    static let bgCore = Color(hex: "#D8D1C3")
    static let activeMajorFill = Color(hex: "#D9CCFF")
    static let activeMajorStroke = Color(hex: "#6E59D9")
    static let activeMajorText = Color(hex: "#43308F")
    static let activeMinorFill = Color(hex: "#CDEEE2")
    static let activeMinorStroke = Color(hex: "#177A5B")
    static let activeMinorText = Color(hex: "#0F5A43")
    static let inactiveText = Color(hex: "#5F645F")
    static let inactiveStroke = Color(hex: "#B4ADA0")
    static let notePrimary = Color(hex: "#1F2328")
    static let micActive = Color(hex: "#39E6A6")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xff
        let g = (int >> 8) & 0xff
        let b = int & 0xff
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
