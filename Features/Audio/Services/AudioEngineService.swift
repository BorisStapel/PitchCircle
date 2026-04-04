import AVFoundation

final class AudioEngineService {
    private let engine = AVAudioEngine()
    private let inputBus: AVAudioNodeBus = 0

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
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    var isRunning: Bool {
        engine.isRunning
    }
}
