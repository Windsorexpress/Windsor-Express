import SwiftUI

// MARK: - Rarity Color

extension Rarity {
    var swiftUIColor: Color {
        switch self {
        case .e: return .gray
        case .d: return .green
        case .c: return .blue
        case .b: return .purple
        case .a: return .orange
        case .s: return .red
        case .ss: return Color(red: 1, green: 0.84, blue: 0)
        case .sss: return Color(red: 1, green: 0.41, blue: 0.71)
        }
    }
}

// MARK: - Stat Bar

struct StatBar: View {
    let label: String
    let value: Int
    let max: Int
    let color: Color
    let emoji: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(emoji) \(label)")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("\(value) / \(max)")
                    .font(.caption.monospacedDigit()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max > 0 ? geo.size.width * CGFloat(value) / CGFloat(max) : 0)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Rarity Badge

struct RarityBadge: View {
    let rarity: Rarity
    var body: some View {
        Text(rarity.rawValue)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(rarity.swiftUIColor.opacity(0.3))
            .foregroundColor(rarity.swiftUIColor)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(rarity.swiftUIColor, lineWidth: 1))
            .cornerRadius(4)
    }
}

// MARK: - Skill Card

struct SkillCard: View {
    let skill: Skill
    var isEquipped: Bool = false
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(skill.emoji)
                    .font(isCompact ? .title3 : .title2)
                Spacer()
                RarityBadge(rarity: skill.rarity)
            }
            Text(skill.name)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            if !isCompact {
                Text(skill.description)
                    .font(.caption).foregroundColor(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if skill.mpCost > 0 {
                        Label("\(skill.mpCost) MP", systemImage: "drop.fill")
                            .font(.caption2).foregroundColor(.blue)
                    }
                    if skill.cooldownTurns > 0 {
                        Label("\(skill.cooldownTurns)T", systemImage: "timer")
                            .font(.caption2).foregroundColor(.orange)
                    }
                    if skill.level > 1 {
                        Label("Lv\(skill.level)", systemImage: "arrow.up")
                            .font(.caption2).foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(isCompact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isEquipped ? skill.rarity.swiftUIColor : Color.white.opacity(0.15), lineWidth: isEquipped ? 2 : 1)
                )
        )
    }
}

// MARK: - Weapon Card

struct WeaponCard: View {
    let weapon: Weapon
    var isEquipped: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(weapon.emoji).font(.title2)
                Spacer()
                RarityBadge(rarity: weapon.rarity)
            }
            Text(weapon.name)
                .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
            Text(weapon.description)
                .font(.caption).foregroundColor(.secondary).lineLimit(2)
            HStack(spacing: 6) {
                Label("+\(weapon.totalATKBonus) ATK", systemImage: "bolt.fill")
                    .font(.caption2).foregroundColor(.red)
                if weapon.enhancement > 0 {
                    Text("+\(weapon.enhancement)")
                        .font(.caption2.bold()).foregroundColor(.yellow)
                }
            }
            if let special = weapon.specialEffect {
                Text(special).font(.caption2).foregroundColor(.cyan).lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isEquipped ? weapon.rarity.swiftUIColor : Color.white.opacity(0.15), lineWidth: isEquipped ? 2 : 1)
                )
        )
    }
}

// MARK: - Job Card

struct JobCard: View {
    let job: Job
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Text(job.emoji).font(.system(size: 48))
            Text(job.name)
                .font(.headline).fontWeight(.bold).foregroundColor(.white)
            Text(job.lore)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Divider().background(Color.white.opacity(0.2))
            HStack(spacing: 12) {
                StatPill(label: "HP", value: job.baseHP, color: .red)
                StatPill(label: "ATK", value: job.baseATK, color: .orange)
                StatPill(label: "DEF", value: job.baseDEF, color: .blue)
                StatPill(label: "SPD", value: job.baseSPD, color: .green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

struct StatPill: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.caption.bold()).foregroundColor(color)
            Text(label)
                .font(.system(size: 9)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Currency Row

struct CurrencyRow: View {
    let gold: Int
    let crystals: Int
    let keys: Int
    var body: some View {
        HStack(spacing: 16) {
            CurrencyChip(emoji: "🪙", value: gold, color: .yellow)
            CurrencyChip(emoji: "💎", value: crystals, color: .cyan)
            CurrencyChip(emoji: "🗝️", value: keys, color: .orange)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.black.opacity(0.4))
        .cornerRadius(20)
    }
}

struct CurrencyChip: View {
    let emoji: String
    let value: Int
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji).font(.subheadline)
            Text("\(value)").font(.subheadline.bold()).foregroundColor(color)
        }
    }
}

// MARK: - Notification Toast

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.subheadline).foregroundColor(.white)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 8)
    }
}

// MARK: - Dark Background

struct ShadowBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.03, green: 0.03, blue: 0.08), Color(red: 0.05, green: 0.05, blue: 0.15)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

// MARK: - Gate Rank Badge

struct RankBadge: View {
    let rank: DungeonRank
    var body: some View {
        Text("\(rank.emoji) \(rank.rawValue)")
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(rankColor.opacity(0.2))
            .foregroundColor(rankColor)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(rankColor, lineWidth: 1))
            .cornerRadius(6)
    }
    var rankColor: Color {
        switch rank {
        case .e: return .gray; case .d: return .green; case .c: return .blue
        case .b: return .purple; case .a: return .orange; case .s: return .red
        case .ss: return Color(red: 1, green: 0.84, blue: 0); case .sss: return Color(red: 1, green: 0.41, blue: 0.71)
        }
    }
}
