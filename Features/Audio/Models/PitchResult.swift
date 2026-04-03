import Foundation

struct PitchResult: Equatable {
    let frequency: Double
    let midiNote: Int
    let noteName: String
    let octave: Int
    let confidence: Double

    static func == (lhs: PitchResult, rhs: PitchResult) -> Bool {
        return lhs.midiNote == rhs.midiNote && lhs.octave == rhs.octave
    }
}
