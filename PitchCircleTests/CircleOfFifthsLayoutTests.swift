import Testing
@testable import PitchCircle

struct CircleOfFifthsLayoutTests {
    @Test
    func mapsStandardNotesToExpectedIndices() {
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "C") == 0)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "G") == 1)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "D") == 2)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "A") == 3)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "E") == 4)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "B") == 5)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "F#") == 6)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "Db") == 7)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "Ab") == 8)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "Eb") == 9)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "Bb") == 10)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "F") == 11)
    }

    @Test
    func mapsEnharmonicSpellingsToSameIndex() {
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "Gb") == 6)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "C#") == 7)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "G#") == 8)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "D#") == 9)
        #expect(CircleOfFifthsLayout.getIndex(forNoteName: "A#") == 10)
    }

    @Test
    func returnsParallelMajorAndMinorNamesForIndex() {
        #expect(CircleOfFifthsLayout.majorName(for: 0) == "C")
        #expect(CircleOfFifthsLayout.minorName(for: 0) == "Am")
        #expect(CircleOfFifthsLayout.majorName(for: 11) == "F")
        #expect(CircleOfFifthsLayout.minorName(for: 11) == "Dm")
        #expect(CircleOfFifthsLayout.majorName(for: 12) == "C")
        #expect(CircleOfFifthsLayout.minorName(for: -1) == "Dm")
    }
}
