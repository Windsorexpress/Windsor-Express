import Foundation

// MARK: - Rarity

enum Rarity: String, Codable, CaseIterable {
    case e = "E", d = "D", c = "C", b = "B", a = "A", s = "S", ss = "SS", sss = "SSS"

    var color: String {
        switch self {
        case .e: return "#9E9E9E"
        case .d: return "#4CAF50"
        case .c: return "#2196F3"
        case .b: return "#9C27B0"
        case .a: return "#FF9800"
        case .s: return "#F44336"
        case .ss: return "#FFD700"
        case .sss: return "#FF69B4"
        }
    }

    var weight: Double {
        switch self {
        case .e: return 40
        case .d: return 30
        case .c: return 20
        case .b: return 8
        case .a: return 1.8
        case .s: return 0.18
        case .ss: return 0.02
        case .sss: return 0.001
        }
    }
}

// MARK: - Job

struct Job: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let lore: String
    let emoji: String
    let baseHP: Int
    let baseATK: Int
    let baseDEF: Int
    let baseSPD: Int
    let baseMP: Int
    let startingSkillIDs: [String]
    var isLocked: Bool

    static func == (lhs: Job, rhs: Job) -> Bool { lhs.id == rhs.id }
}

// MARK: - Skill

enum SkillEffect: String, Codable {
    case damage, healing, buff, debuff, summon, shield
}

struct Skill: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let rarity: Rarity
    let mpCost: Int
    let cooldownTurns: Int
    let effect: SkillEffect
    let damageMultiplier: Double
    let healPercent: Double
    let buffKey: String?
    let buffValue: Double
    let buffDuration: Int
    var level: Int = 1

    static func == (lhs: Skill, rhs: Skill) -> Bool { lhs.id == rhs.id }

    var scaledMultiplier: Double { damageMultiplier + Double(level - 1) * 0.15 }
    var scaledHeal: Double { healPercent + Double(level - 1) * 0.03 }
}

// MARK: - Weapon

struct Weapon: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let rarity: Rarity
    let baseATKBonus: Int
    let defBonus: Int
    let mpBonus: Int
    let critChanceBonus: Double
    let critDamageBonus: Double
    let specialEffect: String?
    var enhancement: Int = 0

    var totalATKBonus: Int { baseATKBonus + enhancement * 5 }

    static func == (lhs: Weapon, rhs: Weapon) -> Bool { lhs.id == rhs.id }
}

// MARK: - Enemy

struct Enemy: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let dungeonRank: DungeonRank
    let isBoss: Bool
    let baseHP: Int
    let atk: Int
    let def: Int
    let xpReward: Int
    let goldReward: Int
    var currentHP: Int
    var isEnraged: Bool = false

    init(id: String, name: String, emoji: String, dungeonRank: DungeonRank, isBoss: Bool,
         baseHP: Int, atk: Int, def: Int, xpReward: Int, goldReward: Int) {
        self.id = id; self.name = name; self.emoji = emoji
        self.dungeonRank = dungeonRank; self.isBoss = isBoss
        self.baseHP = baseHP; self.atk = atk; self.def = def
        self.xpReward = xpReward; self.goldReward = goldReward
        self.currentHP = baseHP
    }
}

// MARK: - Dungeon

enum DungeonRank: String, Codable, CaseIterable, Comparable {
    case e = "E", d = "D", c = "C", b = "B", a = "A", s = "S", ss = "SS", sss = "SSS"

    static func < (lhs: DungeonRank, rhs: DungeonRank) -> Bool {
        let order: [DungeonRank] = [.e, .d, .c, .b, .a, .s, .ss, .sss]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }

    var keyCost: Int {
        switch self {
        case .e: return 1; case .d: return 2; case .c: return 3; case .b: return 5
        case .a: return 8; case .s: return 12; case .ss: return 20; case .sss: return 50
        }
    }

    var recommendedLevel: Int {
        switch self {
        case .e: return 1; case .d: return 10; case .c: return 25; case .b: return 45
        case .a: return 70; case .s: return 100; case .ss: return 150; case .sss: return 200
        }
    }

    var xpMultiplier: Double {
        switch self {
        case .e: return 1; case .d: return 2; case .c: return 4; case .b: return 8
        case .a: return 15; case .s: return 30; case .ss: return 60; case .sss: return 150
        }
    }

