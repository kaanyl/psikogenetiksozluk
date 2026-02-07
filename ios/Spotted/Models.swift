import Foundation

enum PostType: String, Codable {
    case text, photo, link, poll
}

struct Post: Identifiable, Codable, Hashable {
    let id: UUID
    let type: PostType
    let text: String?
    let photoURL: URL?
    let linkURL: URL?
    let poll: Poll?
    let score: Int
    let commentCount: Int
    let createdAt: Date
    let userVote: Int

    enum CodingKeys: String, CodingKey {
        case id, type, text, photoURL, linkURL, poll, score, commentCount, createdAt, userVote
    }

    init(
        id: UUID,
        type: PostType,
        text: String?,
        photoURL: URL?,
        linkURL: URL?,
        poll: Poll?,
        score: Int,
        commentCount: Int,
        createdAt: Date,
        userVote: Int
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.photoURL = photoURL
        self.linkURL = linkURL
        self.poll = poll
        self.score = score
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.userVote = userVote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(PostType.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        photoURL = try container.decodeIfPresent(URL.self, forKey: .photoURL)
        linkURL = try container.decodeIfPresent(URL.self, forKey: .linkURL)
        poll = try container.decodeIfPresent(Poll.self, forKey: .poll)
        score = try container.decode(Int.self, forKey: .score)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        userVote = try container.decodeIfPresent(Int.self, forKey: .userVote) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encodeIfPresent(linkURL, forKey: .linkURL)
        try container.encodeIfPresent(poll, forKey: .poll)
        try container.encode(score, forKey: .score)
        try container.encode(commentCount, forKey: .commentCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(userVote, forKey: .userVote)
    }
}

struct Poll: Identifiable, Codable, Hashable {
    let id: UUID
    let question: String
    let options: [PollOption]
}

struct PollOption: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let votePercent: Int
}

struct Comment: Identifiable, Codable {
    let id: UUID
    let nickname: String?
    let text: String
    let createdAt: Date
}

struct AdCard: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let imageURL: URL?
    let linkURL: URL
}
