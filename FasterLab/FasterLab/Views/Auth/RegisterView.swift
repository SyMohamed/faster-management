import SwiftUI

struct RegisterView: View {
    @ObservedObject var auth = AuthService.shared
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            FasterTheme.surface1.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(FasterTheme.purple)

                    Text("Request Access")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FasterTheme.text)

                    Text("An admin will review your request")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(FasterTheme.muted)

                    VStack(spacing: 12) {
                        TextField("Full Name", text: $name)
                            .fasterInput()

                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .fasterInput()

                        SecureField("Password", text: $password)
                            .fasterInput()

                        SecureField("Confirm Password", text: $confirmPassword)
                            .fasterInput()
                    }
                    .padding(.top, 8)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(FasterTheme.red)
                    }

                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(FasterTheme.green)
                    }

                    Button(action: performRegister) {
                        if isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Submit Request")
                        }
                    }
                    .buttonStyle(FasterPrimaryButtonStyle())
                    .disabled(isLoading)
                    .padding(.top, 4)

                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(FasterTheme.muted)
                        .font(.system(size: 14))
                }
                .padding(24)
            }
        }
    }

    private func performRegister() {
        errorMessage = ""
        successMessage = ""

        guard !name.isEmpty, !username.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        guard password.count >= 4 else {
            errorMessage = "Password must be at least 4 characters"
            return
        }

        isLoading = true
        Task {
            do {
                try await auth.register(
                    name: name,
                    username: username.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password
                )
                successMessage = "Request submitted! Await admin approval."
                name = ""
                username = ""
                password = ""
                confirmPassword = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
