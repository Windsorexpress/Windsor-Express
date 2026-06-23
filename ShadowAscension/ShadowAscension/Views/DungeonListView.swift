import SwiftUI

struct DungeonListView: View {
    @Bindable var gameState: GameState
    @State private var selectedRank: DungeonRank? = nil
    @State private var showEnterAlert = false

    var body: some View {
        ZStack {
            ShadowBackground()
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gates")
                            .font(.title.bold()).foregroundColor(.white)
                        Text("🗝️ \(gameState.player.dungeonKeys)/10 keys")
                            .font(.subheadline).foregroundColor(.orange)
                    }
                    Spacer()
                    CurrencyRow(gold: gameState.player.gold, crystals: gameState.player.manacrystals, keys: gameState.player.dungeonKeys)
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(DungeonRank.allCases, id: \.self) { rank in
                            DungeonRankCard(
                                rank: rank,
                                isUnlocked: gameState.player.level >= rank.recommendedLevel,
                                hasKeys: gameState.player.dungeonKeys >= rank.keyCost,
                                isCleared: gameState.player.clearedDungeons["\(rank.rawValue)_cleared"] ?? false,
                                onTap: {
                                    selectedRank = rank
                                    showEnterAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showEnterAlert) {
            guard let rank = selectedRank else {
                return Alert(title: Text("Error"))
            }
            let canEnter = gameState.canEnterDungeon(rank: rank)
            return Alert(
                title: Text("\(rank.emoji) \(rank.rawValue)-Rank Gate"),
                message: Text(canEnter ? "Spend \(rank.keyCost) 🗝️ to enter?\nRecommended: Lv.\(rank.recommendedLevel)+" : "Not enough keys or level too low."),
                primaryButton: .destructive(Text(canEnter ? "Enter" : "Cancel"), action: {
                    if canEnter, let r = selectedRank {
                        gameState.startDungeon(rank: r)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Dungeon Card

struct DungeonRankCard: View {
    let rank: DungeonRank
    let isUnlocked: Bool
    let hasKeys: Bool
    let isCleared: Bool
    let onTap: () -> Void

    var canEnter: Bool { isUnlocked && hasKeys }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Rank icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Text(rank.emoji)
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(rank.rawValue)-Rank Gate")
                            .font(.headline).foregroundColor(.white)
                        if isCleared {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption).foregroundColor(.green)
                        }
                    }
                    Text("Recommended: Lv.\(rank.recommendedLevel)+")
                        .font(.caption).foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        Label("\(rank.keyCost) Keys", systemImage: "key.fill")
                            .font(.caption2).foregroundColor(.orange)
                        Label("\(Int(100 * rank.xpMultiplier))+ XP", systemImage: "star.fill")
                            .font(.caption2).foregroundColor(.yellow)
                    }

                    enemyPreview
                }
                Spacer()

                // Status indicator
                VStack(spacing: 4) {
                    if !isUnlocked {
                        Image(systemName: "lock.fill").foregroundColor(.gray)
                        Text("Lv.\(rank.recommendedLevel)").font(.system(size: 9)).foregroundColor(.gray)
                    } else if !hasKeys {
                        Image(systemName: "key.slash.fill").foregroundColor(.orange)
                        Text("No keys").font(.system(size: 9)).foregroundColor(.orange)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title3).foregroundColor(rankColor)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(canEnter ? 0.07 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(canEnter ? rankColor.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }

    var enemyPreview: some View {
        let enemies = GameData.regularEnemies(for: rank)
        let boss = GameData.boss(for: rank)
        return HStack(spacing: 2) {
            Text("Enemies: ")
                .font(.system(size: 10)).foregroundColor(.secondary)
            ForEach(enemies.prefix(3)) { e in
                Text(e.emoji).font(.system(size: 14))
            }
            if let b = boss {
                Text("👑\(b.emoji)").font(.system(size: 14))
            }
        }
    }

    var rankColor: Color {
        switch rank {
        case .e: return .gray; case .d: return .green; case .c: return .blue
        case .b: return .purple; case .a: return .orange; case .s: return .red
        case .ss: return Color(red: 1, green: 0.84, blue: 0); case .sss: return Color(red: 1, green: 0.41, blue: 0.71)
        }
    }
}
