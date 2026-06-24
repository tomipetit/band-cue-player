import AVFoundation
import CoreAudio

@MainActor
final class AudioEngineManager: ObservableObject {
    @Published var status: String = "Ready"
    @Published var isPlaying: Bool = false

    private var engine = AVAudioEngine()
    private var okePlayer = AVAudioPlayerNode()
    private var clickPlayer = AVAudioPlayerNode()
    private var selectedDeviceID: AudioDeviceID?

    func selectDevice(_ id: AudioDeviceID) {
        selectedDeviceID = id
    }

    func play(okeURL: URL, clickURL: URL) {
        do {
            if engine.isRunning {
                okePlayer.stop()
                clickPlayer.stop()
                engine.stop()
            }

            engine = AVAudioEngine()
            okePlayer = AVAudioPlayerNode()
            clickPlayer = AVAudioPlayerNode()
            engine.attach(okePlayer)
            engine.attach(clickPlayer)

            if let id = selectedDeviceID {
                try applyDevice(id)
            }

            let okeFile = try AVAudioFile(forReading: okeURL)
            let clickFile = try AVAudioFile(forReading: clickURL)

            let sampleRate: Double
            if let id = selectedDeviceID {
                sampleRate = AudioDeviceManager.nominalSampleRate(id)
            } else {
                sampleRate = 44100
            }
            let stereo = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            let outputNode = engine.outputNode

            let chCount = selectedDeviceID.flatMap { AudioDeviceManager.outputChannelCount($0) } ?? 2
            if chCount >= 4 {
                // oke → Output 1/2 (bus 0), click → Output 3/4 (bus 1)
                engine.connect(okePlayer, to: outputNode, fromBus: 0, toBus: 0, format: stereo)
                engine.connect(clickPlayer, to: outputNode, fromBus: 0, toBus: 1, format: stereo)
            } else {
                let mixer = engine.mainMixerNode
                engine.connect(okePlayer, to: mixer, fromBus: 0, toBus: mixer.nextAvailableInputBus, format: stereo)
                engine.connect(clickPlayer, to: mixer, fromBus: 0, toBus: mixer.nextAvailableInputBus, format: stereo)
            }

            okePlayer.scheduleFile(okeFile, at: nil)
            clickPlayer.scheduleFile(clickFile, at: nil)

            engine.prepare()
            try engine.start()

            let startTime = AVAudioTime(hostTime: mach_absolute_time() + toHostTime(0.1))
            okePlayer.play(at: startTime)
            clickPlayer.play(at: startTime)

            isPlaying = true
            status = "Playing"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }

    func stop() {
        okePlayer.stop()
        clickPlayer.stop()
        engine.stop()
        isPlaying = false
        status = "Stopped"
    }

    private func applyDevice(_ deviceID: AudioDeviceID) throws {
        var id = deviceID
        guard let au = engine.outputNode.audioUnit else { return }
        let err = AudioUnitSetProperty(
            au,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &id,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        if err != noErr {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err))
        }
    }

    private func toHostTime(_ seconds: Double) -> UInt64 {
        var tb = mach_timebase_info_data_t()
        mach_timebase_info(&tb)
        let nanos = UInt64(seconds * 1_000_000_000)
        return nanos * UInt64(tb.denom) / UInt64(tb.numer)
    }
}
