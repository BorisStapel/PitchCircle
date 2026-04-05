import Foundation
import Testing
@testable import PitchCircle

struct PYINProcessorTests {
    private let processor = PYINProcessor()
    private let sampleRate: Float = 44100.0
    private let bufferSize: Int = 4096

    private func sineWave(frequency: Float, sampleRate: Float, count: Int) -> [Float] {
        (0..<count).map { i in
            sin(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
    }

    @Test
    func detectsConcertA440() {
        let samples = sineWave(frequency: 440, sampleRate: sampleRate, count: bufferSize)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        #expect(!candidates.isEmpty)
        guard let top = candidates.first else { return }
        #expect(abs(top.hz - 440) < 2.0)
        #expect(top.probability > 0.9)
    }

    @Test
    func detectsMiddleC() {
        let samples = sineWave(frequency: 261.63, sampleRate: sampleRate, count: bufferSize)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        #expect(!candidates.isEmpty)
        guard let top = candidates.first else { return }
        #expect(abs(top.hz - 261.63) < 2.0)
        #expect(top.probability > 0.9)
    }

    @Test
    func detectsHighOctaveA880() {
        let samples = sineWave(frequency: 880, sampleRate: sampleRate, count: bufferSize)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        #expect(!candidates.isEmpty)
        guard let top = candidates.first else { return }
        #expect(abs(top.hz - 880) < 3.0)
        #expect(top.probability > 0.9)
    }

    @Test
    func returnsEmptyForSilence() {
        let samples = [Float](repeating: 0, count: bufferSize)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        #expect(candidates.isEmpty)
    }

    @Test
    func returnsEmptyForBufferTooShort() {
        let samples = sineWave(frequency: 440, sampleRate: sampleRate, count: 100)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        #expect(candidates.isEmpty)
    }

    @Test
    func detectsLowFrequency() {
        let samples = sineWave(frequency: 55, sampleRate: sampleRate, count: 8192)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        #expect(!candidates.isEmpty)
        guard let top = candidates.first else { return }
        #expect(abs(top.hz - 55) < 2.0)
    }

    @Test
    func candidatesAreSortedByProbability() {
        let samples = sineWave(frequency: 440, sampleRate: sampleRate, count: bufferSize)
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: sampleRate)

        for i in 0..<(candidates.count - 1) {
            #expect(candidates[i].probability >= candidates[i + 1].probability)
        }
    }
}
