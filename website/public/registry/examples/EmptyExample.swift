import SwiftUI
import SwiftCN

struct EmptyExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNEmpty {
                Image(systemName: "tray").tw("text-3xl").accessibilityHidden(true)
                CNEmptyTitle("No projects yet")
                CNEmptyDescription("Create your first project to get started.")
                CNEmptyContent { CNButton("Create project", action: {}) }
            }

        }
    }
}
