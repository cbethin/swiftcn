import SwiftUI
import SwiftCN

struct KbdExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Search"); CNKbd("⌘ K") }

        }
    }
}
