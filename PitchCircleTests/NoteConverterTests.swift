import Testing
@testable import PitchCircle

struct NoteConverterTests {
    @Test
    func convertsConcertAAtA440() {
        let result = NoteConverter.convert(frequency: 440)

        #expect(result?.noteName == "A")
        #expect(result?.octave == 4)
        #expect(result?.midiNote == 69)
    }

    @Test
    func convertsMiddleC() {
        let result = NoteConverter.convert(frequency: 261.63)

        #expect(result?.noteName == "C")
        #expect(result?.octave == 4)
        #expect(result?.midiNote == 60)
    }

    @Test
    func rejectsInvalidFrequency() {
        #expect(NoteConverter.convert(frequency: 0) == nil)
        #expect(NoteConverter.convert(frequency: -1) == nil)
    }

    @Test
    func respectsReferencePitch() {
        let a440Result = NoteConverter.convert(frequency: 432, referenceA4: 440)
        let a432Result = NoteConverter.convert(frequency: 432, referenceA4: 432)

        #expect(a440Result?.noteName == "A")
        #expect(a440Result?.octave == 4)
        #expect(a440Result?.midiNote == 69)
        #expect(a432Result?.noteName == "A")
        #expect(a432Result?.octave == 4)
        #expect(a432Result?.midiNote == 69)
        #expect(abs((a432Result?.cents ?? 999) - 0) < 0.01)
        #expect(abs((a440Result?.cents ?? 0)) > 0.01)
    }
}
