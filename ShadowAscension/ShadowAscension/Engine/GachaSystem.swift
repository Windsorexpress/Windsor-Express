import Foundation

// GachaSystem is a lightweight helper used by GameState.
// All pull logic lives in GameState; this file holds animation/display helpers.

enum GachaAnimationPhase {
    case idle, pulling, revealing([GachaResult])
}

struct GachaResultDisplay: Identifiable {
    let id = UUID()
    let result: GachaResult
    var isRevealed: Bool = false

    var emoji: String {
        switch result {
        case .skill(let s): return s.emoji
        case .weapon(let w): return w.emoji
        case .jobShard(let name): return "💎"
        case .shadowSoldier(let s): return s.emoji
        }
    }

    var name: String {
        switch result {
        case .skill(let s): return s.name
        case .weapon(let w): return w.name
        case .jobShard(let name): return "\(name) Shard"
        case .shadowSoldier(let s): return s.name
        }
    }

    var rarity: Rarity {
        switch result {
        case .skill(let s): return s.rarity
        case .weapon(let w): return w.rarity
        case .jobShard: return .c
        case .shadowSoldier: return .d
        }
    }

    var rarityColor: String { rarity.color }
}
