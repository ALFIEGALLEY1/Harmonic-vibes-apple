import SwiftUI
import MediaPlayer

struct SettingsView: View {
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled = true
    @AppStorage("selectedStreamQuality") private var selectedStreamQuality = "High"
    @AppStorage("isBackgroundPlaybackEnabled") private var isBackgroundPlaybackEnabled = true
    @AppStorage("selectedVolumeLevel") private var selectedVolumeLevel = 50.0
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @AppStorage("isDataSaverEnabled") private var isDataSaverEnabled = false  // Data Saver Mode setting
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Audio Settings")) {
                    Picker("Stream Quality", selection: $selectedStreamQuality) {
                        Text("High").tag("High")
                        Text("Medium").tag("Medium")
                        Text("Low").tag("Low")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: isDataSaverEnabled) { newValue in
                        if newValue {
                            selectedStreamQuality = "Low"  // Automatically switch to low when Data Saver is enabled
                        }
                    }

                    Toggle("Enable Notifications", isOn: $isNotificationsEnabled)
                        .padding()

                    Toggle("Enable Background Playback", isOn: $isBackgroundPlaybackEnabled)
                        .padding()

                    Slider(value: $selectedVolumeLevel, in: 0...100, step: 1) {
                        Text("Volume Level")
                    }
                    .padding()
                    
                    // Volume control using MPVolumeView
                    MPVolumeViewWrapper()
                        .frame(height: 50)
                        .padding()
                }

                Section(header: Text("Appearance Settings")) {
                    Toggle("Enable Dark Mode", isOn: $isDarkModeEnabled)
                        .padding()
                }

                Section(header: Text("Data Saver Settings")) { // New section for Data Saver
                    Toggle("Enable Data Saver Mode", isOn: $isDataSaverEnabled)
                        .padding()
                }

                Section(header: Text("General Settings")) {
                    Button("Clear Cache") {
                        clearCache()
                    }
                    .padding()

                    Button("Reset Settings") {
                        resetSettings()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss the view or save changes (handle as needed)
                print("Settings Saved!")
            })
            .onChange(of: isDarkModeEnabled) { newValue in
                // Handle theme change (Dark/Light Mode)
                if newValue {
                    // Enable dark mode
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
                } else {
                    // Enable light mode
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
                }
            }
        }
    }
    
    // Function to clear cache (or other stored data)
    func clearCache() {
        // Implement the logic to clear the app's cache
        print("Cache cleared!")
    }
    
    // Function to reset all settings to their defaults
    func resetSettings() {
        isNotificationsEnabled = true
        selectedStreamQuality = "High"
        isBackgroundPlaybackEnabled = true
        selectedVolumeLevel = 50.0
        isDarkModeEnabled = false
        isDataSaverEnabled = false  // Reset Data Saver Mode
    }
}

struct MPVolumeViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        return MPVolumeView()
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // No need to update as it's handled by system
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
