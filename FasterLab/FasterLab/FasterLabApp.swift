import SwiftUI
import FirebaseCore

@main
struct FasterLabApp: App {
    @StateObject private var auth = AuthService.shared

    init() {
        FirebaseApp.configure()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(FasterTheme.surface1)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(FasterTheme.text),
            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(FasterTheme.text),
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(FasterTheme.accent)

        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(FasterTheme.surface1)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = UIColor(FasterTheme.accent)
        UITabBar.appearance().unselectedItemTintColor = UIColor(FasterTheme.muted)
    }
}
