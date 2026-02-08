import SwiftUI

struct PollLeagueView: View {
    let polls: [Post]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anket Ligi · Top 10")
                .font(.subheadline)

            ForEach(Array(polls.prefix(10).enumerated()), id: \.element.id) { index, post in
                HStack {
                    Text("#\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 28, alignment: .leading)
                    Text(post.poll?.question ?? "Anket")
                        .font(.footnote)
                        .lineLimit(1)
                    Spacer()
                    Text("\(post.score)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(16)
    }
}
