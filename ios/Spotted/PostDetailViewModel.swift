import Foundation

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil
    @Published var isReady: Bool = false

    private var nextCursor: String? = nil

    init(post: Post) {
        self.post = post
    }

    func loadInitial() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.getPostDetail(postId: post.id)
            post = response.post
            comments = response.comments
            nextCursor = response.nextCursor
            isReady = true
            errorMessage = nil
        } catch {
            if case let APIError.http(_, code, _) = error, code == "not_found" {
                // Post not found on server; keep the feed copy and show nothing.
                isReady = false
                errorMessage = "Post sunucuda bulunamadı."
                return
            }
            isReady = false
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoadingMore, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await APIClient.shared.getPostDetail(postId: post.id, cursor: cursor)
            comments.append(contentsOf: response.comments)
            nextCursor = response.nextCursor
        } catch {
            if case let APIError.http(_, code, _) = error, code == "not_found" {
                errorMessage = nil
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    struct VoteUpdate {
        let oldVote: Int
        let newVote: Int
        let delta: Int
    }

    func applyVote(target: Int) -> VoteUpdate {
        let oldVote = post.userVote
        let newVote = (oldVote == target) ? 0 : target
        let delta = newVote - oldVote
        post = Post(
            id: post.id,
            type: post.type,
            text: post.text,
            photoURL: post.photoURL,
            linkURL: post.linkURL,
            poll: post.poll,
            score: post.score + delta,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
            userVote: newVote,
            expiresAt: post.expiresAt
        )
        return VoteUpdate(oldVote: oldVote, newVote: newVote, delta: delta)
    }

    func rollbackVote(_ update: VoteUpdate) {
        post = Post(
            id: post.id,
            type: post.type,
            text: post.text,
            photoURL: post.photoURL,
            linkURL: post.linkURL,
            poll: post.poll,
            score: post.score - update.delta,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
            userVote: update.oldVote,
            expiresAt: post.expiresAt
        )
    }

    func addOptimisticComment(text: String) -> UUID {
        let tempId = UUID()
        comments.insert(Comment(id: tempId, nickname: nil, text: text, createdAt: Date()), at: 0)
        post = Post(
            id: post.id,
            type: post.type,
            text: post.text,
            photoURL: post.photoURL,
            linkURL: post.linkURL,
            poll: post.poll,
            score: post.score,
            commentCount: post.commentCount + 1,
            createdAt: post.createdAt,
            userVote: post.userVote,
            expiresAt: post.expiresAt
        )
        return tempId
    }

    func removeOptimisticComment(id: UUID) {
        comments.removeAll { $0.id == id }
        post = Post(
            id: post.id,
            type: post.type,
            text: post.text,
            photoURL: post.photoURL,
            linkURL: post.linkURL,
            poll: post.poll,
            score: post.score,
            commentCount: max(0, post.commentCount - 1),
            createdAt: post.createdAt,
            userVote: post.userVote,
            expiresAt: post.expiresAt
        )
    }
}
