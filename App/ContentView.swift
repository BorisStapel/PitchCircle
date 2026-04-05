import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var detector: PitchDetectorService
    @State private var isSettingsPresented = false

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
            .fullScreenCover(isPresented: $isSettingsPresented) {
                SettingsView()
                    .environmentObject(settingsService)
            }
        }
        .task {
            detector.prepareToListen()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                detector.resumeIfNeeded()
            case .inactive, .background:
                detector.pauseForBackground()
            @unknown default:
                break
            }
        }
    }

    private var header: some View {
        HStack {
            Text("PitchCircle")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.notePrimary)

            Spacer()

            Button {
                isSettingsPresented = true
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
                .font(.system(size: 18, weight: .regular))
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
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.notePrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Button("Continue") {
                detector.requestPermissionAndStart()
            }
            .font(.system(size: 18, weight: .medium))
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
        VStack(spacing: 14) {
            Text(detector.currentPitch?.noteWithOctave ?? "—")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(Color.notePrimary)
                .shadow(color: Color.notePrimary.opacity(0.08), radius: 2)

            CentsArcGauge(cents: detector.displayCents)

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
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.inactiveText)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    private var micStatusBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(detector.isListening ? Color.micActive : Color.inactiveStroke)
                .frame(width: 20, height: 20)
                .scaleEffect(dotScale)
                .opacity(dotOpacity)
                .animation(
                    .easeOut(duration: 0.08),
                    value: detector.inputLevel
                )

            Text("live · \(settingsService.settings.referencePitch.statusLabel)")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.notePrimary)

            Spacer()

            Text(detector.statusMessage.lowercased())
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.inactiveText)
        }
        .padding(.horizontal, 20)
    }

    private var dotScale: CGFloat {
        guard detector.isListening else { return 0.75 }
        return 0.75 + CGFloat(responseLevel) * 1.5
    }

    private var dotOpacity: Double {
        guard detector.isListening else { return 0.2 }
        return 0.35 + responseLevel * 0.65
    }

    private var responseLevel: Double {
        pow(detector.inputLevel, 0.35)
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
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            )
            .shadow(color: strokeColor.opacity(0.14), radius: 3)
    }
}
