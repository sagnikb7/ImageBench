import AppKit
import SwiftUI

enum PFTheme {
    static let coral = Color(red: 0.94, green: 0.35, blue: 0.16)
    static let action = Color(red: 0.05, green: 0.39, blue: 0.90)
    static let success = Color(red: 0.16, green: 0.65, blue: 0.30)
    static let warning = Color(red: 0.93, green: 0.54, blue: 0.08)
    static let danger = Color(red: 0.84, green: 0.20, blue: 0.18)
    static let hoverSurface = coral.opacity(0.075)
    static let hoverBorder = coral.opacity(0.55)
    static let sidebarSelection = coral.opacity(0.14)
    static let sidebarSelectionHover = coral.opacity(0.20)
    static let border = Color(nsColor: .separatorColor).opacity(0.42)
    static let surface = Color(nsColor: .textBackgroundColor)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let secondarySurface = Color(nsColor: .controlBackgroundColor).opacity(0.34)
    static let dropSurface = Color(nsColor: .controlBackgroundColor)
    static let mediaStageSurface = Color.primary.opacity(0.05)
    static let quietSelection = Color(nsColor: .selectedControlColor).opacity(0.08)
}

enum PFSpacing {
    static let micro: CGFloat = 4
    static let compact: CGFloat = 8
    static let control: CGFloat = 12
    static let section: CGFloat = 16
    static let card: CGFloat = 18
    static let screen: CGFloat = 24
    static let spacious: CGFloat = 32
}

enum PFRadius {
    static let control: CGFloat = 8
    static let inset: CGFloat = 10
    static let card: CGFloat = 12
    static let brand: CGFloat = 20
}

enum PFLayout {
    static let minimumWindow = CGSize(width: 1080, height: 720)
    static let defaultWindow = CGSize(width: 1440, height: 900)
    static let sidebarWidth: CGFloat = 230
    static let inspectorWidth: CGFloat = 340
    static let selectionFieldWidth: CGFloat = 220
    static let previewMinimumHeight: CGFloat = 460
    static let primaryActionMinimumWidth: CGFloat = 160
}

enum PFMotion {
    /// Fast enough to acknowledge selection without delaying navigation.
    static let quick = Animation.easeOut(duration: 0.14)
}

private struct PointingHandCursorModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content.onHover { isHovered in
            if isHovered, isEnabled {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

private struct PrimaryActionHoverModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    let color: Color

    func body(content: Content) -> some View {
        content
            .brightness(isHovered && isEnabled ? 0.045 : 0)
            .shadow(color: color.opacity(isHovered && isEnabled ? 0.24 : 0), radius: 5, y: 2)
            .scaleEffect(isHovered && isEnabled && !reduceMotion ? 1.012 : 1)
            .animation(reduceMotion ? nil : PFMotion.quick, value: isHovered)
            .onHover { isHovered = $0 }
            .modifier(PointingHandCursorModifier())
    }
}

extension View {
    func pointingHandCursor() -> some View {
        modifier(PointingHandCursorModifier())
    }

    func primaryActionHover(color: Color = PFTheme.action) -> some View {
        modifier(PrimaryActionHoverModifier(color: color))
    }
}

struct ToolHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title2.weight(.bold))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Gives the product a distinct identity while keeping task typography native and quiet.
struct BrandWordmark: View {
    var body: some View {
        (Text("Image").fontWeight(.heavy)
            + Text("Bench")
            .fontWeight(.bold)
            .italic()
            .foregroundColor(PFTheme.coral))
            .font(.system(.title2, design: .rounded))
            .tracking(-0.6)
            .accessibilityLabel("ImageBench")
    }
}

/// The shared ImageBench identity mark used by the sidebar and app icon.
struct SidebarBrandMark: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "photo.stack.fill")
            .font(.system(size: size * 0.43, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                PFTheme.coral.gradient,
                in: RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

struct SurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(PFSpacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PFTheme.surface, in: RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PFRadius.card, style: .continuous)
                    .stroke(PFTheme.border, lineWidth: 1)
            }
    }
}

