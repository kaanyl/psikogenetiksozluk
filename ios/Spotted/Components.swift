import SwiftUI

struct TopBar: View {
    var body: some View {
        HStack {
            Text("İstanbul · 1 km")
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

struct VoteButton: View {
    let isUp: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isUp ? "arrow.up" : "arrow.down")
                .foregroundColor(isSelected ? (isUp ? .green : .red) : .gray)
        }
    }
}

struct SponsorCardView: View {
    let ad: AdCard

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 40, height: 40)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(ad.title).font(.subheadline).bold()
                Text("Sponsor").font(.caption).foregroundColor(.gray)
            }

            Spacer()

            Button("Git") { }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(16)
    }
}

struct PostCardView: View {
    let post: Post
    let onVote: (Int) -> Void

    init(post: Post, onVote: @escaping (Int) -> Void = { _ in }) {
        self.post = post
        self.onVote = onVote
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let text = post.text {
                Text(text).font(.body)
            }

            if post.type == .photo {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 180)
                    .cornerRadius(12)
            }

            if post.type == .link, let link = post.linkURL {
                Text(link.absoluteString)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            if let poll = post.poll {
                PollView(poll: poll)
            }

            HStack(spacing: 12) {
                VoteButton(isUp: true, isSelected: post.userVote == 1) {
                    onVote(1)
                }
                Text("\(post.score)").font(.subheadline)
                VoteButton(isUp: false, isSelected: post.userVote == -1) {
                    onVote(-1)
                }
                Spacer()
                Text("\(post.commentCount) yorum · \(DateFormatters.relativeString(from: post.createdAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}

struct PollView: View {
    let poll: Poll

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(poll.question).font(.subheadline).bold()
            ForEach(poll.options) { option in
                HStack {
                    Text(option.text).font(.footnote)
                    Spacer()
                    Text("\(option.votePercent)%").font(.footnote)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
        }
    }
}
