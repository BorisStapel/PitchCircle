import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var detector: PitchDetectorService

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgApp.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 28) {
                    header

                    Group {
                        switch detector.permissionState {
                        case .denied:
                            deniedBanner
                        case .undetermined:
                            permissionPrompt
                        case .granted:
                            CircleOfFifthsView()
                        }
                    }
                    .frame(maxWidth: .infinity)

                    noteDisplay

                    micStatusBar

                    Spacer(minLength: 0)
                }
            }
            .sheet(isPresented: $appState.isSettingsPresented) {
                SettingsView()
                    .environmentObject(appState)
                    .environmentObject(settingsService)
            }
        }
        .task {
            detector.prepareToListen()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            detector.refreshPermissionState()
            detector.prepareToListen()
        }
    }

    private var header: some View {
        HStack {
            Text("PitchCircle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.notePrimary)

            Spacer()

            Button {
                appState.isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.notePrimary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
    }

    private var deniedBanner: some View {
        Button {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
        } label: {
            Text("Microphone access is required. Tap to open Settings.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.notePrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 264)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.bgSegment)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.inactiveStroke, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var permissionPrompt: some View {
        VStack(spacing: 16) {
            Text("PitchCircle listens to your microphone to detect musical pitch. Audio is processed entirely on-device.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.notePrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Button("Continue") {
                detector.requestPermissionAndStart()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.notePrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.activeMajorFill)
            )
        }
        .frame(maxWidth: .infinity, minHeight: 264)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.bgSegment)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.inactiveStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private var noteDisplay: some View {
        VStack(spacing: 12) {
            Text(detector.currentPitch?.noteWithOctave ?? "—")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Color.notePrimary)

            HStack(spacing: 10) {
                pillLabel(
                    detector.currentPitch?.majorKeyName ?? "—",
                    fillColor: .activeMajorFill,
                    strokeColor: .activeMajorStroke,
                    textColor: .activeMajorText
                )

                pillLabel(
                    detector.currentPitch?.relativeMinorName ?? "—",
                    fillColor: .activeMinorFill,
                    strokeColor: .activeMinorStroke,
                    textColor: .activeMinorText
                )
            }

            Text(frequencyText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.inactiveText)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private var micStatusBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(detector.isListening ? Color.micActive : Color.inactiveStroke)
                .frame(width: 10, height: 10)
                .scaleEffect(detector.isListening ? 1.0 : 0.8)
                .opacity(detector.isListening ? 1.0 : 0.55)
                .animation(
                    detector.isListening
                    ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                    : .easeInOut(duration: 0.2),
                    value: detector.isListening
                )

            Text("live · \(settingsService.settings.referencePitch.statusLabel)")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.notePrimary)

            Spacer()

            Text(detector.statusMessage.lowercased())
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.inactiveText)
        }
        .padding(.horizontal, 20)
    }

    private var frequencyText: String {
        guard let frequency = detector.currentPitch?.frequency else {
            return "No pitch detected"
        }

        return String(format: "%.1f Hz", frequency)
    }

    private func pillLabel(
        _ title: String,
        fillColor: Color,
        strokeColor: Color,
        textColor: Color
    ) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            )
    }
}
