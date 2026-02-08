import SwiftUI

struct TopBarView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
}
