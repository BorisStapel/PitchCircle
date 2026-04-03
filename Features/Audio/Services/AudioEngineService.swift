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
