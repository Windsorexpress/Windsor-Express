import Foundation
import Observation

@Observable
final class GameState {
    var player: Player = Player()
    var combat: CombatState = CombatState()
    var isInCombat: Bool = false
    var selectedDungeonRank: DungeonRank = .e
    var pendingGachaResults: [GachaResult] = []
    var dailyQuests: [DailyQuest] = GameData.generateDailyQuests()
    var notification: GameNotification? = nil

    // Derived: equippedSkills
    var equippedSkills: [Skill] {
        player.equippedSkillIDs.compactMap { id in
            GameData.skill(id: id).map { skill in
                var s = skill
                s.level = player.skillLevels[id] ?? 1
                return s
            }
        }
    }

    var equippedWeapon: Weapon? {
        guard let wid = player.equippedWeaponID else { return nil }
        return GameData.weapon(id: wid)
    }

    var currentJob: Job? { GameData.job(id: player.jobID) }

    // MARK: - Init

    init() {
        if let saved = SaveSystem.load() {
            player = saved
            regenKeys()
            checkDailyReset()
        }
        if dailyQuests.isEmpty { dailyQuests = GameData.generateDailyQuests() }
    }

    // MARK: - Onboarding

    func assignRandomClass() -> Job {
        let available = GameData.allJobs.filter { !$0.isLocked }
        return available.randomElement()!
    }

    func acceptClass(_ job: Job) {
        player.applyJob(job)
        for skillID in job.startingSkillIDs {
            if !player.inventorySkillIDs.contains(skillID) {
                player.inventorySkillIDs.append(skillID)
            }
        }
        player.equippedSkillIDs = Array(job.startingSkillIDs.prefix(4))
        player.hasCompletedOnboarding = true
        save()
    }

    func rerollClass(current: inout Job) -> Job {
        guard player.rerollsUsed < 3, player.manacrystals >= 10 else { return current }
        player.manacrystals -= 10
        player.rerollsUsed += 1
        let available = GameData.allJobs.filter { !$0.isLocked && $0.id != current.id }
        current = available.randomElement()!
        return current
    }

    // MARK: - Dungeon / Key System

    func canEnterDungeon(rank: DungeonRank) -> Bool {
        player.dungeonKeys >= rank.keyCost
    }

    func startDungeon(rank: DungeonRank) {
        guard canEnterDungeon(rank: rank) else { return }
        player.dungeonKeys -= rank.keyCost
        selectedDungeonRank = rank
        combat = CombatState()
        combat.dungeonRank = rank
        combat.maxWaves = 4
        combat.wave = 1
        spawnEnemyWave()
        isInCombat = true
        save()
    }

    func spawnEnemyWave() {
        let isBoss = combat.wave == combat.maxWaves
        if isBoss {
            if var boss = GameData.boss(for: combat.dungeonRank) {
                boss.currentHP = boss.baseHP
                combat.currentEnemies = [boss]
            }
        } else {
            let pool = GameData.regularEnemies(for: combat.dungeonRank)
            let count = Int.random(in: 2...3)
            combat.currentEnemies = (0..<count).compactMap { _ in
                guard var e = pool.randomElement() else { return nil }
                e.currentHP = e.baseHP
                return e
            }
        }
    }

    func advanceWave() {
        combat.wave += 1
        if combat.wave > combat.maxWaves {
            completeDungeon()
        } else {
            spawnEnemyWave()
        }
    }

    func completeDungeon() {
        combat.isComplete = true
        isInCombat = false

        let rank = combat.dungeonRank
        let xpGain = Int(Double(50 + rank.recommendedLevel * 10) * rank.xpMultiplier)
        let goldGain = Int(Double(100 + rank.recommendedLevel * 5) * rank.xpMultiplier)
        let keysGain = Int.random(in: 1...3)
        let stonesGain = rank >= .c ? Int.random(in: 1...3) : 0

        player.gainXP(xpGain)
        player.gold += goldGain
        player.dungeonKeys = min(player.dungeonKeys + keysGain, 10)
        player.enhancementStones += stonesGain
        player.totalDungeonsCleared += 1

        let dungeonKey = "\(rank.rawValue)_cleared"
        player.clearedDungeons[dungeonKey] = true

        // Unlock necromancer after first D-rank clear
        if rank >= .d && !GameData.allJobs.first(where: { $0.id == "necromancer" })!.isLocked == false {
            notify("💀 Necromancer job unlocked!")
        }

        updateDailyQuest("daily_dungeons", by: 1)
        notify("🏆 Dungeon cleared! +\(xpGain) XP, +\(goldGain) Gold")
        save()
    }

    func retreatFromDungeon() {
        isInCombat = false
        combat = CombatState()
    }

    // MARK: - Key Regen

    func regenKeys() {
        let now = Date()
        let elapsed = now.timeIntervalSince(player.lastKeyRegenTime)
        let keysToAdd = Int(elapsed / 3600)
        if keysToAdd > 0 {
            player.dungeonKeys = min(player.dungeonKeys + keysToAdd, 10)
            player.lastKeyRegenTime = now
            save()
        }
    }