    var emoji: String {
        switch self {
        case .e: return "🟫"; case .d: return "🟩"; case .c: return "🟦"
        case .b: return "🟪"; case .a: return "🟧"; case .s: return "🟥"
        case .ss: return "⭐"; case .sss: return "👑"
        }
    }
}

// MARK: - Combat State

struct CombatState: Codable {
    var currentEnemies: [Enemy] = []
    var wave: Int = 1
    var maxWaves: Int = 4
    var battleLog: [String] = []
    var skillCooldowns: [String: Int] = [:]
    var activeBuffs: [ActiveBuff] = []
    var shadowSoldiers: [ShadowSoldier] = []
    var dungeonRank: DungeonRank = .e
    var isComplete: Bool = false
    var isBossWave: Bool { wave == maxWaves }
}

struct ActiveBuff: Codable, Identifiable {
    var id = UUID()
    let key: String
    let value: Double
    var turnsRemaining: Int
}

struct ShadowSoldier: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let atk: Int
    var turnsRemaining: Int = 5
}

// MARK: - Gacha

enum BannerType: String, Codable, CaseIterable {
    case skill = "Skill Summon"
    case weapon = "Weapon Forge"
    case jobCrystal = "Job Crystal"
    case shadow = "Shadow Extraction"

    var emoji: String {
        switch self {
        case .skill: return "✨"
        case .weapon: return "⚔️"
        case .jobCrystal: return "💎"
        case .shadow: return "👥"
        }
    }

    var singlePullCost: Int {
        switch self {
        case .skill: return 100; case .weapon: return 150
        case .jobCrystal: return 200; case .shadow: return 0
        }
    }

    var tenPullCost: Int { singlePullCost * 9 }
    var pityThreshold: Int { self == .weapon ? 100 : 80 }
}

enum GachaResult {
    case skill(Skill)
    case weapon(Weapon)
    case jobShard(String)
    case shadowSoldier(ShadowSoldier)
}

// MARK: - Player

struct Player: Codable {
    var id: String = UUID().uuidString
    var name: String = "Hunter"
    var level: Int = 1
    var xp: Int = 0
    var jobID: String = ""
    var jobRank: DungeonRank = .e

    var currentHP: Int = 0
    var maxHP: Int = 1000
    var currentMP: Int = 0
    var maxMP: Int = 300
    var atk: Int = 100
    var def: Int = 80
    var spd: Int = 100

    var gold: Int = 1000
    var manacrystals: Int = 30
    var dungeonKeys: Int = 5
    var enhancementStones: Int = 0

    var equippedSkillIDs: [String] = []
    var inventorySkillIDs: [String] = []
    var inventoryWeaponIDs: [String] = []
    var equippedWeaponID: String? = nil
    var shadowArmyIDs: [String] = []
    var jobShards: [String: Int] = [:]

    var skillLevels: [String: Int] = [:]
    var skillPullCount: Int = 0
    var weaponPullCount: Int = 0

    var lastKeyRegenTime: Date = Date()
    var lastDailyResetTime: Date = Date()
    var dailyQuestsCompleted: [String] = []
    var dailyFreePullAvailable: Bool = true
    var loginStreakDays: Int = 0

    var hasCompletedOnboarding: Bool = false
    var rerollsUsed: Int = 0
    var clearedDungeons: [String: Bool] = [:]
    var totalDungeonsCleared: Int = 0
    var totalSkillCasts: Int = 0
    var totalBurstHits: Int = 0

    var xpToNextLevel: Int { level * 100 + (level * level * 10) }

    mutating func applyJob(_ job: Job) {
        jobID = job.id
        maxHP = job.baseHP + (level - 1) * 10
        maxMP = job.baseMP + (level - 1) * 5
        atk = job.baseATK + (level - 1) * 5
        def = job.baseDEF + (level - 1) * 3
        spd = job.baseSPD
        currentHP = maxHP
        currentMP = maxMP
    }

    mutating func gainXP(_ amount: Int) {
        xp += amount
        while xp >= xpToNextLevel && level < 200 {
            xp -= xpToNextLevel
            level += 1
            maxHP += 10; maxMP += 5; atk += 5; def += 3
            currentHP = maxHP; currentMP = maxMP
        }
    }
}

// MARK: - Daily Quest

struct DailyQuest: Identifiable, Codable {
    let id: String
    let description: String
    let emoji: String
    var progress: Int
    let target: Int
    var isComplete: Bool { progress >= target }
    let goldReward: Int
    let mcReward: Int
}
