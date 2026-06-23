import SwiftUI

struct ProfileView: View {
    @Bindable var gameState: GameState
    @State private var selectedTab: ProfileTab = .skills
    @State private var showSkillPicker: Bool = false
    @State private var selectedSlot: Int = 0

    enum ProfileTab: String, CaseIterable {
        case skills = "Skills", weapons = "Weapons", stats = "Stats"
    }

    var body: some View {
        ZStack {
            ShadowBackground()
            VStack(spacing: 0) {
                // Header
                profileHeader
                // Tab picker
                Picker("Tab", selection: $selectedTab) {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16).padding(.vertical, 8)

                ScrollView {
                    Group {
                        switch selectedTab {
                        case .skills: skillsSection
                        case .weapons: weaponsSection
                        case .stats: statsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSkillPicker) {
            skillPickerSheet
        }
    }

    // MARK: - Profile Header

    var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Text(gameState.currentJob?.emoji ?? "⚔️")
                    .font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(gameState.player.name)
                    .font(.title2.bold()).foregroundColor(.white)
                Text(gameState.currentJob?.name ?? "Unknown Job")
                    .font(.subheadline).foregroundColor(.blue)

                HStack(spacing: 8) {
                    Text("Lv.\(gameState.player.level)")
                        .font(.caption.bold()).foregroundColor(.orange)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15)).cornerRadius(8)
                    RankBadge(rank: gameState.player.jobRank)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                CurrencyChip(emoji: "🪙", value: gameState.player.gold, color: .yellow)
                CurrencyChip(emoji: "💎", value: gameState.player.manacrystals, color: .cyan)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
    }

    // MARK: - Skills Section

    var skillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Equipped slots
            VStack(alignment: .leading, spacing: 10) {
                Text("⚡ Equipped Skills (4 max)")
                    .font(.headline).foregroundColor(.white)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(0..<4) { slot in
                        if slot < gameState.player.equippedSkillIDs.count,
                           let skill = GameData.skill(id: gameState.player.equippedSkillIDs[slot]) {
                            Button(action: { selectedSlot = slot; showSkillPicker = true }) {
                                SkillCard(skill: skill, isEquipped: true, isCompact: false)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: { selectedSlot = slot; showSkillPicker = true }) {
                                emptySkillSlot(slot: slot)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Inventory
            VStack(alignment: .leading, spacing: 10) {
                Text("📦 Skill Inventory (\(gameState.inventorySkills.count))")
                    .font(.headline).foregroundColor(.white)

                if gameState.inventorySkills.isEmpty {
                    Text("No skills yet. Pull from Summon!")
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(30)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(gameState.inventorySkills.sorted(by: { a, b in
                            Rarity.allCases.firstIndex(of: a.rarity)! > Rarity.allCases.firstIndex(of: b.rarity)!
                        })) { skill in
                            let isEquipped = gameState.player.equippedSkillIDs.contains(skill.id)
                            SkillCard(skill: skill, isEquipped: isEquipped)
                        }
                    }
                }
            }
        }
        .padding(.top, 12)
    }

    func emptySkillSlot(slot: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle.dashed")
                .font(.title2).foregroundColor(.secondary)
            Text("Slot \(slot + 1)")
                .font(.caption).foregroundColor(.secondary)
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
        .cornerRadius(10)
    }

    // MARK: - Weapons Section

    var weaponsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Equipped weapon
            VStack(alignment: .leading, spacing: 10) {
                Text("⚔️ Equipped Weapon")
                    .font(.headline).foregroundColor(.white)

                if let weapon = gameState.equippedWeapon {
                    WeaponCard(weapon: weapon, isEquipped: true)
                } else {
                    Text("No weapon equipped")
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(10)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Inventory
            VStack(alignment: .leading, spacing: 10) {
                Text("📦 Weapon Inventory (\(gameState.inventoryWeapons.count))")
                    .font(.headline).foregroundColor(.white)

                if gameState.inventoryWeapons.isEmpty {
                    Text("No weapons yet. Pull from Weapon Forge!")
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity).padding(30)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(gameState.inventoryWeapons.sorted(by: {
                            Rarity.allCases.firstIndex(of: $0.rarity)! > Rarity.allCases.firstIndex(of: $1.rarity)!
                        })) { weapon in
                            let isEquipped = gameState.player.equippedWeaponID == weapon.id
                            Button(action: { gameState.equipWeapon(weapon.id) }) {
                                WeaponCard(weapon: weapon, isEquipped: isEquipped)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Enhancement
            if gameState.player.equippedWeaponID != nil {
                enhancementSection
            }
        }
        .padding(.top, 12)
    }

    var enhancementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔧 Weapon Enhancement")
                .font(.headline).foregroundColor(.white)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enhancement Stones: \(gameState.player.enhancementStones)")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("Gold cost: \((gameState.inventoryWeapons.first?.enhancement ?? 0 + 1) * 50) 🪙")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    if let wid = gameState.player.equippedWeaponID {
                        let _ = gameState.enhanceWeapon(wid)
                    }
                }) {
                    Text("Enhance +1")
                        .font(.subheadline.bold()).foregroundColor(.black)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(gameState.player.enhancementStones > 0 ? Color.orange : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(gameState.player.enhancementStones == 0)
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }

    // MARK: - Stats Section

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Hunter Statistics")
                .font(.headline).foregroundColor(.white)

            // Core stats
            statsGrid

            Divider().background(Color.white.opacity(0.1))

            // Record
            recordSection

            Divider().background(Color.white.opacity(0.1))

            // Shadow army
            shadowArmySection
        }
        .padding(.top, 12)
    }

    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatDetailRow(label: "Max HP", value: "\(gameState.player.maxHP)", emoji: "❤️", color: .red)
            StatDetailRow(label: "ATK", value: "\(gameState.player.atk + (gameState.equippedWeapon?.totalATKBonus ?? 0))", emoji: "⚔️", color: .orange)
            StatDetailRow(label: "DEF", value: "\(gameState.player.def + (gameState.equippedWeapon?.defBonus ?? 0))", emoji: "🛡️", color: .blue)
            StatDetailRow(label: "SPD", value: "\(gameState.player.spd)", emoji: "💨", color: .green)
            StatDetailRow(label: "Max MP", value: "\(gameState.player.maxMP)", emoji: "💧", color: .purple)
            StatDetailRow(label: "Crit +", value: "\(Int((gameState.equippedWeapon?.critChanceBonus ?? 0) * 100))%", emoji: "💥", color: .yellow)
        }
    }

