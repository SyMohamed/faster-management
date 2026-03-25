import Foundation

struct Asset: Identifiable, Codable {
    var id: String = UUID().uuidString
    var category: AssetCategory = .laser
    var status: AssetStatus = .operational
    var notes: String = ""
    var timestamp: Int64 = 0
    var fields: [String: String] = [:]

    enum AssetCategory: String, Codable, CaseIterable {
        case laser
        case optics
        case pump
        case detector
        case oscillator

        var icon: String {
            switch self {
            case .laser: return "light.max"
            case .optics: return "camera.filters"
            case .pump: return "gauge.with.dots.needle.bottom.50percent"
            case .detector: return "sensor"
            case .oscillator: return "waveform"
            }
        }

        var displayName: String {
            rawValue.capitalized
        }
    }

    enum AssetStatus: String, Codable, CaseIterable {
        case operational = "Operational"
        case inMaintenance = "In Maintenance"
        case nonFunctional = "Non-Functional"

        var color: String {
            switch self {
            case .operational: return "green"
            case .inMaintenance: return "amber"
            case .nonFunctional: return "red"
            }
        }
    }

    // Coding keys to handle the underscore-prefixed Firebase fields
    enum CodingKeys: String, CodingKey {
        case id
        case category = "_cat"
        case status = "_status"
        case notes = "_notes"
        case timestamp = "_ts"
        case fields
    }
}
