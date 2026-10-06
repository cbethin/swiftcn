import SwiftUI
import SwiftCN

struct DirectionExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNDirection(.rightToLeft) {
                HStack { Image(systemName: "arrow.forward"); Text("Direction follows the environment.") }.tw("p-4 bg-accent rounded-lg")
            }

        }
    }
}
