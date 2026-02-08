import SwiftUI

struct LocalDealCard: View {
    let deal: LocalDeal

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.25))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "tag.fill").foregroundColor(.orange))

            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title).font(.subheadline).bold()
                Text(deal.subtitle).font(.caption).foregroundColor(.gray)
            }

            Spacer()

            Text("\(Int(deal.distanceMeters)) m")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.yellow.opacity(0.12))
        .cornerRadius(16)
    }
}
