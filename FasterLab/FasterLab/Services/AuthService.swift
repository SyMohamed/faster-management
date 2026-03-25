import Foundation
import CryptoKit
import FirebaseDatabase

// MARK: - Authentication Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: FasterUser?
    @Published var currentUsername: String = ""
    @Published var allUsers: [String: FasterUser] = [:]

    var isAdmin: Bool { currentUser?.isAdmin ?? false }
    var isReadOnly: Bool { currentUser?.isReadOnly ?? false }
    var displayName: String { currentUser?.name ?? "" }
    var role: FasterUser.UserRole { currentUser?.role ?? .member }

    private var usersHandle: UInt?

    private init() {}

    // MARK: - SHA-256 hashing (matching web app's crypto.subtle.digest)

    func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Login

    func login(username: String, password: String) async throws -> Bool {
        let db = Database.database().reference()
        let snapshot = try await db.child("faster_users/\(username)").getData()

        guard let dict = snapshot.value as? [String: Any],
              let storedHash = dict["passwordHash"] as? String else {
            throw AuthError.userNotFound
        }

        let inputHash = hashPassword(password)
        guard inputHash == storedHash else {
            throw AuthError.wrongPassword
        }

        let user = FasterUser(
            id: username,
            name: dict["name"] as? String ?? username,
            passwordHash: storedHash,
            role: FasterUser.UserRole(rawValue: dict["role"] as? String ?? "member") ?? .member,
            createdAt: dict["createdAt"] as? String ?? "",
            createdBy: dict["createdBy"] as? String,
            approvedAt: dict["approvedAt"] as? String,
            photoURL: dict["photoURL"] as? String
        )

        currentUser = user
        currentUsername = username
        isAuthenticated = true

        // Start observing all users (for display names, etc.)
        startObservingUsers()

        return true
    }

    // MARK: - Guest login

    func loginAsGuest() {
        let guest = FasterUser(
            id: "guest",
            name: "Guest",
            passwordHash: "",
            role: .viewer,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        currentUser = guest
        currentUsername = "guest"
        isAuthenticated = true
        startObservingUsers()
    }

    // MARK: - Register

    func register(name: String, username: String, password: String) async throws {
        let db = Database.database().reference()

        // Check if username exists
        let existing = try await db.child("faster_users/\(username)").getData()
        if existing.exists() {
            throw AuthError.usernameTaken
        }

        // Check pending
        let pendingCheck = try await db.child("faster_pending/\(username)").getData()
        if pendingCheck.exists() {
            throw AuthError.pendingApproval
        }

        let hash = hashPassword(password)
        let data: [String: Any] = [
            "name": name,
            "username": username,
            "passwordHash": hash,
            "requestedAt": ISO8601DateFormatter().string(from: Date()),
            "status": "pending",
        ]

        try await db.child("faster_pending/\(username)").setValue(data)
    }

    // MARK: - Change password

    func changePassword(username: String, oldPassword: String, newPassword: String) async throws {
        let db = Database.database().reference()
        let snapshot = try await db.child("faster_users/\(username)").getData()

        guard let dict = snapshot.value as? [String: Any],
              let storedHash = dict["passwordHash"] as? String else {
            throw AuthError.userNotFound
        }

        let oldHash = hashPassword(oldPassword)
        guard oldHash == storedHash else {
            throw AuthError.wrongPassword
        }

        let newHash = hashPassword(newPassword)
        try await db.child("faster_users/\(username)/passwordHash").setValue(newHash)
    }

    // MARK: - Logout

    func logout() {
        if let handle = usersHandle {
            Database.database().reference().child("faster_users").removeObserver(withHandle: handle)
            usersHandle = nil
        }
        currentUser = nil
        currentUsername = ""
        isAuthenticated = false
        allUsers = [:]
    }

    // MARK: - User management (admin)

    func approveUser(username: String) async throws {
        let db = Database.database().reference()
        let pendingSnap = try await db.child("faster_pending/\(username)").getData()

        guard let dict = pendingSnap.value as? [String: Any] else {
            throw AuthError.userNotFound
        }

        let userData: [String: Any] = [
            "name": dict["name"] as? String ?? username,
            "passwordHash": dict["passwordHash"] as? String ?? "",
            "role": "member",
            "createdAt": dict["requestedAt"] as? String ?? ISO8601DateFormatter().string(from: Date()),
            "createdBy": currentUsername,
            "approvedAt": ISO8601DateFormatter().string(from: Date()),
        ]

        try await db.child("faster_users/\(username)").setValue(userData)
        try await db.child("faster_pending/\(username)").removeValue()
    }

    func rejectUser(username: String) async throws {
        let db = Database.database().reference()
        try await db.child("faster_pending/\(username)").removeValue()
    }

    // MARK: - Observe users

    private func startObservingUsers() {
        let db = Database.database().reference()
        usersHandle = db.child("faster_users").observe(.value) { [weak self] snapshot in
            var users: [String: FasterUser] = [:]
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                let user = FasterUser(
                    id: snap.key,
                    name: dict["name"] as? String ?? "",
                    passwordHash: "",
                    role: FasterUser.UserRole(rawValue: dict["role"] as? String ?? "member") ?? .member,
                    createdAt: dict["createdAt"] as? String ?? ""
                )
                users[snap.key] = user
            }
            Task { @MainActor in
                self?.allUsers = users
            }
        }
    }

    func userName(for key: String) -> String {
        allUsers[key]?.name ?? key
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case userNotFound
    case wrongPassword
    case usernameTaken
    case pendingApproval

    var errorDescription: String? {
        switch self {
        case .userNotFound: return "User not found"
        case .wrongPassword: return "Incorrect password"
        case .usernameTaken: return "Username already taken"
        case .pendingApproval: return "Registration pending admin approval"
        }
    }
}
