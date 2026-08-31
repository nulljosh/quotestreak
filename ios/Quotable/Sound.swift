import AVFoundation

/// The web game's two beeps (game.js `beep()`): 660Hz on a correct answer, 180Hz on a miss,
/// at the user's chosen volume. Synthesised rather than shipped as audio files so the tones
/// stay identical to the oscillator the browser builds.
enum Sound {
    private static let engine = AVAudioEngine()
    private static var phase = 0.0
    private static var phaseStep = 0.0
    private static var remaining = 0
    private static var amplitude = 0.0
    private static var started = false

    static func play(frequency: Double, duration: Double, volume: Double) {
        guard volume > 0 else { return }
        start()
        let rate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        phase = 0
        phaseStep = 2 * .pi * frequency / rate
        amplitude = volume * 0.2
        remaining = Int(duration * rate)
    }

    static func correct(volume: Double) { play(frequency: 660, duration: 0.15, volume: volume) }
    static func wrong(volume: Double) { play(frequency: 180, duration: 0.25, volume: volume) }

    private static func start() {
        guard !started else { return }
        let format = engine.outputNode.inputFormat(forBus: 0)
        let source = AVAudioSourceNode { _, _, frameCount, buffers in
            let out = UnsafeMutableAudioBufferListPointer(buffers)
            for frame in 0..<Int(frameCount) {
                var sample = 0.0
                // Reading the shared state off the audio thread is safe here: only whole
                // Doubles/Ints are touched and a torn beep is inaudible.
                if remaining > 0 {
                    sample = sin(phase) * amplitude
                    phase += phaseStep
                    remaining -= 1
                }
                for buffer in out {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = Float(sample)
                }
            }
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        try? engine.start()
        started = engine.isRunning
    }
}
