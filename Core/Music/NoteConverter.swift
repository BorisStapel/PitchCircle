import Foundation

struct NoteConverter: Sendable {
    nonisolated static func convert(frequency: Float, referenceA4: Float = 440.0, confidence: Float = 0.0) -> PitchResult? {
        guard frequency > 0 else { return nil }

        let noteNames = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
        let midi = 12 * log2(frequency / referenceA4) + 69
        let roundedMidi = Int(round(midi))
        let cents = Double((midi - Float(roundedMidi)) * 100)
        let octave = (roundedMidi / 12) - 1
        let noteIndex = ((roundedMidi % 12) + 12) % 12

        return PitchResult(
            frequency: Double(frequency),
            midiNote: roundedMidi,
            noteName: noteNames[noteIndex],
            octave: octave,
            confidence: confidence,
            cents: cents
        )
    }
}
