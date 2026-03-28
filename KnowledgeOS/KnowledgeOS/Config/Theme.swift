import SwiftUI

enum Theme {
    // MARK: - Colors (Light / Glass UI)
    static let bg = Color(.systemBackground)
    static let surface = Color.white.opacity(0.6)
    static let surfaceElevated = Color.white.opacity(0.75)
    static let surfaceHover = Color.white.opacity(0.85)
    static let border = Color.black.opacity(0.08)
    static let borderHover = Color.black.opacity(0.12)

    static let textPrimary = Color(hex: "1A1A2E")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")

    static let accent = Color(hex: "0071FA")
    static let accentLight = Color(hex: "3D94FF")
    static let accentDim = Color(hex: "0071FA").opacity(0.10)

    static let extract = Color(hex: "F59E0B")
    static let extractDim = Color(hex: "F59E0B").opacity(0.08)

    static let synthesis = Color(hex: "22C55E")
    static let synthesisDim = Color(hex: "22C55E").opacity(0.08)

    static let skill = Color(hex: "8B5CF6")
    static let skillDim = Color(hex: "8B5CF6").opacity(0.08)

    static let destructive = Color(hex: "EF4444")
    static let star = Color(hex: "FBBF24")

    // MARK: - Glass
    static let glassMaterial: Material = .ultraThinMaterial
    static let glassCardMaterial: Material = .thinMaterial

    // MARK: - Tag Color Palette
    static let tagColors: [String] = [
        "#6366F1", "#8B5CF6", "#EC4899", "#EF4444",
        "#F59E0B", "#22C55E", "#14B8A6", "#3B82F6",
        "#F97316", "#A855F7", "#06B6D4", "#84CC16",
    ]

    // MARK: - Spacing
    static let cardPadding: CGFloat = 16
    static let cardGap: CGFloat = 16
    static let cardRadius: CGFloat = 16
    static let inputRadius: CGFloat = 12
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
