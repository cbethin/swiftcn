#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Adaptive action bounds", .serialized)
@MainActor
struct AdaptiveActionLayoutTests {
    @Test(arguments: [CGFloat(320), 393, 720])
    func intrinsicActionsStayInsideTheirMeasuredGroup(width: CGFloat) throws {
        let probes = ActionBoundsProbes()
        let host = NSHostingView(rootView: ActionBoundsFixture(probes: probes).frame(width: width))
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        host.layoutSubtreeIfNeeded()
        let group = try #require(probes.views["group"])
        for id in ["design", "mobile", "archive"] {
            let view = try #require(probes.views[id])
            let frame = view.convert(view.bounds, to: group)
            #expect(group.bounds.insetBy(dx: -0.5, dy: -0.5).contains(frame),
                    "Action \(id) must fit the measured group at width \(width).")
        }
    }
}

@MainActor private final class ActionBoundsProbes {
    var views: [String: NSView] = [:]
}

private struct ActionBoundsFixture: View {
    let probes: ActionBoundsProbes
    @State private var selection: Set<String> = []
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"),
                           CNOption("archive", title: "Archived", isDisabled: true)]
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Toggle Group").tw("text-xl font-semibold")
            CNToggleGroup(options, selection: $selection) { option in
                HStack(spacing: 6) {
                    Text(option.title)
                    if option.id == "design" { CNBadge("New") }
                }.background { ActionBoundsProbe(probes: probes, id: option.id) }
            }.background { ActionBoundsProbe(probes: probes, id: "group") }
        }.tw("p-5 w-full")
    }
}

private struct ActionBoundsProbe: NSViewRepresentable {
    let probes: ActionBoundsProbes
    let id: String
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        probes.views[id] = view
        return view
    }
    func updateNSView(_ view: NSView, context: Context) {}
}
#endif
