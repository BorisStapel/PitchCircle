# 1. Create the root directory and folder structure
mkdir -p PitchCircleSource/{App,Features/{Audio/{Models,Services,ViewModels},CircleOfFifths/{Models,Views,ViewModels},Settings/{Models,Services,Views}},Core/{Audio,Music,Extensions},Resources}

cd PitchCircleSource

# 2. Create the PitchResult Model
cat <<EOF > Features/Audio/Models/PitchResult.swift
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
EOF

# 3. Create the Audio Engine Service (The "Ear")
cat <<EOF > Features/Audio/Services/AudioEngineService.swift
import AVFoundation

class AudioEngineService {
    private let engine = AVAudioEngine()
    private let inputBus: AVAudioNodeBus = 0
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func start(onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.mixWithOthers])
        try session.setActive(true)
        
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: inputBus)
        
        inputNode.removeTap(onBus: inputBus)
        inputNode.installTap(onBus: inputBus, bufferSize: 1024, format: format) { buffer, _ in
            DispatchQueue.global(qos: .userInteractive).async {
                onBuffer(buffer)
            }
        }
        try engine.start()
    }
    
    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: inputBus)
    }
}
EOF

# 4. Create the pYIN Processor (The "Brain")
cat <<EOF > Core/Audio/PYINProcessor.swift
import Foundation
import Accelerate

class PYINProcessor {
    private let minHz: Float = 30.0
    private let maxHz: Float = 2000.0
    private let threshold: Float = 0.10
    
    func getPitchCandidates(samples: [Float], sampleRate: Float) -> [(hz: Float, probability: Float)] {
        let n = samples.count
        let maxTau = Int(sampleRate / minHz)
        let minTau = Int(sampleRate / maxHz)
        if n < maxTau { return [] }
        
        var difference = [Float](repeating: 0, count: maxTau)
        for tau in 1..<maxTau {
            var diff: Float = 0
            let length = n - tau
            var subResult = [Float](repeating: 0, count: length)
            vDSP_vsub(samples, 1, Array(samples[tau..<n]), 1, &subResult, 1, vDSP_Length(length))
            vDSP_svesq(subResult, 1, &diff, vDSP_Length(length))
            difference[tau] = diff
        }
        
        var cmnd = [Float](repeating: 1, count: maxTau)
        var runningSum: Float = 0
        for tau in 1..<maxTau {
            runningSum += difference[tau]
            cmnd[tau] = difference[tau] / ((1/Float(tau)) * runningSum)
        }
        
        var candidates: [(hz: Float, probability: Float)] = []
        for tau in minTau..<maxTau - 1 {
            if cmnd[tau] < threshold {
                if cmnd[tau] < cmnd[tau - 1] && cmnd[tau] < cmnd[tau + 1] {
                    candidates.append((hz: sampleRate / Float(tau), probability: 1.0 - cmnd[tau]))
                }
            }
        }
        return candidates.sorted { \$0.probability > \$1.probability }
    }
}
EOF

# 5. Create the Note Converter (The "Translator")
cat <<EOF > Core/Music/NoteConverter.swift
import Foundation

struct NoteConverter {
    static let noteNames = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
    
    static func convert(frequency: Float, referenceA4: Float = 440.0) -> PitchResult? {
        guard frequency > 0 else { return nil }
        let midi = 12 * log2(frequency / referenceA4) + 69
        let roundedMidi = Int(round(midi))
        let octave = (roundedMidi / 12) - 1
        let noteIndex = roundedMidi % 12
        return PitchResult(frequency: Double(frequency), midiNote: roundedMidi, noteName: noteNames[noteIndex], octave: octave, confidence: 0.0)
    }
}
EOF

# 6. Create the Detector Service (The "Coordinator")
cat <<EOF > Features/Audio/Services/PitchDetectorService.swift
import Foundation
import AVFoundation

class PitchDetectorService: ObservableObject {
    private let engineService = AudioEngineService()
    private let processor = PYINProcessor()
    @Published var currentPitch: PitchResult? = nil

    @MainActor
    func start() {
        Task {
            if await engineService.requestPermission() {
                try? engineService.start { [weak self] buffer in
                    self?.analyzeBuffer(buffer)
                }
            }
        }
    }

    private func analyzeBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: Float(buffer.format.sampleRate))
        
        if let top = candidates.first, top.probability > 0.8 {
            let result = NoteConverter.convert(frequency: top.hz)
            DispatchQueue.main.async { self.currentPitch = result }
        } else {
            DispatchQueue.main.async { self.currentPitch = nil }
        }
    }
}
EOF

# 7. Create UI and App Entry
cat <<EOF > App/PitchCircleApp.swift
import SwiftUI

@main
struct PitchCircleApp: App {
    @StateObject private var detector = PitchDetectorService()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(detector).onAppear { detector.start() }
        }
    }
}
EOF

cat <<EOF > App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var detector: PitchDetectorService
    var body: some View {
        VStack(spacing: 20) {
            Text("PitchCircle").font(.headline)
            if let pitch = detector.currentPitch {
                Text(pitch.noteName).font(.system(size: 80, weight: .bold))
                Text("Octave \(pitch.octave)")
            } else {
                Text("Waiting for audio...")
            }
            // Simulator Test Button
            Button("Simulate A4") {
                detector.currentPitch = PitchResult(frequency: 440, midiNote: 69, noteName: "A", octave: 4, confidence: 0.9)
            }.buttonStyle(.bordered)
        }.preferredColorScheme(.dark)
    }
}
EOF

echo "Done! Folder 'PitchCircleSource' is ready."