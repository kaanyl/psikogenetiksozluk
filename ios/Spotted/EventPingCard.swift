import SwiftUI

struct EventPingCard: View {
    let ping: EventPing

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "bolt.fill").foregroundColor(.orange))

            VStack(alignment: .leading, spacing: 4) {
                Text(ping.title).font(.subheadline).bold()
                Text(ping.subtitle).font(.caption).foregroundColor(.gray)
            }

            Spacer()

            Text("\(Int(ping.distanceMeters)) m")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(16)
    }
}
