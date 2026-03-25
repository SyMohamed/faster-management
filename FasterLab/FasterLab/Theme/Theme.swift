import SwiftUI

// MARK: - Design Tokens matching the web app's shared.css

enum FasterTheme {

    // MARK: - Colors (Dark mode primary, matching --bg, --s1, --s2, etc.)

    static let background = Color(hex: "#090d12")
    static let surface1 = Color(hex: "#111720")
    static let surface2 = Color(hex: "#181f2a")
    static let surface3 = Color(hex: "#1e2736")
    static let surface4 = Color(hex: "#252e3e")

    static let border1 = Color(hex: "#232e3d")
    static let border2 = Color(hex: "#2e3f54")
    static let border3 = Color(hex: "#374660")

    static let text = Color(hex: "#dde6f0")
    static let muted = Color(hex: "#6a7d94")
    static let muted2 = Color(hex: "#3e5068")

    static let accent = Color(hex: "#00ccf5")
    static let accent2 = Color(hex: "#00a8cc")

    // Semantic colors
    static let green = Color(hex: "#22c55e")
    static let red = Color(hex: "#ef4444")
    static let amber = Color(hex: "#f59e0b")
    static let blue = Color(hex: "#3b82f6")
    static let purple = Color(hex: "#a855f7")
    static let teal = Color(hex: "#14b8a6")
    static let orange = Color(hex: "#f97316")

    // Background variants for semantic colors
    static let greenBg = Color(hex: "#22c55e").opacity(0.1)
    static let redBg = Color(hex: "#ef4444").opacity(0.1)
    static let amberBg = Color(hex: "#f59e0b").opacity(0.1)
    static let blueBg = Color(hex: "#3b82f6").opacity(0.1)
    static let purpleBg = Color(hex: "#a855f7").opacity(0.1)

    // MARK: - Light Mode Colors

    enum Light {
        static let background = Color(hex: "#f0f4f8")
        static let surface1 = Color.white
        static let surface2 = Color(hex: "#f5f8fb")
        static let surface3 = Color(hex: "#edf2f7")
        static let surface4 = Color(hex: "#e2e8f0")

        static let border1 = Color(hex: "#cbd5e1")
        static let border2 = Color(hex: "#94a3b8")

        static let text = Color(hex: "#0f172a")
        static let muted = Color(hex: "#475569")
        static let muted2 = Color(hex: "#64748b")

        static let accent = Color(hex: "#0099bb")
        static let accent2 = Color(hex: "#0077aa")
    }

    // MARK: - Corner Radius

    static let cornerRadius: CGFloat = 8
    static let cornerRadiusLarge: CGFloat = 12
    static let cornerRadiusXL: CGFloat = 16

    // MARK: - Helper to get semantic color by name

    static func semanticColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "green": return green
        case "red": return red
        case "amber": return amber
        case "blue": return blue
        case "purple": return purple
        case "teal": return teal
        case "orange": return orange
        case "muted": return muted
        default: return accent
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct FasterCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FasterTheme.surface1)
            .clipShape(RoundedRectangle(cornerRadius: FasterTheme.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: FasterTheme.cornerRadiusLarge)
                    .stroke(FasterTheme.border1, lineWidth: 1)
            )
    }
}

struct FasterInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(FasterTheme.surface2)
            .foregroundStyle(FasterTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(FasterTheme.border1, lineWidth: 1.5)
            )
    }
}

struct FasterPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(FasterTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct FasterSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(FasterTheme.muted)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(FasterTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(FasterTheme.border2, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

extension View {
    func fasterCard() -> some View {
        modifier(FasterCardModifier())
    }

    func fasterInput() -> some View {
        modifier(FasterInputModifier())
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
