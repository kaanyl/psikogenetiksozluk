import Foundation

actor MockServer {
    static let shared = MockServer()

    private var posts: [Post]
    private var commentsByPostId: [UUID: [Comment]]
    private let ad: AdCard = MockData.ad

    private init() {
        self.posts = MockData.posts
        self.commentsByPostId = [:]
    }

    func getFeed() async -> FeedResponse {
        FeedResponse(posts: posts, ad: ad, nextCursor: nil)
    }

    func getPostDetail(postId: UUID) async -> PostDetailResponse {
        let post = posts.first { $0.id == postId } ?? posts.first!
        let comments = commentsByPostId[postId] ?? []
        return PostDetailResponse(post: post, comments: comments, nextCursor: nil)
    }

    func createPost(_ request: PostCreateRequest) async {
        let poll: Poll? = request.poll.map { p in
            Poll(
                id: UUID(),
                question: p.question,
                options: p.options.map { PollOption(id: UUID(), text: $0, votePercent: 0) }
            )
        }
        let post = Post(
            id: UUID(),
            type: request.type,
            text: request.text,
            photoURL: request.photoURL.flatMap { URL(string: $0) },
            linkURL: request.linkURL.flatMap { URL(string: $0) },
            poll: poll,
            score: 0,
            commentCount: 0,
            createdAt: Date(),
            userVote: 0
        )
        posts.insert(post, at: 0)
    }

    func vote(postId: UUID, value: Int) async {
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
        let post = posts[idx]
        let oldVote = post.userVote
        let newVote = value
        let delta = newVote - oldVote
        let updated = Post(
            id: post.id,
            type: post.type,
            text: post.text,
            photoURL: post.photoURL,
            linkURL: post.linkURL,
            poll: post.poll,
            score: post.score + delta,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
            userVote: newVote
        )
        posts[idx] = updated
    }

    func createComment(postId: UUID, text: String) async {
        var list = commentsByPostId[postId] ?? []
        let c = Comment(id: UUID(), nickname: "local", text: text, createdAt: Date())
        list.insert(c, at: 0)
        commentsByPostId[postId] = list

        if let idx = posts.firstIndex(where: { $0.id == postId }) {
            let post = posts[idx]
            let updated = Post(
                id: post.id,
                type: post.type,
                text: post.text,
                photoURL: post.photoURL,
                linkURL: post.linkURL,
                poll: post.poll,
                score: post.score,
                commentCount: post.commentCount + 1,
                createdAt: post.createdAt,
                userVote: post.userVote
            )
            posts[idx] = updated
        }
    }

    func uploadPhoto() async -> String {
        "local://photo"
    }

    func requestOTP() async -> OTPRequestResponse {
        OTPRequestResponse(requestId: UUID().uuidString)
    }

    func verifyOTP() async -> OTPVerifyResponse {
        OTPVerifyResponse(accessToken: "local-token", userId: UUID().uuidString, needsNickname: false)
    }

    func updateNickname() async {
        // no-op
    }
}
