import SwiftUI

public enum CNMarkerVariant: Sendable { case inline, bordered, separator }
/// A conversation status or labeled separator. Wrap in a native Link or Button for actions.
public struct CNMarker<Content: View>: View {
    private let variant: CNMarkerVariant
    private let classes: TWClasses
    private let content: Content
    public init(variant: CNMarkerVariant = .inline, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.variant = variant; self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, variant: CNMarkerVariant = .inline, classes: TWClasses = "") where Content == Text {
        self.init(variant: variant, classes: classes) { Text(title) }
    }
    public var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                if variant == .separator { CNSeparator() }
                content
                if variant == .separator { CNSeparator() }
            }
            if variant == .bordered { CNSeparator() }
        }.tw(cn("marker", classes))
    }
}
public struct CNMarkerIcon<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { content.accessibilityHidden(true) }
}
