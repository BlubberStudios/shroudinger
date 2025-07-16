import SwiftUI

// MARK: - Shroudinger Design System
// Modern design tokens and components for consistent UI across the app

struct DesignSystem {
    
    // MARK: - Typography Scale
    struct Typography {
        // Display - Largest text, used for hero content
        static let display = Font.system(size: 28, weight: .bold, design: .default)
        
        // Headlines - Major section headers
        static let headline = Font.system(size: 22, weight: .semibold, design: .default)
        
        // Title - Content titles and important labels
        static let title = Font.system(size: 18, weight: .medium, design: .default)
        static let titleLarge = Font.system(size: 20, weight: .medium, design: .default)
        
        // Body - Main content and descriptions
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        
        // Caption - Secondary information and labels
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
        
        // Small - Smallest text for fine details
        static let small = Font.system(size: 10, weight: .regular, design: .default)
        static let smallMedium = Font.system(size: 10, weight: .medium, design: .default)
    }
    
    // MARK: - Color System
    struct Colors {
        // Primary Colors - Brand identity
        static let primary = Color(red: 0.2, green: 0.3, blue: 0.4)
        static let primaryLight = Color(red: 0.3, green: 0.4, blue: 0.5)
        static let primaryDark = Color(red: 0.1, green: 0.2, blue: 0.3)
        
        // Semantic Colors - Status and feedback
        static let success = Color(red: 0.2, green: 0.7, blue: 0.3)
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let error = Color(red: 0.9, green: 0.2, blue: 0.2)
        static let info = Color(red: 0.2, green: 0.5, blue: 0.9)
        
        // Neutral Colors - Text and backgrounds
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)
        
        // Background Colors - Surfaces and containers
        static let backgroundPrimary = Color(nsColor: .windowBackgroundColor)
        static let backgroundSecondary = Color(nsColor: .controlBackgroundColor)
        static let backgroundTertiary = Color(red: 0.96, green: 0.96, blue: 0.96)
        
        // Privacy Theme Colors
        static let privacyBlue = Color(red: 0.1, green: 0.3, blue: 0.6)
        static let privacyGreen = Color(red: 0.1, green: 0.6, blue: 0.3)
        static let privacyShield = Color(red: 0.15, green: 0.25, blue: 0.35)
    }
    
    // MARK: - Spacing System (8-point grid)
    struct Spacing {
        static let xxs: CGFloat = 4    // 4px - Minimal spacing
        static let xs: CGFloat = 8     // 8px - Small spacing
        static let sm: CGFloat = 12    // 12px - Compact spacing
        static let md: CGFloat = 16    // 16px - Standard spacing
        static let lg: CGFloat = 24    // 24px - Large spacing
        static let xl: CGFloat = 32    // 32px - Extra large spacing
        static let xxl: CGFloat = 48   // 48px - Maximum spacing
        
        // Semantic spacing
        static let componentPadding = md
        static let sectionSpacing = lg
        static let containerPadding = md
    }
    
    // MARK: - Corner Radius System
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
        
        // Semantic radius
        static let card = medium
        static let button = small
        static let container = large
    }
    
    // MARK: - Shadow System
    struct Shadows {
        static let subtle = Shadow(
            color: .black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let small = Shadow(
            color: .black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: .black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: .black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Animation System
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - Design Components

// Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    var background: Color = DesignSystem.Colors.backgroundSecondary
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.card
    var shadow: Shadow = DesignSystem.Shadows.small
    
    init(
        background: Color = DesignSystem.Colors.backgroundSecondary,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: Shadow = DesignSystem.Shadows.small,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.componentPadding)
            .background(background)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(DesignSystem.Colors.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(.white.opacity(configuration.isPressed ? 0.2 : 0))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(configuration.isPressed ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// Status Indicator Component
struct StatusIndicator: View {
    enum Status {
        case connected, disconnected, connecting, error
        
        var color: Color {
            switch self {
            case .connected: return DesignSystem.Colors.success
            case .disconnected: return DesignSystem.Colors.textTertiary
            case .connecting: return DesignSystem.Colors.warning
            case .error: return DesignSystem.Colors.error
            }
        }
        
        var label: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .error: return "Error"
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.label)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// Helper for Shadow
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// View Extension for easier spacing
extension View {
    func spacing(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }
    
    func modernCard(
        background: Color = DesignSystem.Colors.backgroundSecondary,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: Shadow = DesignSystem.Shadows.small
    ) -> some View {
        ModernCard(background: background, cornerRadius: cornerRadius, shadow: shadow) {
            self
        }
    }
}