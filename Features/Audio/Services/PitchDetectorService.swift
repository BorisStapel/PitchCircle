import Foundation
import AVFoundation
import SwiftUI
import Combine

enum MicrophonePermissionState {
    case undetermined
    case granted
    case denied
}

@MainActor
final class PitchDetectorService: ObservableObject {
    private let confidenceThreshold: Float = 0.7
    private let levelSmoothingFactor: Float = 0.2

    @Published private(set) var currentPitch: PitchResult?
    @Published private(set) var statusMessage: String = "Ready"
    @Published private(set) var permissionState: MicrophonePermissionState = .undetermined
    @Published private(set) var isListening = false
    @Published private(set) var inputLevel: Double = 0

    private let engineService = AudioEngineService()
    private let processor = PYINProcessor()
    private let settingsService: SettingsService
    private var shouldResumeAfterInterruption = false

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
        refreshPermissionState()
        observeAudioInterruptions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func prepareToListen() {
        refreshPermissionState()

        guard permissionState == .granted, !isListening else {
            if permissionState == .undetermined {
                statusMessage = "Microphone access required"
            } else if permissionState == .denied {
                statusMessage = "Microphone access denied"
            }
            return
        }

        startAudioEngine()
    }

    func requestPermissionAndStart() {
        Task {
            let granted = await requestMicrophonePermission()

            permissionState = granted ? .granted : .denied
            statusMessage = granted ? "Listening..." : "Microphone access denied"

            if granted {
                startAudioEngine()
            } else {
                currentPitch = nil
                isListening = false
            }
        }
    }

    private func startAudioEngine() {
        guard !engineService.isRunning else { return }

        do {
            try engineService.start { [weak self] buffer in
                self?.analyzeBuffer(buffer)
            }
            statusMessage = "Listening..."
            isListening = true
        } catch {
            statusMessage = "Audio unavailable"
            isListening = false
            print("Engine Error: \(error)")
        }
    }

    private func analyzeBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        updateInputLevel(with: samples)

        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: Float(buffer.format.sampleRate))

        if let top = candidates.first, top.probability >= confidenceThreshold {
            let referencePitch = Float(settingsService.settings.referencePitch.rawValue)

            if let result = NoteConverter.convert(
                frequency: top.hz,
                referenceA4: referencePitch,
                confidence: top.probability
            ) {
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

    func stopListening() {
        engineService.stop()
        currentPitch = nil
        isListening = false
        inputLevel = 0
        statusMessage = permissionState == .granted ? "Paused" : "Microphone access denied"
    }

    func refreshPermissionState() {
        switch currentMicrophonePermissionState() {
        case .granted:
            permissionState = .granted
            statusMessage = isListening ? "Listening..." : "Ready"
        case .denied:
            permissionState = .denied
            statusMessage = "Microphone access denied"
        case .undetermined:
            permissionState = .undetermined
            statusMessage = "Microphone access required"
        }
    }

    private func currentMicrophonePermissionState() -> MicrophonePermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .notDetermined:
            return .undetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func updateInputLevel(with samples: [Float]) {
        guard !samples.isEmpty else { return }

        let meanSquare = samples.reduce(Float.zero) { partialResult, sample in
            partialResult + (sample * sample)
        } / Float(samples.count)
        let rms = sqrt(meanSquare)
        let normalizedLevel = min(max(rms * 30, 0), 1)
        let smoothedLevel = (Float(inputLevel) * (1 - levelSmoothingFactor)) + (normalizedLevel * levelSmoothingFactor)

        DispatchQueue.main.async {
            self.inputLevel = Double(smoothedLevel)
        }
    }

    private func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch interruptionType {
        case .began:
            shouldResumeAfterInterruption = isListening
            stopListening()
            statusMessage = "Interrupted"
        case .ended:
            refreshPermissionState()

            if shouldResumeAfterInterruption && permissionState == .granted {
                shouldResumeAfterInterruption = false
                startAudioEngine()
            }
        @unknown default:
            break
        }
    }
}
