import Foundation

struct SafetyReport: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String = ""
    var location: String = ""
    var description: String = ""
    var severity: Severity = .low
    var reporter: String = ""
    var causedBy: String = ""
    var status: ReportStatus = .open
    var photo: String = ""
    var _ts: Int64 = 0
    var resolvedBy: String?
    var resolvedAt: Int64?

    enum Severity: String, Codable, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "amber"
            case .low: return "green"
            }
        }

        var rank: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }

    enum ReportStatus: String, Codable, CaseIterable {
        case open = "Open"
        case resolved = "Resolved"
    }
}

struct SafetyMember: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String = ""
    var photo: String = ""
}
