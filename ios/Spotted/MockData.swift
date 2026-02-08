import Foundation
import CoreLocation

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
            userVote: 1,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60)
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
            userVote: 0,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60)
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
            userVote: -1,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60)
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
            userVote: 0,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60)
        )
    ]

    static let comments: [Comment] = [
        Comment(id: UUID(), nickname: "marti", text: "Katılıyorum.", createdAt: Date().addingTimeInterval(-300)),
        Comment(id: UUID(), nickname: "bosphorus", text: "Bence de.", createdAt: Date().addingTimeInterval(-1200))
    ]

    static let heatPoints: [HeatPoint] = [
        HeatPoint(title: "Kadıköy", coordinate: .init(latitude: 40.9901, longitude: 29.0286), intensity: 0.6),
        HeatPoint(title: "Beşiktaş", coordinate: .init(latitude: 41.0430, longitude: 29.0094), intensity: 0.7),
        HeatPoint(title: "Taksim", coordinate: .init(latitude: 41.0369, longitude: 28.9850), intensity: 0.8),
        HeatPoint(title: "Üsküdar", coordinate: .init(latitude: 41.0226, longitude: 29.0122), intensity: 0.5)
    ]

    static let eventPings: [EventPing] = [
        EventPing(
            title: "Yoğun kalabalık",
            subtitle: "Moda sahilinde yoğunluk",
            coordinate: .init(latitude: 40.9852, longitude: 29.0294),
            distanceMeters: 650,
            createdAt: Date().addingTimeInterval(-600)
        ),
        EventPing(
            title: "Canlı müzik",
            subtitle: "Beşiktaş çarşı civarı",
            coordinate: .init(latitude: 41.0426, longitude: 29.0081),
            distanceMeters: 1400,
            createdAt: Date().addingTimeInterval(-1200)
        )
    ]

    static let localDeals: [LocalDeal] = [
        LocalDeal(
            title: "Yakında %20 indirim",
            subtitle: "2 sokak ötede kahve kampanyası",
            distanceMeters: 180,
            linkURL: URL(string: "https://example.com")!
        ),
        LocalDeal(
            title: "Happy hour",
            subtitle: "Taksim'de 1+1",
            distanceMeters: 520,
            linkURL: URL(string: "https://example.com")!
        )
    ]
}
