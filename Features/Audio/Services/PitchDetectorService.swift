import Foundation
import AVFoundation
import SwiftUI
import Combine

class PitchDetectorService: ObservableObject {
    @Published var currentPitch: PitchResult? = nil
    @Published var statusMessage: String = "Idle"
    
    private let engineService = AudioEngineService()
    // Ensure PYINProcessor is accessible in your Core/Audio folder
    private let processor = PYINProcessor()

    @MainActor
    func start() {
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            if granted {
                self.statusMessage = "Listening..."
                self.startAudioEngine()
            } else {
                self.statusMessage = "Mic Denied"
            }
        }
    }

    private func startAudioEngine() {
        do {
            try engineService.start { [weak self] buffer in
                self?.analyzeBuffer(buffer)
            }
        } catch {
            print("Engine Error: \(error)")
        }
    }

    private func analyzeBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: Float(buffer.format.sampleRate))
        
        // FR-08: Confidence threshold (0.7 as per PRD)
        if let top = candidates.first, top.probability > 0.7 {
            if let result = NoteConverter.convert(frequency: top.hz) {
                DispatchQueue.main.async {
                    self.currentPitch = result
                }
            }
        } else {
            DispatchQueue.main.async {
                self.currentPitch = nil
            }
        }
    }
}
