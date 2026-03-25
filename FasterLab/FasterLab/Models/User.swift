import Foundation

struct FasterUser: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var passwordHash: String
    var role: UserRole
    var createdAt: String
    var createdBy: String?
    var approvedAt: String?
    var photoURL: String?

    enum UserRole: String, Codable, CaseIterable {
        case admin
        case member
        case viewer
    }

    var isAdmin: Bool { role == .admin }
    var isReadOnly: Bool { role == .viewer }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct PendingUser: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var username: String
    var passwordHash: String
    var requestedAt: String
    var status: String = "pending"
}
