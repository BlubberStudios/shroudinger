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
        
        // Responsive spacing helpers
        static func responsive(compact: CGFloat, regular: CGFloat) -> CGFloat {
            // Simple responsive helper - could be enhanced with actual size class detection
            return regular
        }
        
        static let cardSpacing = responsive(compact: sm, regular: md)
        static let sectionMargin = responsive(compact: md, regular: lg)
        static let layoutPadding = responsive(compact: sm, regular: md)
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
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let microInteraction = SwiftUI.Animation.easeInOut(duration: 0.1)
        
        // Specific animations for different use cases
        static let cardAppear = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1)
        static let buttonPress = SwiftUI.Animation.easeInOut(duration: 0.08)
        static let statusChange = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Design Components

// Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    var background: Color = DesignSystem.Colors.backgroundSecondary
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.card
    var shadow: Shadow = DesignSystem.Shadows.small
    var isInteractive: Bool = false
    
    @State private var isHovered = false
    
    init(
        background: Color = DesignSystem.Colors.backgroundSecondary,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: Shadow = DesignSystem.Shadows.small,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.isInteractive = isInteractive
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.componentPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isInteractive && isHovered 
                                ? DesignSystem.Colors.primary.opacity(0.2)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: shadow.color,
                radius: isInteractive && isHovered ? shadow.radius * 1.5 : shadow.radius,
                x: shadow.x,
                y: isInteractive && isHovered ? shadow.y * 1.5 : shadow.y
            )
            .scaleEffect(isInteractive && isHovered ? 1.005 : 1.0)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .onHover { if isInteractive { isHovered = $0 } }
    }
}

// Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary,
                                DesignSystem.Colors.primaryDark
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(.white.opacity(configuration.isPressed ? 0.2 : isHovered ? 0.1 : 0))
                    )
                    .shadow(
                        color: DesignSystem.Colors.primary.opacity(0.3),
                        radius: isHovered ? 6 : 3,
                        x: 0,
                        y: isHovered ? 3 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.Animation.buttonPress, value: configuration.isPressed)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(
                        DesignSystem.Colors.primary.opacity(isHovered ? 1.0 : 0.7),
                        lineWidth: isHovered ? 1.5 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(
                                configuration.isPressed 
                                ? DesignSystem.Colors.primary.opacity(0.15)
                                : isHovered 
                                ? DesignSystem.Colors.primary.opacity(0.05)
                                : Color.clear
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : isHovered ? 1.01 : 1.0)
            .animation(DesignSystem.Animation.buttonPress, value: configuration.isPressed)
            .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            .onHover { isHovered = $0 }
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
        
        var isAnimated: Bool {
            switch self {
            case .connecting: return true
            default: return false
            }
        }
    }
    
    let status: Status
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if status.isAnimated {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear { isAnimating = true }
                    .onDisappear { isAnimating = false }
            } else {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .animation(DesignSystem.Animation.statusChange, value: status.color)
            }
            
            Text(status.label)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .animation(DesignSystem.Animation.statusChange, value: status.label)
        }
    }
}

// Loading Indicator Component
struct LoadingIndicator: View {
    let size: CGFloat
    @State private var isAnimating = false
    
    init(size: CGFloat = 20) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                DesignSystem.Colors.primary,
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
            .onDisappear { isAnimating = false }
    }
}

// Helper for Shadow
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// Modern Text Field Component
struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var description: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text(title)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .font(DesignSystem.Typography.body)
            
            if let description = description {
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// Modern Section Header Component
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// Enhanced Toggle Component
struct ModernToggle: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    let onChange: (() -> Void)?
    
    init(
        _ title: String,
        description: String? = nil,
        isOn: Binding<Bool>,
        onChange: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(title)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let description = description {
                            Text(description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isOn)
                        .toggleStyle(.switch)
                        .onChange(of: isOn) { _ in
                            onChange?()
                        }
                }
            }
        }
    }
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