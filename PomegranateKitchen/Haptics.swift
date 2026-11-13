import CoreHaptics

/// Turns the game's haptic moments into Core Haptics patterns.
///
/// Each pattern is a tiny score made of two kinds of notes:
///   tap  = one instant click   (a .hapticTransient event)
///   buzz = a vibration that lasts a moment   (a .hapticContinuous event)
/// Every note has an intensity (0 = nothing, 1 = strongest) and a
/// sharpness (0 = soft, dull thud; 1 = crisp click).
///
/// To change how a moment feels, edit its numbers in `events(for:)` and run
/// on your iPhone again. The Simulator has no haptics, so test on a real phone.
final class Haptics {
    private var engine: CHHapticEngine?
    private var running = false

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = false
            // iOS stops the engine when the app goes to the background. It restarts on the next event.
            engine.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async { self?.running = false }
            }
            engine.resetHandler = { [weak self] in
                DispatchQueue.main.async {
                    self?.running = false
                    self?.start()
                }
            }
            self.engine = engine
            start()
        } catch {
            print("Core Haptics unavailable: \(error)")
        }
    }

    /// Plays one moment sent from the game: "pop", "burst", "crunch", ...
    func play(_ name: String) {
        guard let engine else { return }
        start()
        let events = Haptics.events(for: name)
        if events.isEmpty { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic '\(name)' failed: \(error)")
        }
    }

    private func start() {
        guard let engine, !running else { return }
        do {
            try engine.start()
            running = true
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }

    // MARK: - How each moment feels

    private static func events(for name: String) -> [CHHapticEvent] {
        // A little randomness so a hundred pops in a row feel organic, not robotic.
        let j = Float.random(in: 0.85...1.0)
        switch name {
        case "pop":
            // An aril pulling free: a faint tug of resistance, then a crisp snap.
            return [buzz(at: 0, for: 0.03, intensity: 0.2 * j, sharpness: 0.2),
                    tap(at: 0.03, intensity: 0.75 * j, sharpness: 0.85)]
        case "burst":
            // Squashing one: a dull hit, then a wet squish that fades.
            return [tap(at: 0, intensity: 0.9, sharpness: 0.25),
                    buzz(at: 0.005, for: 0.14, intensity: 0.55, sharpness: 0.1, fade: true)]
        case "crunch":
            // The knife biting through the rind, repeated as you drag. Random each time, so it feels gritty.
            return [tap(at: 0, intensity: Float.random(in: 0.3...0.55), sharpness: Float.random(in: 0.45...0.75))]
        case "crack":
            // The fruit splitting open.
            return [tap(at: 0, intensity: 1.0, sharpness: 0.5),
                    buzz(at: 0.01, for: 0.2, intensity: 0.65, sharpness: 0.15, fade: true)]
        case "plip":
            // An aril landing in the bowl of water.
            return [tap(at: 0, intensity: 0.22 * j, sharpness: 0.3)]
        case "scoop":
            // Lifting a bit of pith off the water.
            return [buzz(at: 0, for: 0.09, intensity: 0.35, sharpness: 0.3, fade: true),
                    tap(at: 0.06, intensity: 0.4, sharpness: 0.6)]
        case "toss":
            // Tossing an empty half aside: a soft whoosh, then a thud.
            return [buzz(at: 0, for: 0.12, intensity: 0.25, sharpness: 0.05, fade: true),
                    tap(at: 0.13, intensity: 0.6, sharpness: 0.3)]
        case "open":
            // The scored fruit falling open into wedges: a ripple of soft thuds, growing.
            return [tap(at: 0, intensity: 0.5, sharpness: 0.3),
                    tap(at: 0.06, intensity: 0.6, sharpness: 0.3),
                    tap(at: 0.12, intensity: 0.7, sharpness: 0.3),
                    tap(at: 0.18, intensity: 0.8, sharpness: 0.35),
                    tap(at: 0.24, intensity: 0.9, sharpness: 0.4),
                    buzz(at: 0, for: 0.32, intensity: 0.3, sharpness: 0.1, fade: true)]
        case "turn":
            // Turning a wedge in your hand: light ratchet clicks.
            return [tap(at: 0, intensity: 0.35, sharpness: 0.95)]
        case "stuck":
            // Trying to pull an aril that's stuck behind others: a dull double bump.
            return [tap(at: 0, intensity: 0.5, sharpness: 0.15),
                    tap(at: 0.07, intensity: 0.4, sharpness: 0.15)]
        case "success":
            // The results screen: three rising taps.
            return [tap(at: 0, intensity: 0.5, sharpness: 0.6),
                    tap(at: 0.1, intensity: 0.7, sharpness: 0.7),
                    tap(at: 0.22, intensity: 1.0, sharpness: 0.8)]
        default:
            return []
        }
    }

    private static func tap(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                   CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: time)
    }

    private static func buzz(at time: TimeInterval, for duration: TimeInterval,
                             intensity: Float, sharpness: Float, fade: Bool = false) -> CHHapticEvent {
        var parameters = [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                          CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)]
        if fade {
            // Fade out across the whole buzz instead of holding steady.
            parameters.append(CHHapticEventParameter(parameterID: .sustained, value: 0))
            parameters.append(CHHapticEventParameter(parameterID: .decayTime, value: Float(duration)))
        }
        return CHHapticEvent(eventType: .hapticContinuous, parameters: parameters,
                             relativeTime: time, duration: duration)
    }
}
