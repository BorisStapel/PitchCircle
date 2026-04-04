import SwiftUI

struct SettingsView: View {
    private let backgroundColor = Color(.sRGB, red: 14 / 255, green: 14 / 255, blue: 18 / 255, opacity: 1)

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settingsService: SettingsService

    var body: some View {
        NavigationStack {
            Form {
                Section("Reference Pitch") {
                    Picker("Reference Pitch", selection: referencePitchBinding) {
                        ForEach(ReferencePitch.allCases) { referencePitch in
                            Text(referencePitch.label)
                                .tag(referencePitch)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        settingsService.resetToDefaults()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        appState.isSettingsPresented = false
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var referencePitchBinding: Binding<ReferencePitch> {
        Binding(
            get: { settingsService.settings.referencePitch },
            set: { settingsService.updateReferencePitch($0) }
        )
    }
}
