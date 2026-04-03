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