    var recordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📈 Record")
                .font(.subheadline.bold()).foregroundColor(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatDetailRow(label: "Dungeons", value: "\(gameState.player.totalDungeonsCleared)", emoji: "🚪", color: .cyan)
                StatDetailRow(label: "Skills Cast", value: "\(gameState.player.totalSkillCasts)", emoji: "✨", color: .purple)
                StatDetailRow(label: "Burst Hits", value: "\(gameState.player.totalBurstHits)", emoji: "💥", color: .yellow)
                StatDetailRow(label: "Login Streak", value: "\(gameState.player.loginStreakDays)d", emoji: "📆", color: .green)
            }
        }
    }

    var shadowArmySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("👥 Shadow Army (\(gameState.combat.shadowSoldiers.count)/10)")
                .font(.subheadline.bold()).foregroundColor(.white)
            if gameState.combat.shadowSoldiers.isEmpty {
                Text("No shadow soldiers yet. Use Army of the Dead or unlock Necromancer skills.")
                    .font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(gameState.combat.shadowSoldiers) { soldier in
                    HStack {
                        Text(soldier.emoji).font(.title3)
                        Text(soldier.name).font(.subheadline).foregroundColor(.white)
                        Spacer()
                        Text("ATK: \(soldier.atk)").font(.caption).foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Skill Picker Sheet

    var skillPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(gameState.inventorySkills.sorted(by: {
                            Rarity.allCases.firstIndex(of: $0.rarity)! > Rarity.allCases.firstIndex(of: $1.rarity)!
                        })) { skill in
                            Button(action: {
                                gameState.equipSkill(skill.id, slot: selectedSlot)
                                showSkillPicker = false
                            }) {
                                SkillCard(skill: skill, isEquipped: gameState.player.equippedSkillIDs.contains(skill.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Skill for Slot \(selectedSlot + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSkillPicker = false }
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct StatDetailRow: View {
    let label: String
    let value: String
    let emoji: String
    let color: Color

    var body: some View {
        HStack {
            Text(emoji).font(.subheadline)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.subheadline.bold()).foregroundColor(color)
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
