import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let primary = Color("AppPrimary")
    static let accent = Color.accentColor // orange #ff6b35

    static let cardBackground = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.12)
    static let secondaryText = Color.white.opacity(0.6)
    static let tertiaryText = Color.white.opacity(0.4)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

struct StatCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func statCardStyle() -> some View {
        modifier(StatCardStyle())
    }
}
