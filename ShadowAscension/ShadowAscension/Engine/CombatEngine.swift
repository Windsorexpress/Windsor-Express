import Foundation
import Observation

enum BurstState {
    case none, active(skillID: String, expiresAt: Date), expired
}

@Observable
final class CombatEngine {
    var gameState: GameState
    var turnCount: Int = 0
    var autoAttackTimer: Timer? = nil
    var burstWindowTimer: Timer? = nil
    var burstState: BurstState = .none
    var burstSkillID: String? = nil
    var burstWindowActive: Bool = false
    var lastDamageDealt: Int = 0
    var lastDamageReceived: Int = 0
    var combatMessage: String = ""
    var isTelegraphing: Bool = false
    var usedRevive: Bool = false

    init(gameState: GameState) {
        self.gameState = gameState
    }

    // MARK: - Start / Stop

    func startCombat() {
        usedRevive = false
        turnCount = 0
        scheduleAutoAttack()
        scheduleBurstWindow()
    }

    func stopCombat() {
        autoAttackTimer?.invalidate()
        burstWindowTimer?.invalidate()
        autoAttackTimer = nil
        burstWindowTimer = nil
        burstWindowActive = false
        burstSkillID = nil
    }

    // MARK: - Auto Attack Loop

    private func scheduleAutoAttack() {
        autoAttackTimer?.invalidate()
        let interval = max(1.0, 2.5 - (Double(gameState.player.spd) / 200.0))
        autoAttackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performAutoAttack()
        }
    }

    private func performAutoAttack() {
        guard !gameState.combat.isComplete,
              !gameState.combat.currentEnemies.isEmpty else { return }
        regenMP()
        applyPassiveRegen()
        tickDebuffs()
        tickShadowSoldiers()
        tickCooldowns()

        let atk = effectiveATK()
        let target = gameState.combat.currentEnemies.indices.randomElement()!
        let enemy = gameState.combat.currentEnemies[target]
        let dmg = max(1, atk - enemy.def)
        applyDamageToEnemy(index: target, damage: dmg)
        lastDamageDealt = dmg
        combatMessage = "Auto: \(dmg) dmg → \(enemy.name)"
        addLog("⚔️ Auto attack → \(enemy.name): \(dmg)")

        // Enemy counter-attack chance
        if Float.random(in: 0...1) < 0.35 {
            enemyAttack()
        }

        checkWaveComplete()
    }

    // MARK: - Skill Cast

    func castSkill(_ skill: Skill, isBurst: Bool) -> Bool {
        guard gameState.player.currentMP >= skill.mpCost else {
            combatMessage = "Not enough MP!"
            return false
        }
        guard (gameState.combat.skillCooldowns[skill.id] ?? 0) == 0 else {
            combatMessage = "\(skill.name) is on cooldown!"
            return false
        }

        gameState.player.currentMP -= skill.mpCost
        gameState.combat.skillCooldowns[skill.id] = skill.cooldownTurns
        gameState.player.totalSkillCasts += 1

        let burstMult = isBurst ? 3.0 : 1.0
        if isBurst {
            gameState.player.totalBurstHits += 1
            gameState.updateDailyQuest("daily_bursts", by: 1)
        }
        gameState.updateDailyQuest("daily_skills", by: 1)

        switch skill.effect {
        case .damage:
            let atk = effectiveATK()
            var mult = skill.scaledMultiplier * burstMult
            // Check death mark debuff on enemy
            if gameState.combat.activeBuffs.contains(where: { $0.key == "death_mark" }) {
                mult *= 1.5
            }
            let ignoresDef = skill.buffKey == "ignore_def"
            let targets = gameState.combat.currentEnemies.indices
            for i in targets {
                let enemy = gameState.combat.currentEnemies[i]
                let def = ignoresDef ? 0 : enemy.def
                let dmg = max(1, Int(Double(atk) * mult) - def)
                applyDamageToEnemy(index: i, damage: dmg)
            }
            let totalDmg = Int(Double(atk) * mult)
            lastDamageDealt = totalDmg
            let burstTag = isBurst ? " 💥 BURST!" : ""
            combatMessage = "\(skill.name): \(totalDmg) dmg\(burstTag)"
            addLog("\(skill.emoji) \(skill.name)\(burstTag) → \(totalDmg)")

        case .healing:
            let healAmt = Int(Double(gameState.player.maxHP) * skill.scaledHeal * burstMult)
            gameState.player.currentHP = min(gameState.player.maxHP, gameState.player.currentHP + healAmt)
            combatMessage = "\(skill.name): +\(healAmt) HP"
            addLog("\(skill.emoji) \(skill.name) → healed \(healAmt)")

        case .buff:
            if let key = skill.buffKey {
                let val = key == "berserk" ? skill.buffValue : (skill.buffValue * burstMult)
                let buff = ActiveBuff(key: key, value: val, turnsRemaining: skill.buffDuration)
                gameState.combat.activeBuffs.append(buff)
                combatMessage = "\(skill.name): \(key) active!"
            }
            addLog("\(skill.emoji) \(skill.name) activated")

        case .debuff:
            if let key = skill.buffKey {
                if key == "poison" {
                    let poison = ActiveBuff(key: "poison_\(UUID().uuidString)", value: skill.buffValue, turnsRemaining: skill.buffDuration)
                    gameState.combat.activeBuffs.append(poison)
                } else if key == "death_mark" {
                    let mark = ActiveBuff(key: "death_mark", value: skill.buffValue, turnsRemaining: skill.buffDuration)
                    gameState.combat.activeBuffs.append(mark)
                }
            }
            // Also deal initial damage for damage+debuff skills
            if skill.damageMultiplier > 0 {
                let atk = effectiveATK()
                let dmg = max(1, Int(Double(atk) * skill.scaledMultiplier * burstMult) - (gameState.combat.currentEnemies.first?.def ?? 0))
                if let i = gameState.combat.currentEnemies.indices.first {
                    applyDamageToEnemy(index: i, damage: dmg)
                }
            }
            combatMessage = "\(skill.name) applied!"
            addLog("\(skill.emoji) \(skill.name) → debuff applied")

        case .shield:
            let buff = ActiveBuff(key: skill.buffKey ?? "shield", value: skill.buffValue, turnsRemaining: skill.buffDuration)
            gameState.combat.activeBuffs.append(buff)
            combatMessage = "\(skill.name): Shield active!"
            addLog("\(skill.emoji) \(skill.name) → shielded")

        case .summon:
            let count = Int(skill.buffValue)
            for i in 0..<count {
                let shadow = ShadowSoldier(id: UUID().uuidString, name: "Shadow \(i+1)", emoji: "👤", atk: 30 + i * 10, turnsRemaining: skill.buffDuration)
                gameState.combat.shadowSoldiers.append(shadow)
            }
            combatMessage = "\(skill.name): \(count) shadows raised!"
            addLog("\(skill.emoji) \(skill.name) → \(count) shadows summoned")
        }

        // Dismiss burst window after use
        burstWindowActive = false
        burstSkillID = nil
        checkWaveComplete()
        return true
    }

    // MARK: - Enemy Attack

    private func enemyAttack() {
        guard let enemy = gameState.combat.currentEnemies.first else { return }
        isTelegraphing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.isTelegraphing = false
            var dmg = max(1, enemy.atk - self.gameState.player.def)

            // Check active defense buffs
            let shieldBuff = self.gameState.combat.activeBuffs.first { $0.key == "shield" || $0.key == "barrier" || $0.key == "defense_boost" }
            if let shield = shieldBuff {
                dmg = Int(Double(dmg) * (1.0 - shield.value))
            }

            // Berserk reduces def
            if self.gameState.combat.activeBuffs.contains(where: { $0.key == "berserk" }) {
                dmg = Int(Double(dmg) * 1.5)
            }

            self.gameState.player.currentHP = max(0, self.gameState.player.currentHP - dmg)
            self.lastDamageReceived = dmg
            self.addLog("💢 \(enemy.name) attacks! −\(dmg) HP")
            self.combatMessage = "\(enemy.name) deals \(dmg) damage!"

            if self.gameState.player.currentHP <= 0 {
                self.handlePlayerDeath()
            }
        }
    }

    // MARK: - Damage Helpers

    private func applyDamageToEnemy(index: Int, damage: Int) {
        guard index < gameState.combat.currentEnemies.count else { return }
        gameState.combat.currentEnemies[index].currentHP -= damage
    }

    private func checkWaveComplete() {
        let allDead = gameState.combat.currentEnemies.allSatisfy { $0.currentHP <= 0 }
        if allDead && !gameState.combat.currentEnemies.isEmpty {
            let xp = gameState.combat.currentEnemies.reduce(0) { $0 + $1.xpReward }
            let gold = gameState.combat.currentEnemies.reduce(0) { $0 + $1.goldReward }
            gameState.player.gainXP(xp)
            gameState.player.gold += gold
            addLog("✅ Wave \(gameState.combat.wave) cleared! +\(xp) XP +\(gold) Gold")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.gameState.advanceWave()
                if self?.gameState.isInCombat == false {
                    self?.stopCombat()
                }
            }
        }
    }

    // MARK: - Death / Revive

    private func handlePlayerDeath() {
        // Check passive revive
        let hasRevive = gameState.equippedSkills.contains { $0.buffKey == "passive_revive" }
        if hasRevive && !usedRevive {
            usedRevive = true
            gameState.player.currentHP = Int(Double(gameState.player.maxHP) * 0.2)
            combatMessage = "💜 Undying Pact activated! Revived at 20% HP"
            addLog("💜 Undying Pact — auto-revived!")
        } else {
            stopCombat()
            gameState.isInCombat = false
            combatMessage = "☠️ Defeated..."
        }
    }

    func spendCrystalsToRevive() {
        guard gameState.player.manacrystals >= 5 else { return }
        gameState.player.manacrystals -= 5
        gameState.player.currentHP = Int(Double(gameState.player.maxHP) * 0.2)
        gameState.isInCombat = true
        scheduleAutoAttack()
        scheduleBurstWindow()
    }

    // MARK: - Burst Windows

    private func scheduleBurstWindow() {
        burstWindowTimer?.invalidate()
        let delay = Double.random(in: 8...14)
        burstWindowTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.activateBurstWindow()
        }
    }

    private func activateBurstWindow() {
        let activeSkills = gameState.equippedSkills.filter {
            $0.cooldownTurns > 0 && (gameState.combat.skillCooldowns[$0.id] ?? 0) == 0
        }
        guard !activeSkills.isEmpty else {
            scheduleBurstWindow()
            return
        }
        let target = activeSkills.randomElement()!
        burstSkillID = target.id
        burstWindowActive = true
        combatMessage = "💥 BURST WINDOW! Tap \(target.name)!"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.burstWindowActive = false
            self?.burstSkillID = nil
            self?.scheduleBurstWindow()
        }
    }

    // MARK: - Passive / Tick Effects

    private func regenMP() {
        let regen = 15 + gameState.player.spd / 10
        gameState.player.currentMP = min(gameState.player.maxMP, gameState.player.currentMP + regen)
    }

    private func applyPassiveRegen() {
        let hasRegen = gameState.equippedSkills.contains { $0.buffKey == "passive_regen" }
        if hasRegen {
            let healAmt = Int(Double(gameState.player.maxHP) * 0.02)
            gameState.player.currentHP = min(gameState.player.maxHP, gameState.player.currentHP + healAmt)
        }
    }

    private func tickDebuffs() {
        // Apply poison to enemy
        var poisonDamage = 0
        gameState.combat.activeBuffs = gameState.combat.activeBuffs.compactMap { buff in
            if buff.key.hasPrefix("poison") {
                poisonDamage += Int(buff.value)
            }
            var b = buff
            b.turnsRemaining -= 1
            return b.turnsRemaining > 0 ? b : nil
        }
        if poisonDamage > 0, let i = gameState.combat.currentEnemies.indices.first {
            applyDamageToEnemy(index: i, damage: poisonDamage)
            addLog("☠️ Poison: \(poisonDamage) dmg")
        }
    }

    private func tickShadowSoldiers() {
        guard !gameState.combat.currentEnemies.isEmpty else { return }
        gameState.combat.shadowSoldiers = gameState.combat.shadowSoldiers.compactMap { soldier in
            if let i = gameState.combat.currentEnemies.indices.first {
                applyDamageToEnemy(index: i, damage: soldier.atk)
                addLog("👤 \(soldier.name): \(soldier.atk) dmg")
            }
            var s = soldier
            s.turnsRemaining -= 1
            return s.turnsRemaining > 0 ? s : nil
        }
    }

    private func tickCooldowns() {
        var updated = gameState.combat.skillCooldowns
        for key in updated.keys {
            updated[key] = max(0, (updated[key] ?? 0) - 1)
        }
        gameState.combat.skillCooldowns = updated
    }

    // MARK: - Derived Stats

    private func effectiveATK() -> Int {
        var atk = gameState.player.atk
        if let weapon = gameState.equippedWeapon {
            atk += weapon.totalATKBonus
        }
        for buff in gameState.combat.activeBuffs {
            if buff.key == "atk_boost" { atk = Int(Double(atk) * (1.0 + buff.value)) }
            if buff.key == "berserk" { atk = Int(Double(atk) * buff.value) }
            if buff.key == "monarch" { atk = Int(Double(atk) * buff.value) }
        }
        return atk
    }

    // MARK: - Log

    private func addLog(_ message: String) {
        gameState.combat.battleLog.insert(message, at: 0)
        if gameState.combat.battleLog.count > 20 {
            gameState.combat.battleLog.removeLast()
        }
    }
}
