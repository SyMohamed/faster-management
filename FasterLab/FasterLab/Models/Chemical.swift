import Foundation

struct Chemical: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String = ""
    var cas: String = ""
    var location: String = ""
    var status: String = "In Stock"
    var qty: String = ""
    var purity: String = ""
    var owner: String = ""
    var ownerEmail: String = ""
    var currentUser: String = ""
    var userEmail: String = ""
    var desc: String = ""
    var notes: String = ""
    var dateReceived: String = ""
    var expiryDate: String = ""
    var _ts: Int64 = 0

    var isExpiringSoon: Bool {
        guard !expiryDate.isEmpty else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let expiry = formatter.date(from: expiryDate) else { return false }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return daysUntilExpiry <= 30 && daysUntilExpiry >= 0
    }

    var isExpired: Bool {
        guard !expiryDate.isEmpty else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let expiry = formatter.date(from: expiryDate) else { return false }
        return expiry < Date()
    }
}
