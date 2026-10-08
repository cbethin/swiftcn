import SwiftUI
import SwiftCN

struct TypographyExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                CNTypography("Native by design", style: .title)
                CNTypography("A shared styling language for SwiftUI.", style: .lead)
                CNTypography("Keep your content, bindings, and gestures native.")
                CNTypography("import SwiftCN", style: .code)
            }

        }
    }
}
