import Foundation

enum SaveSystem {
    private static let playerKey = "shadow_ascension_player"
    private static let versionKey = "shadow_ascension_version"
    private static let currentVersion = 1

    static func save(_ player: Player) {
        guard let data = try? JSONEncoder().encode(player) else { return }
        UserDefaults.standard.set(data, forKey: playerKey)
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    static func load() -> Player? {
        guard let data = UserDefaults.standard.data(forKey: playerKey),
              let player = try? JSONDecoder().decode(Player.self, from: data) else { return nil }
        return player
    }

    static func delete() {
        UserDefaults.standard.removeObject(forKey: playerKey)
    }
}
