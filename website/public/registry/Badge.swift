import SwiftUI
import SwiftCN

public enum CNBadgeVariant: Sendable {
    case primary, secondary, outline, destructive
    public var classes: TWClasses {
        switch self {
        case .primary: ""
        case .secondary: "bg-muted text-foreground"
        case .outline: "bg-[\(Color.clear)] text-foreground border"
        case .destructive: "bg-destructive text-onDestructive"
        }
    }
}
public struct CNBadge<Content: View>: View {
    private let variant: CNBadgeVariant
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", variant: CNBadgeVariant = .primary, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.variant = variant; self.content = content()
    }
    public init(_ title: LocalizedStringKey, variant: CNBadgeVariant = .primary, classes: TWClasses = "") where Content == Text {
        self.classes = classes; self.variant = variant; content = Text(title)
    }
    public var body: some View { content.tw(cn("badge", variant.classes, classes)) }
}
