import Foundation

struct PlanningEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var facility: String = "LPST"
    var title: String = ""
    var startDate: String = ""
    var endDate: String = ""
    var researcher: String = ""
    var email: String = ""
    var fuel: String = ""
    var pressure: String = ""
    var temp: String = ""
    var diag: String = ""
    var desc: String = ""
    var status: PlanningStatus = .pendingApproval
    var priority: String = "Normal"
    var requestedBy: String = ""
    var _ts: Int64 = 0
    var resolvedBy: String?
    var resolvedAt: String?
    var extensionRequest: ExtensionRequest?

    enum PlanningStatus: String, Codable, CaseIterable {
        case pendingApproval = "Pending Approval"
        case approved = "Approved"
        case rejected = "Rejected"
        case cancelled = "Cancelled"

        var color: String {
            switch self {
            case .pendingApproval: return "amber"
            case .approved: return "green"
            case .rejected: return "red"
            case .cancelled: return "muted"
            }
        }
    }
}

struct ExtensionRequest: Codable {
    var startDate: String?
    var endDate: String?
    var status: String = "pending"
    var resolvedAt: String?
    var resolvedBy: String?
}
