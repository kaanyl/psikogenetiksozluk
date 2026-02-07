import Foundation

enum MockData {
    static let ad = AdCard(
        id: UUID(),
        title: "Kafe X %20 indirim",
        imageURL: nil,
        linkURL: URL(string: "https://example.com")!
    )

    static let poll = Poll(
        id: UUID(),
        question: "İstanbul'da en iyi manzara nerede?",
        options: [
            PollOption(id: UUID(), text: "Galata", votePercent: 45),
            PollOption(id: UUID(), text: "Üsküdar", votePercent: 30),
            PollOption(id: UUID(), text: "Karaköy", votePercent: 25)
        ]
    )

    static let posts: [Post] = [
        Post(
            id: UUID(),
            type: .text,
            text: "Kadıköy'de bugün trafik çok yoğun.",
            photoURL: nil,
            linkURL: nil,
            poll: nil,
            score: 128,
            commentCount: 14,
            createdAt: Date().addingTimeInterval(-3600),
            userVote: 1
        ),
        Post(
            id: UUID(),
            type: .photo,
            text: "Gün batımı 🔥",
            photoURL: nil,
            linkURL: nil,
            poll: nil,
            score: 79,
            commentCount: 9,
            createdAt: Date().addingTimeInterval(-7200),
            userVote: 0
        ),
        Post(
            id: UUID(),
            type: .link,
            text: "Boğaz hattı duyurusu",
            photoURL: nil,
            linkURL: URL(string: "https://example.com")!,
            poll: nil,
            score: 42,
            commentCount: 4,
            createdAt: Date().addingTimeInterval(-900),
            userVote: -1
        ),
        Post(
            id: UUID(),
            type: .poll,
            text: nil,
            photoURL: nil,
            linkURL: nil,
            poll: poll,
            score: 61,
            commentCount: 8,
            createdAt: Date().addingTimeInterval(-3000),
            userVote: 0
        )
    ]

    static let comments: [Comment] = [
        Comment(id: UUID(), nickname: "marti", text: "Katılıyorum.", createdAt: Date().addingTimeInterval(-300)),
        Comment(id: UUID(), nickname: "bosphorus", text: "Bence de.", createdAt: Date().addingTimeInterval(-1200))
    ]
}
