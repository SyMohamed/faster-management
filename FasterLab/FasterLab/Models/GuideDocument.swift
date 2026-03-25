import Foundation

struct GuideCategory: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String = ""
    var icon: String = ""
    var color: String = "#00b4d8"
    var order: Int = 0
}

struct GuideDocument: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String = ""
    var description: String = ""
    var link: String = ""
    var icon: String = "📄"
    var createdAt: Int64 = 0
    var categoryId: String = ""
}
