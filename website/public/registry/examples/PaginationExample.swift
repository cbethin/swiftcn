import SwiftUI
import SwiftCN

struct PaginationExample: View {
    @State private var page = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNPagination(page: $page, pageCount: 20)

        }
    }
}
