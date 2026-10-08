import SwiftUI
import SwiftCN

public enum CNTypographyStyle: String, CaseIterable, Sendable {
    case largeTitle, title, heading, body, lead, small, muted, code
    public var classes: TWClasses {
        switch self {
        case .largeTitle: "text-3xl font-bold"
        case .title: "text-2xl font-bold"
        case .heading: "text-xl font-semibold"
        case .body: "text-base"
        case .lead: "text-lg text-mutedForeground"
        case .small: "text-sm font-medium"
        case .muted: "text-sm text-mutedForeground"
        case .code: "cn-mono text-sm bg-muted rounded-sm px-1"
        }
    }
}
public struct CNTypography: View {
    private let text: LocalizedStringKey
    private let style: CNTypographyStyle
    private let classes: TWClasses
    public init(_ text: LocalizedStringKey, style: CNTypographyStyle = .body, classes: TWClasses = "") {
        self.text = text; self.style = style; self.classes = classes
    }
    public var body: some View {
        Text(text).tw(cn("typography", style.classes, classes)).cnTextUtilities()
            .accessibilityAddTraits(style == .largeTitle || style == .title || style == .heading ? .isHeader : [])
    }
}
public struct CNSeparator: View {
    private let axis: Axis
    private let classes: TWClasses
    public init(_ classes: TWClasses = "", axis: Axis = .horizontal) { self.classes = classes; self.axis = axis }
    public var body: some View {
        Divider().hidden().frame(maxHeight: axis == .vertical ? .infinity : nil)
            .tw(cn("separator", axis == .horizontal ? "h-[1] w-full" : "w-[1]", classes)).accessibilityHidden(true)
    }
}
public struct CNAspectRatio<Content: View>: View {
    private let ratio: CGFloat
    private let classes: TWClasses
    private let content: Content
    public init(_ ratio: CGFloat = 16 / 9, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        precondition(ratio.isFinite && ratio > 0, "Aspect ratio must be finite and positive.")
        self.ratio = ratio; self.classes = classes; self.content = content()
    }
    public var body: some View {
        GeometryReader { proxy in content.frame(width: proxy.size.width, height: proxy.size.height) }
            .tw(cn("cn-aspect-[\(ratio)]", classes)).cnAspectUtilities()
    }
}
public struct CNDirection<Content: View>: View {
    private let direction: LayoutDirection
    private let content: Content
    public init(_ direction: LayoutDirection, @ViewBuilder content: () -> Content) {
        self.direction = direction; self.content = content()
    }
    public var body: some View { content.environment(\.layoutDirection, direction) }
}
public struct CNAvatar<Fallback: View>: View {
    private let url: URL?
    private let accessibilityLabel: String
    private let classes: TWClasses
    private let fallback: Fallback
    public init(url: URL? = nil, accessibilityLabel: String, classes: TWClasses = "", @ViewBuilder fallback: () -> Fallback) {
        self.url = url; self.accessibilityLabel = accessibilityLabel; self.classes = classes; self.fallback = fallback()
    }
    public var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image { image.resizable().tw("cn-avatar-image w-full") }
            else { fallback }
        }.tw(cn("avatar", classes)).cnAvatarUtilities().accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel)
    }
}
