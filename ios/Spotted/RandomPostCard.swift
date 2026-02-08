import SwiftUI

struct RandomPostCard: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "shuffle").foregroundColor(.purple))

            VStack(alignment: .leading, spacing: 4) {
                Text("Rastgele post")
                    .font(.subheadline)
                    .bold()
                Text("Sana bir şey göstereyim")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button("Git") { action() }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(16)
    }
}
