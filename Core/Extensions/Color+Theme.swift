import SwiftUI

extension Color {
    static let bgApp = Color(hex: "#0e0e12")
    static let bgSegment = Color(hex: "#1b1d26")
    static let bgCore = Color(hex: "#11131a")
    static let activeMajorFill = Color(hex: "#3a2b66")
    static let activeMajorStroke = Color(hex: "#a89cff")
    static let activeMajorText = Color(hex: "#e1dcff")
    static let activeMinorFill = Color(hex: "#12362d")
    static let activeMinorStroke = Color(hex: "#58d9ad")
    static let activeMinorText = Color(hex: "#d5fff0")
    static let inactiveText = Color(hex: "#8d93ab")
    static let inactiveStroke = Color(hex: "#383b4d")
    static let notePrimary = Color(hex: "#f3f5fb")
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
