import Foundation

struct FeedResponse: Decodable {
    let posts: [Post]
    let ad: AdCard?
    let nextCursor: String?
}

struct PostDetailResponse: Decodable {
    let post: Post
    let comments: [Comment]
    let nextCursor: String?
}

struct CommentCreateRequest: Encodable {
    let text: String
}

struct VoteRequest: Encodable {
    let value: Int
}

struct PostCreateRequest: Encodable {
    let type: PostType
    let text: String?
    let photoURL: String?
    let linkURL: String?
    let poll: PollCreateRequest?
    let lat: Double
    let lng: Double
}

struct PollCreateRequest: Encodable {
    let question: String
    let options: [String]
}

struct MediaUploadResponse: Decodable {
    let url: String
}

struct ProfileUpdateRequest: Encodable {
    let nickname: String
}
