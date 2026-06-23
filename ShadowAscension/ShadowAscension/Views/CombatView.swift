import SwiftUI

struct CombatView: View {
    @Bindable var gameState: GameState
    @State private var engine: CombatEngine? = nil
    @State private var showDefeatSheet = false
    @State private var damagePopups: [DamagePopup] = []

    var body: some View {
        ZStack {
            // Dark dungeon background
            LinearGradient(colors: [Color(red: 0.02, green: 0.02, blue: 0.06), Color(red: 0.04, green: 0.02, blue: 0.10)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if gameState.isInCombat {
                combatUI
            } else if gameState.combat.isComplete {
                victoryView
            } else {
                notInCombatView
            }

            // Damage popups
            ForEach(damagePopups) { popup in
                Text(popup.text)
                    .font(.headline.bold())
                    .foregroundColor(popup.color)
                    .shadow(color: .black, radius: 2)
                    .position(popup.position)
                    .opacity(popup.opacity)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: gameState.isInCombat) { _, newVal in
            if newVal {
                startEngine()
            } else {
                engine?.stopCombat()
            }
        }
        .onChange(of: gameState.player.currentHP) { old, new in
            if new < old {
                addDamagePopup("-\(old - new)", color: .red, position: CGPoint(x: 100, y: 200))
            }
        }
        .sheet(isPresented: $showDefeatSheet) {
            defeatSheet
        }
        .onDisappear { engine?.stopCombat() }
    }

    // MARK: - Combat UI

    var combatUI: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar
            Divider().background(Color.white.opacity(0.1))

            // Wave indicator
            waveIndicator

            // Enemy section
            enemySection
                .frame(maxHeight: .infinity)

            // Battle log
            battleLog

            // Player status
            playerStatus

            // Skill bar
            skillBar
        }
    }

    var topBar: some View {
        HStack {
            Button(action: { gameState.retreatFromDungeon(); engine?.stopCombat() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Retreat")
                }
                .font(.subheadline).foregroundColor(.red)
            }
            Spacer()
            Text("\(gameState.combat.dungeonRank.emoji) \(gameState.combat.dungeonRank.rawValue)-Rank Gate")
                .font(.headline.bold()).foregroundColor(.white)
            Spacer()
            // Shadow soldiers indicator
            if !gameState.combat.shadowSoldiers.isEmpty {
                HStack(spacing: 2) {
                    ForEach(gameState.combat.shadowSoldiers) { s in
                        Text(s.emoji).font(.caption)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    var waveIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...gameState.combat.maxWaves, id: \.self) { wave in
                Circle()
                    .fill(wave < gameState.combat.wave ? Color.green : (wave == gameState.combat.wave ? Color.blue : Color.white.opacity(0.2)))
                    .frame(width: 10, height: 10)
            }
            if gameState.combat.isBossWave {
                Text("👑 BOSS").font(.caption.bold()).foregroundColor(.yellow)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2)).cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }

    var enemySection: some View {
        VStack(spacing: 12) {
            if gameState.combat.currentEnemies.isEmpty {
                Text("Wave cleared!").font(.title3).foregroundColor(.green)
            } else {
                HStack(spacing: 20) {
                    ForEach(gameState.combat.currentEnemies.indices, id: \.self) { i in
                        let enemy = gameState.combat.currentEnemies[i]
                        if enemy.currentHP > 0 {
                            EnemyCard(enemy: enemy, isTelegraphing: engine?.isTelegraphing ?? false)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    var battleLog: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(gameState.combat.battleLog.prefix(5), id: \.self) { log in
                    Text(log)
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 80)
        .background(Color.black.opacity(0.3))
    }

    var playerStatus: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Text(gameState.currentJob?.emoji ?? "⚔️").font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    StatBar(label: "HP", value: gameState.player.currentHP, max: gameState.player.maxHP, color: .red, emoji: "❤️")
                    StatBar(label: "MP", value: gameState.player.currentMP, max: gameState.player.maxMP, color: .blue, emoji: "💧")
                }
            }
            // Active buffs
            if !gameState.combat.activeBuffs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(gameState.combat.activeBuffs) { buff in
                            Text(buffEmoji(buff.key))
                                .font(.caption)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                                .overlay(
                                    Text("\(buff.turnsRemaining)").font(.system(size: 8))
                                        .foregroundColor(.yellow)
                                        .offset(x: 8, y: -8),
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.black.opacity(0.4))
    }

    var skillBar: some View {
        HStack(spacing: 10) {
            ForEach(gameState.equippedSkills.prefix(4)) { skill in
                let cooldown = gameState.combat.skillCooldowns[skill.id] ?? 0
                let isBurst = engine?.burstWindowActive == true && engine?.burstSkillID == skill.id
                let canCast = cooldown == 0 && gameState.player.currentMP >= skill.mpCost

                Button(action: {
                    let wasBurst = isBurst
                    let _ = engine?.castSkill(skill, isBurst: wasBurst)
                    if let dmg = engine?.lastDamageDealt, dmg > 0 {
                        addDamagePopup(wasBurst ? "💥 \(dmg)!" : "\(dmg)", color: wasBurst ? .yellow : .white, position: CGPoint(x: CGFloat.random(in: 150...250), y: CGFloat.random(in: 250...350)))
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canCast ? Color.white.opacity(0.1) : Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isBurst ? Color.yellow : (canCast ? skill.rarity.swiftUIColor.opacity(0.6) : Color.gray.opacity(0.3)), lineWidth: isBurst ? 2.5 : 1)
                            )
                            .scaleEffect(isBurst ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isBurst)

                        VStack(spacing: 2) {
                            Text(skill.emoji).font(.title3)
                            Text(skill.name.split(separator: " ").first.map(String.init) ?? skill.name)
                                .font(.system(size: 8)).foregroundColor(.white).lineLimit(1)
                            if cooldown > 0 {
                                Text("\(cooldown)").font(.caption.bold()).foregroundColor(.orange)
                            } else if skill.mpCost > 0 {
                                Text("\(skill.mpCost)MP").font(.system(size: 8)).foregroundColor(.blue)
                            }
                        }

                        // Cooldown overlay
                        if cooldown > 0 {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.6))
                        }
                    }
                    .frame(width: 72, height: 72)
                }
                .buttonStyle(.plain)
                .disabled(!canCast && cooldown > 0)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.black.opacity(0.6))
    }

    // MARK: - Victory / Defeat

    var victoryView: some View {
        VStack(spacing: 20) {
            Text("🏆").font(.system(size: 80))
            Text("Victory!").font(.title.bold()).foregroundColor(.yellow)
            Text("Gate cleared!").font(.subheadline).foregroundColor(.secondary)
            Button(action: { gameState.combat = CombatState() }) {
                Text("Continue")
                    .font(.headline).foregroundColor(.black)
                    .frame(width: 200).padding()
                    .background(Color.yellow).cornerRadius(14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var notInCombatView: some View {
        VStack(spacing: 16) {
            Text("🚪").font(.system(size: 60))
            Text("No Active Gate").font(.title3.bold()).foregroundColor(.white)
            Text("Enter a gate from the Gates tab.").font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var defeatSheet: some View {
        VStack(spacing: 20) {
            Text("☠️").font(.system(size: 80))
            Text("Defeated").font(.title.bold()).foregroundColor(.red)
            Text("Do you wish to continue?").font(.subheadline).foregroundColor(.secondary)
            HStack(spacing: 16) {
                Button(action: {
                    showDefeatSheet = false
                    engine?.spendCrystalsToRevive()
                }) {
                    Text("💎 Revive (5 MC)")
                        .font(.headline).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.cyan).cornerRadius(14)
                }
                Button(action: {
                    showDefeatSheet = false
                    gameState.retreatFromDungeon()
                }) {
                    Text("Retreat")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.gray.opacity(0.3)).cornerRadius(14)
                }
            }
        }
        .padding(30)
        .presentationDetents([.fraction(0.4)])
    }

    // MARK: - Helpers

    func startEngine() {
        let e = CombatEngine(gameState: gameState)
        engine = e
        e.startCombat()
    }

    func addDamagePopup(_ text: String, color: Color, position: CGPoint) {
        let popup = DamagePopup(id: UUID(), text: text, color: color, position: position, opacity: 1.0)
        damagePopups.append(popup)
        withAnimation(.easeOut(duration: 1.2)) {
            if let idx = damagePopups.firstIndex(where: { $0.id == popup.id }) {
                damagePopups[idx].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            damagePopups.removeAll { $0.id == popup.id }
        }
    }

    func buffEmoji(_ key: String) -> String {
        switch key {
        case "atk_boost", "monarch", "berserk": return "⬆️"
        case "defense_boost", "shield", "barrier": return "🛡️"
        case "poison", "poison_\(key)": return "☠️"
        case "death_mark": return "💀"
        case "freeze": return "❄️"
        default: return "✨"
        }
    }
}

// MARK: - Enemy Card

struct EnemyCard: View {
    let enemy: Enemy
    let isTelegraphing: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(enemy.emoji)
                .font(.system(size: enemy.isBoss ? 60 : 44))
                .shadow(color: isTelegraphing ? .red : .clear, radius: 15)
                .overlay(
                    isTelegraphing ?
                    Circle().stroke(Color.red, lineWidth: 2).scaleEffect(1.3)
                        .opacity(0.8)
                    : nil
                )

            Text(enemy.name)
                .font(.caption.bold()).foregroundColor(.white)

            // HP bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.red.opacity(0.3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red)
                        .frame(width: geo.size.width * CGFloat(max(0, enemy.currentHP)) / CGFloat(max(1, enemy.baseHP)))
                }
            }
            .frame(height: 5)
            .frame(width: enemy.isBoss ? 120 : 80)

            Text("\(enemy.currentHP)/\(enemy.baseHP)")
                .font(.system(size: 9)).foregroundColor(.secondary)
        }
        .animation(.easeInOut(duration: 0.15), value: isTelegraphing)
    }
}

// MARK: - Damage Popup Model

struct DamagePopup: Identifiable {
    let id: UUID
    let text: String
    let color: Color
    var position: CGPoint
    var opacity: Double
}
