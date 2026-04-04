import SwiftUI

extension Color {
    static let bgApp = Color(hex: "#0e0e12")
    static let bgSegment = Color(hex: "#14141c")
    static let bgCore = Color(hex: "#09090f")
    static let activeMajorFill = Color(hex: "#2a1e4a")
    static let activeMajorStroke = Color(hex: "#7F77DD")
    static let activeMajorText = Color(hex: "#AFA9EC")
    static let activeMinorFill = Color(hex: "#0d2620")
    static let activeMinorStroke = Color(hex: "#1D9E75")
    static let activeMinorText = Color(hex: "#5DCAA5")
    static let inactiveText = Color(hex: "#3a3a52")
    static let inactiveStroke = Color(hex: "#22222e")
    static let notePrimary = Color(hex: "#e8e8f0")
    static let micActive = Color(hex: "#1D9E75")

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
