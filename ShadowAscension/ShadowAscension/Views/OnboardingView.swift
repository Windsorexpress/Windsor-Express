import SwiftUI

struct OnboardingView: View {
    @Bindable var gameState: GameState
    @State private var phase: OnboardingPhase = .intro
    @State private var assignedJob: Job? = nil
    @State private var glowOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.5
    @State private var particlesVisible: Bool = false

    enum OnboardingPhase {
        case intro, gateOpening, reveal, confirm
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .intro:
                introView
            case .gateOpening:
                gateOpeningView
            case .reveal:
                revealView
            case .confirm:
                confirmView
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.5)) { glowOpacity = 1 }
        }
    }

    // MARK: - Intro

    var introView: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("👁️")
                .font(.system(size: 80))
                .opacity(glowOpacity)
                .shadow(color: .blue, radius: 20)

            VStack(spacing: 12) {
                Text("SHADOW ASCENSION")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                Text("The Gates have opened.\nYour awakening begins.")
                    .font(.body).foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .opacity(glowOpacity)

            Spacer()

            Button(action: beginAwakening) {
                Text("ENTER THE GATE")
                    .font(.headline).foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Gate Opening

    var gateOpeningView: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                // Pulsing rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.blue.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 60), height: CGFloat(120 + i * 60))
                        .scaleEffect(particlesVisible ? 1.5 : 0.5)
                        .opacity(particlesVisible ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: particlesVisible)
                }
                Text("🌀")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(particlesVisible ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: particlesVisible)
                    .shadow(color: .blue, radius: 30)
            }
            .frame(height: 260)
            .onAppear { particlesVisible = true }

            VStack(spacing: 8) {
                Text("Scanning Hunter Profile...")
                    .font(.headline).foregroundColor(.blue)
                Text("Determining Awakening Class...")
                    .font(.subheadline).foregroundColor(.gray)
            }
            .padding(.top, 40)
            Spacer()
        }
    }

    // MARK: - Reveal

    var revealView: some View {
        VStack(spacing: 0) {
            Spacer()

            if let job = assignedJob {
                VStack(spacing: 20) {
                    Text("You have awakened as a...")
                        .font(.subheadline).foregroundColor(.gray)
                        .opacity(titleOpacity)

                    Text(job.emoji)
                        .font(.system(size: 100))
                        .scaleEffect(cardScale)
                        .shadow(color: .blue, radius: 30)

                    Text(job.name.uppercased())
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .scaleEffect(cardScale)

                    Text(job.lore)
                        .font(.body).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .opacity(titleOpacity)

                    // Stats
                    HStack(spacing: 20) {
                        StatPill(label: "HP", value: job.baseHP, color: .red)
                        StatPill(label: "ATK", value: job.baseATK, color: .orange)
                        StatPill(label: "DEF", value: job.baseDEF, color: .blue)
                        StatPill(label: "SPD", value: job.baseSPD, color: .green)
                        StatPill(label: "MP", value: job.baseMP, color: .purple)
                    }
                    .opacity(titleOpacity)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: acceptClass) {
                    Text("⚡ Accept Destiny")
                        .font(.headline.bold()).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                }

                if gameState.player.rerollsUsed < 3 {
                    Button(action: reroll) {
                        HStack {
                            Text("🎲 Reroll")
                                .font(.subheadline.bold())
                            Spacer()
                            HStack(spacing: 4) {
                                Text("💎 10")
                                    .font(.caption).foregroundColor(.cyan)
                                Text("(\(3 - gameState.player.rerollsUsed) left)")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Confirm (job select screen)

    var confirmView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose Your Class")
                    .font(.title2.bold()).foregroundColor(.white)
                    .padding(.top, 20)
                Text("Or select from all available classes:")
                    .font(.subheadline).foregroundColor(.gray)

                ForEach(GameData.allJobs.filter { !$0.isLocked }) { job in
                    Button(action: { manualSelectJob(job) }) {
                        JobCard(job: job, isSelected: assignedJob?.id == job.id)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Button(action: acceptClass) {
                    Text("Confirm Class")
                        .font(.headline.bold()).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Actions

    func beginAwakening() {
        phase = .gateOpening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let job = gameState.assignRandomClass()
            assignedJob = job
            phase = .reveal
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
                titleOpacity = 1.0
            }
        }
    }

    func reroll() {
        guard var current = assignedJob else { return }
        let next = gameState.rerollClass(current: &current)
        assignedJob = next
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            cardScale = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { cardScale = 1.0 }
        }
    }

    func acceptClass() {
        guard let job = assignedJob else { return }
        gameState.acceptClass(job)
    }

    func manualSelectJob(_ job: Job) {
        assignedJob = job
    }
}
