import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
                .listRowBackground(Color.bgSegment)

                Section {
                    Text("Changes apply immediately and are stored for the next launch.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.inactiveText)
                        .listRowBackground(Color.bgApp)
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        settingsService.resetToDefaults()
                    }
                    .foregroundStyle(Color.notePrimary)
                }
                .listRowBackground(Color.bgSegment)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgApp)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.activeMajorStroke)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("PitchCircle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.notePrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color.bgApp.ignoresSafeArea())
    }

    private var referencePitchBinding: Binding<ReferencePitch> {
        Binding(
            get: { settingsService.settings.referencePitch },
            set: { settingsService.updateReferencePitch($0) }
        )
    }
}
