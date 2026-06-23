import SwiftUI

struct HomeView: View {
    @Bindable var gameState: GameState
    @State private var showSettings = false

    var body: some View {
        ZStack {
            ShadowBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    // Currency bar
                    CurrencyRow(gold: gameState.player.gold, crystals: gameState.player.manacrystals, keys: gameState.player.dungeonKeys)
                    // Hunter card
                    hunterCard
                    // Daily quests
                    dailyQuestsSection
                    // Quick stats
                    statsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    // MARK: - Header

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Shadow Ascension")
                    .font(.title2.bold())
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                Text("Rank \(gameState.player.jobRank.rawValue) Hunter")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3).foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Hunter Card

    var hunterCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 70, height: 70)
                    Text(gameState.currentJob?.emoji ?? "⚔️")
                        .font(.system(size: 36))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(gameState.player.name)
                        .font(.title3.bold()).foregroundColor(.white)
                    Text(gameState.currentJob?.name ?? "Unknown")
                        .font(.subheadline).foregroundColor(.blue)
                    HStack(spacing: 6) {
                        Text("Lv.\(gameState.player.level)")
                            .font(.caption.bold()).foregroundColor(.orange)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text("Rank \(gameState.player.jobRank.rawValue)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("🏆 \(gameState.player.totalDungeonsCleared)")
                        .font(.caption).foregroundColor(.yellow)
                    Text("Cleared")
                        .font(.system(size: 9)).foregroundColor(.secondary)
                }
            }

            // XP Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("EXP")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("\(gameState.player.xp) / \(gameState.player.xpToNextLevel)")
                        .font(.caption.monospacedDigit()).foregroundColor(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(gameState.player.xp) / CGFloat(max(1, gameState.player.xpToNextLevel)))
                    }
                }.frame(height: 6)
            }

            // HP/MP bars
            StatBar(label: "HP", value: gameState.player.currentHP, max: gameState.player.maxHP, color: .red, emoji: "❤️")
            StatBar(label: "MP", value: gameState.player.currentMP, max: gameState.player.maxMP, color: .blue, emoji: "💧")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    // MARK: - Daily Quests

    var dailyQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📋 Daily Quests")
                    .font(.headline).foregroundColor(.white)
                Spacer()
                if gameState.player.dailyFreePullAvailable {
                    Button(action: { let _ = gameState.claimFreePull() }) {
                        Text("🎁 Free Pull")
                            .font(.caption.bold()).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.yellow)
                            .cornerRadius(10)
                    }
                }
            }

            ForEach(gameState.dailyQuests) { quest in
                DailyQuestRow(quest: quest, isCompleted: gameState.player.dailyQuestsCompleted.contains(quest.id))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    // MARK: - Stats

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ Combat Stats")
                .font(.headline).foregroundColor(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(label: "ATK", value: gameState.player.atk, emoji: "⚔️", color: .red)
                StatTile(label: "DEF", value: gameState.player.def, emoji: "🛡️", color: .blue)
                StatTile(label: "SPD", value: gameState.player.spd, emoji: "💨", color: .green)
                StatTile(label: "Skills", value: gameState.player.inventorySkillIDs.count, emoji: "✨", color: .purple)
                StatTile(label: "Weapons", value: gameState.player.inventoryWeaponIDs.count, emoji: "⚔️", color: .orange)
                StatTile(label: "Bursts", value: gameState.player.totalBurstHits, emoji: "💥", color: .yellow)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }
}

// MARK: - Supporting Views

struct DailyQuestRow: View {
    let quest: DailyQuest
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(quest.emoji).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.description)
                    .font(.subheadline).foregroundColor(isCompleted ? .secondary : .white)
                    .strikethrough(isCompleted)
                HStack(spacing: 4) {
                    Text("🪙 \(quest.goldReward)").font(.caption2).foregroundColor(.yellow)
                    Text("💎 \(quest.mcReward)").font(.caption2).foregroundColor(.cyan)
                }
            }
            Spacer()
            if isCompleted {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Text("\(quest.progress)/\(quest.target)")
                    .font(.caption.monospacedDigit()).foregroundColor(.secondary)
            }
        }
    }
}

struct StatTile: View {
    let label: String
    let value: Int
    let emoji: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji).font(.title3)
            Text("\(value)")
                .font(.headline.bold()).foregroundColor(color)
            Text(label)
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}
