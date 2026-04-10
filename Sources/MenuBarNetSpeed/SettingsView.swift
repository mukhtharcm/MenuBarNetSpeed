import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @Binding var isPresented: Bool
    var onThresholdEnabled: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            VStack(spacing: 6) {
                settingsRow("Refresh Interval") {
                    Picker("", selection: $settings.refreshInterval) {
                        Text("1s").tag(1.0)
                        Text("2s").tag(2.0)
                        Text("5s").tag(5.0)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                settingsRow("Menu Bar Display") {
                    Picker("", selection: $settings.menuBarDisplayMode) {
                        ForEach(MenuBarDisplayMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }

                settingsRow("Show Network Name") {
                    Toggle("", isOn: $settings.showNetworkName)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                settingsRow("Use Bits per Second") {
                    Toggle("", isOn: $settings.useBitsPerSecond)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                settingsRow("Speed Alert") {
                    Toggle("", isOn: $settings.speedThresholdEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: settings.speedThresholdEnabled) { enabled in
                            if enabled {
                                onThresholdEnabled?()
                            }
                        }
                }

                if settings.speedThresholdEnabled {
                    settingsRow("Alert Threshold") {
                        HStack(spacing: 4) {
                            Picker("", selection: $settings.speedThresholdMBps) {
                                Text("1 MB/s").tag(1.0)
                                Text("5 MB/s").tag(5.0)
                                Text("10 MB/s").tag(10.0)
                                Text("50 MB/s").tag(50.0)
                                Text("100 MB/s").tag(100.0)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 110)
                        }
                    }
                }

                settingsRow("Launch at Login") {
                    Toggle("", isOn: $settings.launchAtLogin)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 300)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Text("Settings")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            // Invisible spacer to balance the back button
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                Text("Back")
                    .font(.system(size: 12))
            }
            .opacity(0)
        }
    }

    // MARK: - Row

    private func settingsRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))

            Spacer()

            content()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }
}
