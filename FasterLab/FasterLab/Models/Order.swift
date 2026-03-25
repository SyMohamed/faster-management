import Foundation

struct Order: Identifiable, Codable {
    var id: String = UUID().uuidString
    var requester: String = ""
    var item: String = ""
    var status: OrderStatus = .prSubmitted
    var pr: String = ""
    var po: String = ""
    var created: String = ""
    var createdBy: String = ""
    var delivery: String = ""
    var newDate: String = ""
    var comments: String = ""
    var addedBy: String = ""

    enum OrderStatus: String, Codable, CaseIterable {
        case prSubmitted = "PR submitted"
        case delayed = "Delayed"
        case delivered = "Delivered"
        case cancelled = "Cancelled"

        var color: String {
            switch self {
            case .prSubmitted: return "blue"
            case .delayed: return "amber"
            case .delivered: return "green"
            case .cancelled: return "red"
            }
        }
    }
}