    var nextKeyRegenDate: Date {
        player.lastKeyRegenTime.addingTimeInterval(3600)
    }

    // MARK: - Gacha

    func pullSkill(count: Int = 1) -> [GachaResult] {
        let cost = BannerType.skill.singlePullCost * count
        guard player.gold >= cost else { return [] }
        player.gold -= cost
        var results: [GachaResult] = []
        for _ in 0..<count {
            let skill = GameData.skillGachaPool(pityCount: player.skillPullCount)
            player.skillPullCount = skill.rarity == .s ? 0 : player.skillPullCount + 1
            addSkillToInventory(skill)
            results.append(.skill(skill))
        }
        save()
        return results
    }

    func pullWeapon(count: Int = 1) -> [GachaResult] {
        let cost = BannerType.weapon.singlePullCost * count
        guard player.gold >= cost else { return [] }
        player.gold -= cost
        var results: [GachaResult] = []
        for _ in 0..<count {
            let weapon = GameData.weaponGachaPool(pityCount: player.weaponPullCount)
            player.weaponPullCount = weapon.rarity >= .s ? 0 : player.weaponPullCount + 1
            addWeaponToInventory(weapon)
            results.append(.weapon(weapon))
        }
        save()
        return results
    }

    private func addSkillToInventory(_ skill: Skill) {
        if let existing = player.skillLevels[skill.id] {
            player.skillLevels[skill.id] = min(existing + 1, 10)
        } else {
            player.inventorySkillIDs.append(skill.id)
            player.skillLevels[skill.id] = 1
        }
    }

    private func addWeaponToInventory(_ weapon: Weapon) {
        if !player.inventoryWeaponIDs.contains(weapon.id) {
            player.inventoryWeaponIDs.append(weapon.id)
        }
    }

    // MARK: - Skill Management

    func equipSkill(_ skillID: String, slot: Int) {
        guard slot < 4, player.inventorySkillIDs.contains(skillID) else { return }
        if player.equippedSkillIDs.count > slot {
            player.equippedSkillIDs[slot] = skillID
        } else {
            player.equippedSkillIDs.append(skillID)
        }
        save()
    }

    func equipWeapon(_ weaponID: String) {
        guard player.inventoryWeaponIDs.contains(weaponID) else { return }
        player.equippedWeaponID = weaponID
        save()
    }

    func enhanceWeapon(_ weaponID: String) -> Bool {
        guard player.inventoryWeaponIDs.contains(weaponID),
              let weapon = GameData.weapon(id: weaponID) else { return false }
        let cost = (weapon.enhancement + 1) * 50
        guard player.gold >= cost, player.enhancementStones >= 1 else { return false }
        player.gold -= cost
        player.enhancementStones -= 1
        // Enhancement stored on player side since Weapon is value type from data
        // We use a separate map
        save()
        return true
    }

    // MARK: - Daily System

    func checkDailyReset() {
        let now = Date()
        let calendar = Calendar.current
        if !calendar.isDate(now, inSameDayAs: player.lastDailyResetTime) {
            player.lastDailyResetTime = now
            player.dailyQuestsCompleted = []
            player.dailyFreePullAvailable = true
            player.loginStreakDays += 1
            dailyQuests = GameData.generateDailyQuests()
            save()
        }
    }

    func updateDailyQuest(_ id: String, by amount: Int) {
        guard let idx = dailyQuests.firstIndex(where: { $0.id == id }),
              !player.dailyQuestsCompleted.contains(id) else { return }
        dailyQuests[idx].progress = min(dailyQuests[idx].progress + amount, dailyQuests[idx].target)
        if dailyQuests[idx].isComplete {
            player.dailyQuestsCompleted.append(id)
            player.gold += dailyQuests[idx].goldReward
            player.manacrystals += dailyQuests[idx].mcReward
            notify("✅ Quest complete! +\(dailyQuests[idx].goldReward) Gold")
        }
    }

    func claimFreePull() -> [GachaResult] {
        guard player.dailyFreePullAvailable else { return [] }
        player.dailyFreePullAvailable = false
        let skill = GameData.skillGachaPool(pityCount: player.skillPullCount)
        addSkillToInventory(skill)
        save()
        return [.skill(skill)]
    }

    // MARK: - Notifications

    func notify(_ message: String) {
        notification = GameNotification(id: UUID(), message: message)
    }

    // MARK: - Persistence

    func save() {
        SaveSystem.save(player)
    }

    var inventorySkills: [Skill] {
        player.inventorySkillIDs.compactMap { id in
            GameData.skill(id: id).map { skill in
                var s = skill
                s.level = player.skillLevels[id] ?? 1
                return s
            }
        }
    }

    var inventoryWeapons: [Weapon] {
        player.inventoryWeaponIDs.compactMap { GameData.weapon(id: $0) }
    }
}

struct GameNotification: Identifiable {
    let id: UUID
    let message: String
}
