import Foundation

struct PitchResult: Equatable {
    let frequency: Double
    let midiNote: Int
    let noteName: String
    let octave: Int
    let confidence: Float
    let cents: Double
    
    var coFIndex: Int? {
        CircleOfFifthsLayout.getIndex(forNoteName: noteName)
    }

    var noteWithOctave: String {
        "\(noteName)\(octave)"
    }

    var majorKeyName: String? {
        guard let index = coFIndex else { return nil }
        return "\(CircleOfFifthsLayout.majorName(for: index)) major"
    }

    var relativeMinorName: String? {
        guard let index = coFIndex else { return nil }
        return CircleOfFifthsLayout.minorName(for: index)
    }
}
