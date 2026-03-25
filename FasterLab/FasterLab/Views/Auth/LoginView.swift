import SwiftUI

struct LoginView: View {
    @ObservedObject var auth = AuthService.shared

    @State private var showLogin = false
    @State private var showRegister = false
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            FasterTheme.background.ignoresSafeArea()

            // Grid background pattern
            GridPatternView()

            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "atom")
                        .font(.system(size: 48))
                        .foregroundStyle(FasterTheme.accent)
                        .padding(.bottom, 4)

                    Text("FASTER Lab")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(FasterTheme.text)

                    Text("Digital Workspace")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)
                }

                Spacer().frame(height: 16)

                // Action cards
                VStack(spacing: 12) {
                    // Sign In card
                    Button {
                        showLogin = true
                    } label: {
                        LoginCardRow(
                            icon: "person.crop.circle.fill",
                            iconBg: FasterTheme.accent.opacity(0.15),
                            iconColor: FasterTheme.accent,
                            title: "Sign In",
                            subtitle: "Access your workspace with your credentials",
                            isPrimary: true
                        )
                    }

                    // Register card
                    Button {
                        showRegister = true
                    } label: {
                        LoginCardRow(
                            icon: "person.badge.plus",
                            iconBg: FasterTheme.purple.opacity(0.15),
                            iconColor: FasterTheme.purple,
                            title: "Request Access",
                            subtitle: "Submit a registration request to join",
                            isPrimary: false
                        )
                    }

                    // Guest card
                    Button {
                        auth.loginAsGuest()
                    } label: {
                        LoginCardRow(
                            icon: "eye",
                            iconBg: FasterTheme.muted.opacity(0.15),
                            iconColor: FasterTheme.muted,
                            title: "View as Guest",
                            subtitle: "Browse in read-only mode",
                            isPrimary: false
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Footer
                Text("FASTER Lab \u{00B7} Digital Workspace")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(FasterTheme.muted2)
                    .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginFormSheet(
                username: $username,
                password: $password,
                errorMessage: $errorMessage,
                isLoading: $isLoading,
                onLogin: performLogin,
                onDismiss: { showLogin = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(onDismiss: { showRegister = false })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func performLogin() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password"
            return
        }
        isLoading = true
        errorMessage = ""
        Task {
            do {
                _ = try await auth.login(username: username.lowercased().trimmingCharacters(in: .whitespaces), password: password)
                showLogin = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Login Card Row

struct LoginCardRow: View {
    let icon: String
    let iconBg: Color
    let iconColor: Color
    let title: String
    let subtitle: String
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FasterTheme.text)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(FasterTheme.muted2)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(FasterTheme.muted2)
        }
        .padding(18)
        .background(FasterTheme.surface1.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isPrimary ? FasterTheme.accent.opacity(0.25) : FasterTheme.border2, lineWidth: 1.5)
        )
    }
}

// MARK: - Login Form Sheet

struct LoginFormSheet: View {
    @Binding var username: String
    @Binding var password: String
    @Binding var errorMessage: String
    @Binding var isLoading: Bool
    let onLogin: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            FasterTheme.surface1.ignoresSafeArea()

            VStack(spacing: 16) {
                // Avatar
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FasterTheme.accent)

                Text("Sign In")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(FasterTheme.text)

                Text("Enter your credentials")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(FasterTheme.muted)

                VStack(spacing: 12) {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fasterInput()

                    SecureField("Password", text: $password)
                        .fasterInput()
                }
                .padding(.top, 8)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(FasterTheme.red)
                }

                Button(action: onLogin) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(FasterPrimaryButtonStyle())
                .disabled(isLoading)
                .padding(.top, 4)

                Button("Cancel") {
                    onDismiss()
                }
                .foregroundStyle(FasterTheme.muted)
                .font(.system(size: 14))
            }
            .padding(24)
        }
    }
}

// MARK: - Grid Pattern Background

struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 52
            for x in stride(from: 0, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(FasterTheme.accent.opacity(0.025)), lineWidth: 1)
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(FasterTheme.accent.opacity(0.025)), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}
