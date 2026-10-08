import SwiftUI
import Charts

/// Swift Charts keeps its scales, axes, marks, accessibility and selection APIs native.
/// Pass any ChartContent; style the shared surface with classes and the native marks in the builder.
public struct CNChart<Content: ChartContent>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ChartContentBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public var body: some View { Chart { content }.tw(cn("chart", classes)).cnControlUtilities() }
}
