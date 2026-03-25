import Foundation
import FirebaseCore
import FirebaseDatabase

// MARK: - Firebase Service (singleton for all database operations)

@MainActor
final class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private let db: DatabaseReference

    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        db = Database.database().reference()
    }

    // MARK: - Generic CRUD

    func observe<T: Decodable>(path: String, decode: @escaping ([String: Any]) -> T?) async -> AsyncStream<[T]> {
        AsyncStream { continuation in
            let ref = db.child(path)
            let handle = ref.observe(.value) { snapshot in
                var items: [T] = []
                for child in snapshot.children {
                    guard let snap = child as? DataSnapshot,
                          var dict = snap.value as? [String: Any] else { continue }
                    dict["id"] = snap.key
                    if let item = decode(dict) {
                        items.append(item)
                    }
                }
                continuation.yield(items)
            }
            continuation.onTermination = { _ in
                ref.removeObserver(withHandle: handle)
            }
        }
    }

    func fetchOnce(path: String) async throws -> DataSnapshot {
        try await db.child(path).getData()
    }

    func write(path: String, value: [String: Any]) async throws {
        try await db.child(path).setValue(value)
    }

    func push(path: String, value: [String: Any]) async throws -> String {
        let ref = db.child(path).childByAutoId()
        try await ref.setValue(value)
        return ref.key ?? ""
    }

    func update(path: String, values: [String: Any]) async throws {
        try await db.child(path).updateChildValues(values)
    }

    func delete(path: String) async throws {
        try await db.child(path).removeValue()
    }

    // MARK: - Orders

    func observeOrders(onChange: @escaping ([Order]) -> Void) -> UInt {
        let ref = db.child("faster_orders")
        return ref.observe(.value) { snapshot in
            var orders: [Order] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var order = Order()
                order.id = snap.key
                order.requester = dict["requester"] as? String ?? ""
                order.item = dict["item"] as? String ?? ""
                order.status = Order.OrderStatus(rawValue: dict["status"] as? String ?? "") ?? .prSubmitted
                order.pr = dict["pr"] as? String ?? ""
                order.po = dict["po"] as? String ?? ""
                order.created = dict["created"] as? String ?? ""
                order.createdBy = dict["createdBy"] as? String ?? ""
                order.delivery = dict["delivery"] as? String ?? ""
                order.newDate = dict["newDate"] as? String ?? ""
                order.comments = dict["comments"] as? String ?? ""
                order.addedBy = dict["addedBy"] as? String ?? ""
                orders.append(order)
            }
            onChange(orders)
        }
    }

    func saveOrder(_ order: Order) async throws {
        let data: [String: Any] = [
            "requester": order.requester,
            "item": order.item,
            "status": order.status.rawValue,
            "pr": order.pr,
            "po": order.po,
            "created": order.created,
            "createdBy": order.createdBy,
            "delivery": order.delivery,
            "newDate": order.newDate,
            "comments": order.comments,
            "addedBy": order.addedBy,
        ]
        if order.id.isEmpty || order.id == UUID().uuidString {
            _ = try await push(path: "faster_orders", value: data)
        } else {
            try await write(path: "faster_orders/\(order.id)", value: data)
        }
    }

    func deleteOrder(_ id: String) async throws {
        try await delete(path: "faster_orders/\(id)")
    }

    // MARK: - Chemicals

    func observeChemicals(onChange: @escaping ([Chemical]) -> Void) -> UInt {
        let ref = db.child("faster_chemicals")
        return ref.observe(.value) { snapshot in
            var chemicals: [Chemical] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var chem = Chemical()
                chem.id = snap.key
                chem.name = dict["name"] as? String ?? ""
                chem.cas = dict["cas"] as? String ?? ""
                chem.location = dict["location"] as? String ?? ""
                chem.status = dict["status"] as? String ?? "In Stock"
                chem.qty = dict["qty"] as? String ?? ""
                chem.purity = dict["purity"] as? String ?? ""
                chem.owner = dict["owner"] as? String ?? ""
                chem.ownerEmail = dict["ownerEmail"] as? String ?? ""
                chem.currentUser = dict["currentUser"] as? String ?? ""
                chem.userEmail = dict["userEmail"] as? String ?? ""
                chem.desc = dict["desc"] as? String ?? ""
                chem.notes = dict["notes"] as? String ?? ""
                chem.dateReceived = dict["dateReceived"] as? String ?? ""
                chem.expiryDate = dict["expiryDate"] as? String ?? ""
                chem._ts = dict["_ts"] as? Int64 ?? 0
                chemicals.append(chem)
            }
            onChange(chemicals)
        }
    }

    func saveChemical(_ chemical: Chemical) async throws {
        let data: [String: Any] = [
            "name": chemical.name,
            "cas": chemical.cas,
            "location": chemical.location,
            "status": chemical.status,
            "qty": chemical.qty,
            "purity": chemical.purity,
            "owner": chemical.owner,
            "ownerEmail": chemical.ownerEmail,
            "currentUser": chemical.currentUser,
            "userEmail": chemical.userEmail,
            "desc": chemical.desc,
            "notes": chemical.notes,
            "dateReceived": chemical.dateReceived,
            "expiryDate": chemical.expiryDate,
            "_ts": chemical._ts > 0 ? chemical._ts : Int64(Date().timeIntervalSince1970 * 1000),
        ]
        if chemical.id.isEmpty {
            _ = try await push(path: "faster_chemicals", value: data)
        } else {
            try await write(path: "faster_chemicals/\(chemical.id)", value: data)
        }
    }

    func deleteChemical(_ id: String) async throws {
        try await delete(path: "faster_chemicals/\(id)")
    }

    // MARK: - Assets

    func observeAssets(onChange: @escaping ([Asset]) -> Void) -> UInt {
        let ref = db.child("faster_assets_v5")
        return ref.observe(.value) { snapshot in
            var assets: [Asset] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var asset = Asset()
                asset.id = snap.key
                asset.category = Asset.AssetCategory(rawValue: dict["_cat"] as? String ?? "") ?? .laser
                asset.status = Asset.AssetStatus(rawValue: dict["_status"] as? String ?? "") ?? .operational
                asset.notes = dict["_notes"] as? String ?? ""
                asset.timestamp = dict["_ts"] as? Int64 ?? 0
                // Collect all other fields as dynamic fields
                var fields: [String: String] = [:]
                for (key, value) in dict where !key.hasPrefix("_") && key != "id" {
                    fields[key] = "\(value)"
                }
                asset.fields = fields
                assets.append(asset)
            }
            onChange(assets)
        }
    }

    func saveAsset(_ asset: Asset) async throws {
        var data: [String: Any] = [
            "_cat": asset.category.rawValue,
            "_status": asset.status.rawValue,
            "_notes": asset.notes,
            "_ts": asset.timestamp > 0 ? asset.timestamp : Int64(Date().timeIntervalSince1970 * 1000),
        ]
        for (key, value) in asset.fields {
            data[key] = value
        }
        if asset.id.isEmpty {
            _ = try await push(path: "faster_assets_v5", value: data)
        } else {
            try await write(path: "faster_assets_v5/\(asset.id)", value: data)
        }
    }

    func deleteAsset(_ id: String) async throws {
        try await delete(path: "faster_assets_v5/\(id)")
    }

    // MARK: - Planning

    func observePlanning(onChange: @escaping ([PlanningEntry]) -> Void) -> UInt {
        let ref = db.child("faster_planning")
        return ref.observe(.value) { snapshot in
            var entries: [PlanningEntry] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var entry = PlanningEntry()
                entry.id = snap.key
                entry.facility = dict["facility"] as? String ?? ""
                entry.title = dict["title"] as? String ?? ""
                entry.startDate = dict["startDate"] as? String ?? ""
                entry.endDate = dict["endDate"] as? String ?? ""
                entry.researcher = dict["researcher"] as? String ?? ""
                entry.email = dict["email"] as? String ?? ""
                entry.fuel = dict["fuel"] as? String ?? ""
                entry.pressure = dict["pressure"] as? String ?? ""
                entry.temp = dict["temp"] as? String ?? ""
                entry.diag = dict["diag"] as? String ?? ""
                entry.desc = dict["desc"] as? String ?? ""
                entry.status = PlanningEntry.PlanningStatus(rawValue: dict["status"] as? String ?? "") ?? .pendingApproval
                entry.priority = dict["priority"] as? String ?? "Normal"
                entry.requestedBy = dict["requestedBy"] as? String ?? ""
                entry._ts = dict["_ts"] as? Int64 ?? 0
                entry.resolvedBy = dict["resolvedBy"] as? String
                entry.resolvedAt = dict["resolvedAt"] as? String
                entries.append(entry)
            }
            onChange(entries)
        }
    }

    func savePlanning(_ entry: PlanningEntry) async throws {
        let data: [String: Any] = [
            "facility": entry.facility,
            "title": entry.title,
            "startDate": entry.startDate,
            "endDate": entry.endDate,
            "researcher": entry.researcher,
            "email": entry.email,
            "fuel": entry.fuel,
            "pressure": entry.pressure,
            "temp": entry.temp,
            "diag": entry.diag,
            "desc": entry.desc,
            "status": entry.status.rawValue,
            "priority": entry.priority,
            "requestedBy": entry.requestedBy,
            "_ts": entry._ts > 0 ? entry._ts : Int64(Date().timeIntervalSince1970 * 1000),
        ]
        if entry.id.isEmpty {
            _ = try await push(path: "faster_planning", value: data)
        } else {
            try await write(path: "faster_planning/\(entry.id)", value: data)
        }
    }

    func updatePlanningStatus(id: String, status: String, resolvedBy: String) async throws {
        let isoDate = ISO8601DateFormatter().string(from: Date())
        try await update(path: "faster_planning/\(id)", values: [
            "status": status,
            "resolvedBy": resolvedBy,
            "resolvedAt": isoDate,
        ])
    }

    func deletePlanning(_ id: String) async throws {
        try await delete(path: "faster_planning/\(id)")
    }

    // MARK: - Safety

    func observeSafetyReports(onChange: @escaping ([SafetyReport]) -> Void) -> UInt {
        let ref = db.child("faster_safety/reports")
        return ref.observe(.value) { snapshot in
            var reports: [SafetyReport] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var report = SafetyReport()
                report.id = snap.key
                report.title = dict["title"] as? String ?? ""
                report.location = dict["location"] as? String ?? ""
                report.description = dict["description"] as? String ?? ""
                report.severity = SafetyReport.Severity(rawValue: dict["severity"] as? String ?? "") ?? .low
                report.reporter = dict["reporter"] as? String ?? ""
                report.causedBy = dict["causedBy"] as? String ?? ""
                report.status = SafetyReport.ReportStatus(rawValue: dict["status"] as? String ?? "") ?? .open
                report.photo = dict["photo"] as? String ?? ""
                report._ts = dict["_ts"] as? Int64 ?? 0
                report.resolvedBy = dict["resolvedBy"] as? String
                report.resolvedAt = dict["resolvedAt"] as? Int64
                reports.append(report)
            }
            onChange(reports)
        }
    }

    func saveSafetyReport(_ report: SafetyReport) async throws {
        var data: [String: Any] = [
            "title": report.title,
            "location": report.location,
            "description": report.description,
            "severity": report.severity.rawValue,
            "reporter": report.reporter,
            "causedBy": report.causedBy,
            "status": report.status.rawValue,
            "photo": report.photo,
            "_ts": report._ts > 0 ? report._ts : Int64(Date().timeIntervalSince1970 * 1000),
        ]
        if let resolvedBy = report.resolvedBy {
            data["resolvedBy"] = resolvedBy
        }
        if let resolvedAt = report.resolvedAt {
            data["resolvedAt"] = resolvedAt
        }
        if report.id.isEmpty {
            _ = try await push(path: "faster_safety/reports", value: data)
        } else {
            try await write(path: "faster_safety/reports/\(report.id)", value: data)
        }
    }

    func deleteSafetyReport(_ id: String) async throws {
        try await delete(path: "faster_safety/reports/\(id)")
    }

    // MARK: - Guide

    func observeGuideCategories(onChange: @escaping ([GuideCategory]) -> Void) -> UInt {
        let ref = db.child("faster_guide/categories")
        return ref.observe(.value) { snapshot in
            var categories: [GuideCategory] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var cat = GuideCategory()
                cat.id = snap.key
                cat.name = dict["name"] as? String ?? ""
                cat.icon = dict["icon"] as? String ?? ""
                cat.color = dict["color"] as? String ?? "#00b4d8"
                cat.order = dict["order"] as? Int ?? 0
                categories.append(cat)
            }
            categories.sort { $0.order < $1.order }
            onChange(categories)
        }
    }

    func observeGuideDocs(categoryId: String, onChange: @escaping ([GuideDocument]) -> Void) -> UInt {
        let ref = db.child("faster_guide/docs/\(categoryId)")
        return ref.observe(.value) { snapshot in
            var docs: [GuideDocument] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var doc = GuideDocument()
                doc.id = snap.key
                doc.title = dict["title"] as? String ?? ""
                doc.description = dict["description"] as? String ?? ""
                doc.link = dict["link"] as? String ?? ""
                doc.icon = dict["icon"] as? String ?? "📄"
                doc.createdAt = dict["createdAt"] as? Int64 ?? 0
                doc.categoryId = categoryId
                docs.append(doc)
            }
            onChange(docs)
        }
    }

    // MARK: - Users

    func observeUsers(onChange: @escaping ([String: FasterUser]) -> Void) -> UInt {
        let ref = db.child("faster_users")
        return ref.observe(.value) { snapshot in
            var users: [String: FasterUser] = [:]
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any] else { continue }
                var user = FasterUser(
                    name: dict["name"] as? String ?? "",
                    passwordHash: dict["passwordHash"] as? String ?? "",
                    role: FasterUser.UserRole(rawValue: dict["role"] as? String ?? "member") ?? .member,
                    createdAt: dict["createdAt"] as? String ?? ""
                )
                user.id = snap.key
                user.createdBy = dict["createdBy"] as? String
                user.approvedAt = dict["approvedAt"] as? String
                user.photoURL = dict["photoURL"] as? String
                users[snap.key] = user
            }
            onChange(users)
        }
    }

    // MARK: - Remove observer

    func removeObserver(path: String, handle: UInt) {
        db.child(path).removeObserver(withHandle: handle)
    }
}
