import AVFoundation
import Combine

@MainActor
final class AudioLevelMonitor: ObservableObject {
    @Published private(set) var normalizedLevel: CGFloat = 0

    private var engine: AVAudioEngine?
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let level = self.computeLevel(buffer: buffer)
            DispatchQueue.main.async {
                self.normalizedLevel = CGFloat(min(level * 3.0, 1.0))
            }
        }

        do {
            try audioEngine.start()
            engine = audioEngine
            isRunning = true
        } catch {
            print("AudioLevelMonitor: Failed to start engine: \(error)")
        }
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        isRunning = false
        normalizedLevel = 0
    }

    private func computeLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        let channel = UnsafeBufferPointer(start: channelData[0], count: frameLength)
        let rms = sqrt(channel.reduce(0) { $0 + $1 * $1 } / Float(frameLength))
        return rms.isFinite ? rms : 0
    }
}
