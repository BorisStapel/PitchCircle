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
    private let confidenceThreshold: Float = 0.95
    private let levelSmoothingFactor: Float = 0.2
    private let centsSmoothingFactor: Double = 0.08
    private let centsDeadband: Double = 5.0
    private let maxDisplayCentsStep: Double = 2.5
    private let centsSampleWindowSize: Int = 5

    @Published private(set) var currentPitch: PitchResult?
    @Published private(set) var displayCents: Double?
    @Published private(set) var statusMessage: String = "Ready"
    @Published private(set) var permissionState: MicrophonePermissionState = .undetermined
    @Published private(set) var isListening = false
    @Published private(set) var inputLevel: Double = 0

    private let engineService = AudioEngineService()
    private let processor = PYINProcessor()
    private let settingsService: SettingsService
    private var shouldResumeAfterInterruption = false
    private var wasListeningBeforeBackground = false
    private var recentCentsSamples: [Double] = []
    private var cancellables = Set<AnyCancellable>()

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
        refreshPermissionState()
        observeAudioInterruptions()
        observeSettingsChanges()
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
                displayCents = nil
                isListening = false
            }
        }
    }

    private func startAudioEngine() {
        guard !engineService.isRunning else { return }

        let referencePitch = Float(settingsService.settings.referencePitch.rawValue)
        let threshold = confidenceThreshold
        let processor = self.processor
        let smoothingFactor = levelSmoothingFactor

        do {
            try engineService.start { [weak self] buffer in
                self?.processAudioBuffer(
                    buffer,
                    referencePitch: referencePitch,
                    confidenceThreshold: threshold,
                    processor: processor,
                    smoothingFactor: smoothingFactor
                )
            }
            statusMessage = "Listening..."
            isListening = true
        } catch {
            statusMessage = "Audio unavailable"
            isListening = false
            print("Engine Error: \(error)")
        }
    }

    nonisolated private func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        referencePitch: Float,
        confidenceThreshold: Float,
        processor: PYINProcessor,
        smoothingFactor: Float
    ) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))

        let rms = Self.computeRMS(samples: samples)

        let candidates = processor.getPitchCandidates(samples: samples, sampleRate: Float(buffer.format.sampleRate))

        let pitchResult: PitchResult?
        if let top = candidates.first, top.probability >= confidenceThreshold {
            pitchResult = NoteConverter.convert(
                frequency: top.hz,
                referenceA4: referencePitch,
                confidence: top.probability
            )
        } else {
            pitchResult = nil
        }

        Task { @MainActor [weak self] in
            self?.applyResults(pitch: pitchResult, rms: rms, smoothingFactor: smoothingFactor)
        }
    }

    private func applyResults(pitch: PitchResult?, rms: Float, smoothingFactor: Float) {
        currentPitch = pitch
        updateDisplayCents(with: pitch?.cents)

        let normalizedLevel = min(max(rms * 30, 0), 1)
        let smoothedLevel = (Float(inputLevel) * (1 - smoothingFactor)) + (normalizedLevel * smoothingFactor)
        inputLevel = Double(smoothedLevel)
    }

    private func updateDisplayCents(with newValue: Double?) {
        guard let newValue else {
            recentCentsSamples.removeAll(keepingCapacity: true)
            displayCents = nil
            return
        }

        recentCentsSamples.append(newValue)
        if recentCentsSamples.count > centsSampleWindowSize {
            recentCentsSamples.removeFirst(recentCentsSamples.count - centsSampleWindowSize)
        }

        let stabilizedValue = median(of: recentCentsSamples)

        guard let previousValue = displayCents else {
            displayCents = stabilizedValue
            return
        }

        guard abs(stabilizedValue - previousValue) >= centsDeadband else {
            return
        }

        let smoothedDelta = (stabilizedValue - previousValue) * centsSmoothingFactor
        let limitedDelta = min(max(smoothedDelta, -maxDisplayCentsStep), maxDisplayCentsStep)
        displayCents = previousValue + limitedDelta
    }

    private func median(of values: [Double]) -> Double {
        let sortedValues = values.sorted()
        let middleIndex = sortedValues.count / 2

        if sortedValues.count.isMultiple(of: 2) {
            return (sortedValues[middleIndex - 1] + sortedValues[middleIndex]) / 2
        }

        return sortedValues[middleIndex]
    }

    nonisolated private static func computeRMS(samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let meanSquare = samples.reduce(Float.zero) { $0 + ($1 * $1) } / Float(samples.count)
        return sqrt(meanSquare)
    }

    func stopListening() {
        engineService.stop()
        currentPitch = nil
        displayCents = nil
        isListening = false
        inputLevel = 0
        statusMessage = permissionState == .granted ? "Paused" : "Microphone access denied"
    }

    func pauseForBackground() {
        guard isListening else {
            wasListeningBeforeBackground = false
            return
        }
        wasListeningBeforeBackground = true
        stopListening()
        statusMessage = "Paused"
    }

    func resumeIfNeeded() {
        refreshPermissionState()
        guard wasListeningBeforeBackground else { return }
        wasListeningBeforeBackground = false
        prepareToListen()
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

    private func observeSettingsChanges() {
        settingsService.$settings
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isListening else { return }
                    self.engineService.stop()
                    self.startAudioEngine()
                }
            }
            .store(in: &cancellables)
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
