import AppKit
import Foundation

enum SystemSounds {
    static let silent = "None"
    static let defaultSound = "Glass"

    /// Find actual sounds installed on this Mac instead of hard-coding a list.
    static let availableNames: [String] = {
        let directories = [
            "/System/Library/Sounds",
            "/Library/Sounds",
            NSHomeDirectory() + "/Library/Sounds",
        ]
        let extensions: Set<String> = ["aiff", "aif", "wav", "caf", "mp3", "m4a"]
        let names = directories.flatMap { directory -> [String] in
            let urls =
                (try? FileManager.default.contentsOfDirectory(
                    at: URL(fileURLWithPath: directory, isDirectory: true),
                    includingPropertiesForKeys: nil
                )) ?? []
            return
                urls
                .filter { extensions.contains($0.pathExtension.lowercased()) }
                .map { $0.deletingPathExtension().lastPathComponent }
        }
        return Array(Set(names)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }()
}

@MainActor
final class SystemSoundPlayer {
    private var currentSound: NSSound?

    func play(_ name: String) {
        currentSound?.stop()
        currentSound = nil
        guard name != SystemSounds.silent else { return }
        let sound = NSSound(named: NSSound.Name(name))
        currentSound = sound
        sound?.play()
    }
}
