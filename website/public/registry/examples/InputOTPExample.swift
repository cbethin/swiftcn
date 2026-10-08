import SwiftUI
import SwiftCN

struct InputOTPExample: View {
    @State private var code = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNInputOTP(code: $code)

        }
    }
}
