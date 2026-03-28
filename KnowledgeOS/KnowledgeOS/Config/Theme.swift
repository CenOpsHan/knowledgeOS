import SwiftUI

enum Theme {
    // MARK: - Colors
    static let bg = Color(hex: "0A0A0C")
    static let surface = Color(hex: "131318")
    static let surfaceElevated = Color(hex: "1A1A22")
    static let surfaceHover = Color(hex: "22222E")
    static let border = Color(hex: "2A2A38")
    static let borderHover = Color(hex: "3A3A4D")

    static let textPrimary = Color(hex: "E8E8F0")
    static let textSecondary = Color(hex: "9898A8")
    static let textTertiary = Color(hex: "686878")

    static let accent = Color(hex: "6366F1")
    static let accentLight = Color(hex: "818CF8")
    static let accentDim = Color(hex: "6366F1").opacity(0.12)

    static let extract = Color(hex: "F59E0B")
    static let extractDim = Color(hex: "F59E0B").opacity(0.04)

    static let synthesis = Color(hex: "22C55E")
    static let synthesisDim = Color(hex: "22C55E").opacity(0.04)

    static let skill = Color(hex: "8B5CF6")
    static let skillDim = Color(hex: "8B5CF6").opacity(0.04)

    static let destructive = Color(hex: "EF4444")
    static let star = Color(hex: "FBBF24")

    // MARK: - Tag Color Palette
    static let tagColors: [String] = [
        "#6366F1", "#8B5CF6", "#EC4899", "#EF4444",
        "#F59E0B", "#22C55E", "#14B8A6", "#3B82F6",
        "#F97316", "#A855F7", "#06B6D4", "#84CC16",
    ]

    // MARK: - Spacing
    static let cardPadding: CGFloat = 16
    static let cardGap: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let inputRadius: CGFloat = 8
    static let sectionSpacing: CGFloat = 24
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
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
