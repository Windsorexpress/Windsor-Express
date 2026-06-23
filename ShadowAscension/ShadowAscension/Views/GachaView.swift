import SwiftUI

struct GachaView: View {
    @Bindable var gameState: GameState
    @State private var selectedBanner: BannerType = .skill
    @State private var pullResults: [GachaResultDisplay] = []
    @State private var isPulling: Bool = false
    @State private var showResults: Bool = false
    @State private var animationPhase: Int = 0

    var body: some View {
        ZStack {
            ShadowBackground()
            VStack(spacing: 0) {
                // Header
                headerSection
                // Banner tabs
                bannerTabs
                // Banner content
                ScrollView {
                    VStack(spacing: 20) {
                        bannerVisual
                        pullInfo
                        pityInfo
                        actionButtons
                        if !showResults { Spacer(minLength: 20) }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Pull animation overlay
            if isPulling {
                pullAnimationOverlay
            }

            // Results overlay
            if showResults {
                resultsOverlay
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Summon")
                    .font(.title.bold()).foregroundColor(.white)
                Text("Collect skills, weapons & more")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            CurrencyRow(gold: gameState.player.gold, crystals: gameState.player.manacrystals, keys: gameState.player.dungeonKeys)
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
    }

    // MARK: - Banner Tabs

    var bannerTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BannerType.allCases, id: \.self) { banner in
                    Button(action: { selectedBanner = banner }) {
                        VStack(spacing: 4) {
                            Text(banner.emoji).font(.title3)
                            Text(banner.rawValue.components(separatedBy: " ").first ?? banner.rawValue)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(selectedBanner == banner ? Color.blue.opacity(0.3) : Color.white.opacity(0.05))
                        .foregroundColor(selectedBanner == banner ? .blue : .secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedBanner == banner ? Color.blue : Color.clear, lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    // MARK: - Banner Visual

    var bannerVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(height: 180)

            VStack(spacing: 12) {
                Text(selectedBanner.emoji).font(.system(size: 60))
                    .shadow(color: .blue, radius: 20)
                Text(selectedBanner.rawValue)
                    .font(.title2.bold())
                    .foregroundStyle(LinearGradient(colors: [.white, .blue], startPoint: .leading, endPoint: .trailing))
            }

            // Animated particles
            ForEach(0..<5) { i in
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: CGFloat.random(in: 4...12), height: CGFloat.random(in: 4...12))
                    .offset(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: -60...60))
                    .opacity(Double.random(in: 0.3...0.8))
            }
        }
    }

    // MARK: - Pull Info

    var pullInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drop Rates")
                .font(.subheadline.bold()).foregroundColor(.white)

            if selectedBanner == .skill {
                RatesGrid(rates: [
                    ("E", "40%", .gray), ("D", "30%", .green), ("C", "20%", .blue),
                    ("B", "8%", .purple), ("A", "1.8%", .orange), ("S", "0.2%", .red)
                ])
            } else if selectedBanner == .weapon {
                RatesGrid(rates: [
                    ("E", "35%", .gray), ("D", "30%", .green), ("C", "20%", .blue),
                    ("B", "10%", .purple), ("A", "4%", .orange), ("S", "0.8%", .red),
                    ("SS", "0.15%", Color(red: 1, green: 0.84, blue: 0)),
                    ("SSS", "0.05%", Color(red: 1, green: 0.41, blue: 0.71))
                ])
            } else {
                Text("5 Job Shards = Job Change Crystal")
                    .font(.caption).foregroundColor(.secondary)
                Text("Necromancer: 10% · Other jobs: 90%")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Pity Info

    var pityInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("⭐ Pity Counter")
                    .font(.subheadline.bold()).foregroundColor(.white)
                if selectedBanner == .skill {
                    Text("Pulls until guaranteed S-rank: \(80 - gameState.player.skillPullCount)")
                        .font(.caption).foregroundColor(.secondary)
                    ProgressView(value: Double(gameState.player.skillPullCount), total: 80)
                        .tint(.red)
                } else if selectedBanner == .weapon {
                    Text("Pulls until guaranteed S-rank: \(100 - gameState.player.weaponPullCount)")
                        .font(.caption).foregroundColor(.secondary)
                    ProgressView(value: Double(gameState.player.weaponPullCount), total: 100)
                        .tint(.orange)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons

    var actionButtons: some View {
        VStack(spacing: 10) {
            // Single pull
            Button(action: { performPull(count: 1) }) {
                HStack {
                    Text("× 1 Pull")
                        .font(.headline.bold())
                    Spacer()
                    if selectedBanner.singlePullCost > 0 {
                        Text("🪙 \(selectedBanner.singlePullCost)")
                            .font(.subheadline.bold()).foregroundColor(.yellow)
                    } else {
                        Text("FREE")
                            .font(.subheadline.bold()).foregroundColor(.green)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.3), lineWidth: 1))
                .cornerRadius(14)
            }

            // 10x pull
            if selectedBanner.singlePullCost > 0 {
                Button(action: { performPull(count: 10) }) {
                    HStack {
                        Text("× 10 Pull")
                            .font(.headline.bold())
                        Text("(BEST VALUE)")
                            .font(.caption).foregroundColor(.yellow)
                        Spacer()
                        Text("🪙 \(selectedBanner.tenPullCost)")
                            .font(.subheadline.bold()).foregroundColor(.yellow)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.6), lineWidth: 1))
                    .cornerRadius(14)
                }
            }

            // Not enough warning
            if gameState.player.gold < selectedBanner.singlePullCost {
                Text("⚠️ Not enough Gold")
                    .font(.caption).foregroundColor(.orange)
            }
        }
    }

    // MARK: - Pull Animation Overlay

    var pullAnimationOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("✨")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(Double(animationPhase) * 30))
                    .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: animationPhase)
                Text("Summoning...")
                    .font(.title2.bold()).foregroundColor(.white)
            }
        }
        .onAppear { animationPhase += 1 }
    }

    // MARK: - Results Overlay

    var resultsOverlay: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Summon Results")
                    .font(.title2.bold()).foregroundColor(.white)
                    .padding(.top, 40)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(pullResults) { result in
                            ResultCard(result: result)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Button(action: { showResults = false; pullResults = [] }) {
                    Text("Close")
                        .font(.headline.bold()).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.white).cornerRadius(14)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Pull Logic

    func performPull(count: Int) {
        guard !isPulling else { return }
        isPulling = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            var results: [GachaResult] = []
            switch selectedBanner {
            case .skill: results = gameState.pullSkill(count: count)
            case .weapon: results = gameState.pullWeapon(count: count)
            case .jobCrystal:
                for _ in 0..<count {
                    let job = GameData.allJobs.filter { !$0.isLocked }.randomElement()!
                    let shard = GachaResult.jobShard(job.name)
                    let shardKey = job.id
                    gameState.player.jobShards[shardKey, default: 0] += 1
                    results.append(shard)
                }
            case .shadow:
                let rank = gameState.selectedDungeonRank
                let enemies = GameData.regularEnemies(for: rank)
                if let enemy = enemies.randomElement() {
                    let shadow = ShadowSoldier(id: UUID().uuidString, name: "Shadow \(enemy.name)", emoji: enemy.emoji, atk: enemy.atk / 2, turnsRemaining: 5)
                    gameState.combat.shadowSoldiers.append(shadow)
                    results.append(.shadowSoldier(shadow))
                }
            }

            isPulling = false
            if !results.isEmpty {
                pullResults = results.map { GachaResultDisplay(result: $0) }
                showResults = true
            }
        }
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let result: GachaResultDisplay
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(result.rarity.swiftUIColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(result.rarity.swiftUIColor.opacity(0.6), lineWidth: 1.5)
                    )
                VStack(spacing: 6) {
                    Text(result.emoji).font(.system(size: 36))
                    Text(result.name)
                        .font(.caption.bold()).foregroundColor(.white)
                        .multilineTextAlignment(.center).lineLimit(2)
                    RarityBadge(rarity: result.rarity)
                }
                .padding(12)
            }
        }
        .scaleEffect(isRevealed ? 1.0 : 0.3)
        .opacity(isRevealed ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double.random(in: 0...0.5))) {
                isRevealed = true
            }
        }
    }
}

// MARK: - Rates Grid

struct RatesGrid: View {
    let rates: [(String, String, Color)]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(rates, id: \.0) { rate in
                HStack(spacing: 4) {
                    Text(rate.0).font(.caption.bold()).foregroundColor(rate.2)
                    Text(rate.1).font(.caption2).foregroundColor(.secondary)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(rate.2.opacity(0.1)).cornerRadius(6)
            }
        }
    }
}