/// A quiet grouped region. Use it when spacing and a hairline are enough to establish hierarchy.
struct WorkspaceSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, PFSpacing.control)
    }
}

struct SectionHeading: View {
    let number: Int?
    let title: String

    init(_ title: String, number: Int? = nil) {
        self.title = title
        self.number = number
    }

    var body: some View {
        HStack(spacing: 6) {
            if let number { Text("\(number).").foregroundStyle(PFTheme.coral) }
            Text(title)
        }
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
    }
}

struct StatusPill: View {
    let icon: String
    let text: String
    var color = PFTheme.success

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.10), in: Capsule())
    }
}

struct FileDropWell<Content: View>: View {
    @State private var isHovered = false

    let isTargeted: Bool
    let action: () -> Void
    let content: Content

    init(isTargeted: Bool, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.isTargeted = isTargeted
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, minHeight: 142)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isTargeted ? PFTheme.coral.opacity(0.09) : (isHovered ? PFTheme.hoverSurface : PFTheme.mediaStageSurface)
        )
        .clipShape(RoundedRectangle(cornerRadius: PFRadius.inset, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PFRadius.inset, style: .continuous)
                .strokeBorder(
                    isTargeted ? PFTheme.coral : (isHovered ? PFTheme.hoverBorder : PFTheme.border),
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [6])
                )
        }
        .onHover { isHovered = $0 }
        .pointingHandCursor()
    }
}

struct SelectionField<Items: View>: View {
    @State private var isHovered = false

    let label: String
    let value: String
    let help: String
    private let items: Items

    init(label: String, value: String, help: String, @ViewBuilder items: () -> Items) {
        self.label = label
        self.value = value
        self.help = help
        self.items = items()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Menu {
                items
            } label: {
                HStack(spacing: PFSpacing.compact) {
                    Text(value)
                        .lineLimit(1)
                    Spacer(minLength: PFSpacing.compact)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, PFSpacing.control)
                .frame(width: PFLayout.selectionFieldWidth, height: 36, alignment: .leading)
                .background(
                    isHovered ? PFTheme.hoverSurface : PFTheme.dropSurface,
                    in: RoundedRectangle(cornerRadius: PFRadius.control, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: PFRadius.control, style: .continuous)
                        .stroke(isHovered ? PFTheme.hoverBorder : PFTheme.border, lineWidth: 1)
                }
                .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .frame(width: PFLayout.selectionFieldWidth, height: 36, alignment: .leading)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .pointingHandCursor()
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint("Choose an option")

            Text(help)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A compact, native button presented as a selectable card. Use this for small,
/// finite option sets where seeing every choice is more useful than opening a menu.
struct SelectableCardButton<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let isSelected: Bool
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void
    private let content: Content

    init(
        isSelected: Bool,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? (isHovered ? PFTheme.sidebarSelectionHover : PFTheme.sidebarSelection)
                        : (isHovered ? PFTheme.hoverSurface : PFTheme.secondarySurface)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: PFRadius.control, style: .continuous)
                        .stroke(
                            isSelected ? PFTheme.coral : (isHovered ? PFTheme.hoverBorder : PFTheme.border),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(PFTheme.coral)
                            .padding(6)
                            .accessibilityHidden(true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: PFRadius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pointingHandCursor()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(reduceMotion ? nil : PFMotion.quick, value: isSelected)
    }
}

struct BrandIcon: View {
    var size: CGFloat

    private static let image: NSImage? = {
        guard let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png") else { return nil }
        let image = NSImage(contentsOf: url)
        image?.isTemplate = false
        return image
    }()

    var body: some View {
        Group {
            if let image = Self.image {
                Image(nsImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "photo.stack.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PFTheme.coral)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ResultMetric: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        Label {
            Text("\(value.formatted()) ").fontWeight(.semibold) + Text(label).foregroundColor(.secondary)
        } icon: {
            Image(systemName: icon).foregroundStyle(color)
        }
        .font(.subheadline)
        .accessibilityLabel("\(value) \(label)")
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: Self { self }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
