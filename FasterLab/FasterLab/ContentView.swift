import SwiftUI

struct ContentView: View {
    @ObservedObject var auth = AuthService.shared
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
                    .overlay(alignment: .bottom) {
                        if auth.isReadOnly {
                            ReadOnlyBanner()
                        }
                    }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: Int
    @ObservedObject var auth = AuthService.shared
    @State private var showUserMenu = false
    @State private var showPasswordChange = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                OrdersView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Orders", systemImage: "cart")
            }
            .tag(1)

            NavigationStack {
                ChemicalsView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Chemicals", systemImage: "flask")
            }
            .tag(2)

            NavigationStack {
                AssetsView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Assets", systemImage: "wrench.and.screwdriver")
            }
            .tag(3)

            NavigationStack {
                PlanningView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Planning", systemImage: "calendar.badge.clock")
            }
            .tag(4)

            NavigationStack {
                SafetyView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Safety", systemImage: "shield.checkered")
            }
            .tag(5)

            NavigationStack {
                GuideView()
                    .toolbar { navToolbar }
            }
            .tabItem {
                Label("Guide", systemImage: "book")
            }
            .tag(6)
        }
        .tint(FasterTheme.accent)
        .confirmationDialog("Account", isPresented: $showUserMenu) {
            Button("Change Password") { showPasswordChange = true }
            Button("Sign Out", role: .destructive) { auth.logout() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Signed in as \(auth.displayName)")
        }
        .sheet(isPresented: $showPasswordChange) {
            PasswordChangeView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ToolbarContentBuilder
    var navToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showUserMenu = true
            } label: {
                HStack(spacing: 6) {
                    Text(auth.currentUser?.initials ?? "?")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 22, height: 22)
                        .background(FasterTheme.accent)
                        .clipShape(Circle())

                    Text(auth.currentUser?.name.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(FasterTheme.surface2)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(FasterTheme.border1, lineWidth: 1))
            }
        }
    }
}

// MARK: - Read Only Banner

struct ReadOnlyBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye")
                .font(.system(size: 12))
            Text("View-only mode")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text("--")
                .foregroundStyle(.black.opacity(0.5))
            NavigationLink("sign in to edit", destination: EmptyView())
                .font(.system(size: 13, weight: .semibold))
                .underline()
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(FasterTheme.amber)
        .offset(y: -49) // Above tab bar
    }
}

// MARK: - Password Change View

struct PasswordChangeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var auth = AuthService.shared
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            FasterTheme.surface1.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Change Password")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(FasterTheme.text)

                VStack(spacing: 12) {
                    SecureField("Current Password", text: $oldPassword)
                        .fasterInput()
                    SecureField("New Password", text: $newPassword)
                        .fasterInput()
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .fasterInput()
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(FasterTheme.red)
                }

                Button(action: changePassword) {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text("Update Password")
                    }
                }
                .buttonStyle(FasterPrimaryButtonStyle())
                .disabled(isLoading)

                Button("Cancel") { dismiss() }
                    .foregroundStyle(FasterTheme.muted)
            }
            .padding(24)
        }
    }

    private func changePassword() {
        guard !oldPassword.isEmpty, !newPassword.isEmpty else {
            errorMessage = "All fields required"
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        isLoading = true
        Task {
            do {
                try await auth.changePassword(
                    username: auth.currentUsername,
                    oldPassword: oldPassword,
                    newPassword: newPassword
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
