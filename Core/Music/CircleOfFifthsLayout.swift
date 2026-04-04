import Foundation

struct CircleOfFifthsLayout {
    static let majorNames = ["C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"]
    static let minorNames = ["Am", "Em", "Bm", "F#m", "C#m", "G#m", "Ebm", "Bbm", "Fm", "Cm", "Gm", "Dm"]

    static func getIndex(forNoteName name: String) -> Int? {
        let normalized = name.replacingOccurrences(of: "♯", with: "#").replacingOccurrences(of: "♭", with: "b")
        let chromaticMap: [String: Int] = [
            "C": 0, "G": 1, "D": 2, "A": 3, "E": 4, "B": 5,
            "F#": 6, "Gb": 6, "Db": 7, "C#": 7, "Ab": 8, "G#": 8,
            "Eb": 9, "D#": 9, "Bb": 10, "A#": 10, "F": 11
        ]
        return chromaticMap[normalized]
    }

    static func majorName(for index: Int) -> String {
        majorNames[normalizedIndex(index)]
    }

    static func minorName(for index: Int) -> String {
        minorNames[normalizedIndex(index)]
    }

    private static func normalizedIndex(_ index: Int) -> Int {
        ((index % majorNames.count) + majorNames.count) % majorNames.count
    }
}
