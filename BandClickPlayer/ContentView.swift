import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var audio = AudioEngineManager()

    @State private var okeURL: URL?
    @State private var clickURL: URL?
    @State private var devices: [AudioDevice] = []
    @State private var selectedDeviceID: AudioDeviceID?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Band Click Player")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            fileRow(label: "オケを選択", url: okeURL) { pickFile(for: .oke) }
            fileRow(label: "クリックを選択", url: clickURL) { pickFile(for: .click) }

            Divider()

            HStack {
                Text("Output Device:")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $selectedDeviceID) {
                    Text("— 選択 —").tag(AudioDeviceID?.none)
                    ForEach(devices) { device in
                        Text("\(device.name)  (\(device.outputChannelCount)ch)")
                            .tag(Optional(device.id))
                    }
                }
                .labelsHidden()
                .frame(width: 260)
            }

            HStack(spacing: 0) {
                Text("オケ出力:").frame(width: 110, alignment: .leading)
                Text("Output 1/2").foregroundColor(.secondary)
            }
            HStack(spacing: 0) {
                Text("クリック出力:").frame(width: 110, alignment: .leading)
                Text("Output 3/4").foregroundColor(.secondary)
            }

            Divider()

            HStack(spacing: 12) {
                Button("Play") {
                    if let id = selectedDeviceID { audio.selectDevice(id) }
                    audio.play(okeURL: okeURL!, clickURL: clickURL!)
                }
                .disabled(okeURL == nil || clickURL == nil || audio.isPlaying)
                .buttonStyle(.borderedProminent)

                Button("Stop") { audio.stop() }
                    .disabled(!audio.isPlaying)
                    .buttonStyle(.bordered)
            }

            HStack(spacing: 4) {
                Text("Status:").foregroundColor(.secondary)
                Text(audio.status)
            }
            .font(.callout)
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 300)
        .onAppear {
            devices = AudioDeviceManager.outputDevices()
            selectedDeviceID = AudioDeviceManager.defaultOutputDeviceID()
        }
    }

    @ViewBuilder
    private func fileRow(label: String, url: URL?, action: @escaping () -> Void) -> some View {
        HStack {
            Button(label, action: action)
                .frame(width: 130)
            Text(url?.lastPathComponent ?? "未選択")
                .foregroundColor(url == nil ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private enum FileTarget { case oke, click }

    private func pickFile(for target: FileTarget) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]
        panel.message = target == .oke ? "オケ音源を選択" : "クリック音源を選択"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        switch target {
        case .oke:   okeURL = url
        case .click: clickURL = url
        }
    }
}
