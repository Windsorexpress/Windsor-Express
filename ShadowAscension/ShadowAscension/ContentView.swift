import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var selectedTab: AppTab = .home
    @State private var toastMessage: String? = nil

    enum AppTab: Int, CaseIterable {
        case home, dungeon, combat, gacha, profile

        var label: String {
            switch self {
            case .home: return "Home"
            case .dungeon: return "Gates"
            case .combat: return "Battle"
            case .gacha: return "Summon"
            case .profile: return "Hunter"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .dungeon: return "door.right.hand.open"
            case .combat: return "bolt.shield.fill"
            case .gacha: return "sparkles"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            if !gameState.player.hasCompletedOnboarding {
                OnboardingView(gameState: gameState)
                    .transition(.opacity)
            } else {
                mainApp
            }

            // Global toast notification
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: msg)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: toastMessage)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: gameState.notification) { _, newVal in
            if let notif = newVal {
                showToast(notif.message)
                gameState.notification = nil
            }
        }
        // Switch to combat tab automatically when dungeon starts
        .onChange(of: gameState.isInCombat) { _, newVal in
            if newVal { selectedTab = .combat }
        }
    }

    var mainApp: some View {
        TabView(selection: $selectedTab) {
            HomeView(gameState: gameState)
                .tabItem { Label(AppTab.home.label, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            DungeonListView(gameState: gameState)
                .tabItem { Label(AppTab.dungeon.label, systemImage: AppTab.dungeon.icon) }
                .tag(AppTab.dungeon)

            CombatView(gameState: gameState)
                .tabItem {
                    Label(AppTab.combat.label, systemImage: AppTab.combat.icon)
                }
                .tag(AppTab.combat)
                .badge(gameState.isInCombat ? "!" : nil)

            GachaView(gameState: gameState)
                .tabItem { Label(AppTab.gacha.label, systemImage: AppTab.gacha.icon) }
                .tag(AppTab.gacha)

            ProfileView(gameState: gameState)
                .tabItem { Label(AppTab.profile.label, systemImage: AppTab.profile.icon) }
                .tag(AppTab.profile)
        }
        .tint(.blue)
    }

    func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}
