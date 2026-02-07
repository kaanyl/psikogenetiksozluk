import Foundation
import CoreLocation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var ad: AdCard? = nil
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil

    private var nextCursor: String? = nil

    init(posts: [Post] = [], ad: AdCard? = nil) {
        self.posts = posts
        self.ad = ad
    }

    func loadFeed(location: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.getFeed(
                lat: location.latitude,
                lng: location.longitude,
                radiusKm: 1
            )
            posts = response.posts.sorted { $0.score > $1.score }
            ad = response.ad
            nextCursor = response.nextCursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore(location: CLLocationCoordinate2D) async {
        guard !isLoadingMore, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await APIClient.shared.getFeed(
                lat: location.latitude,
                lng: location.longitude,
                radiusKm: 1,
                cursor: cursor
            )
            posts.append(contentsOf: response.posts)
            posts.sort { $0.score > $1.score }
            nextCursor = response.nextCursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var items: [FeedItem] {
        guard let ad else {
            return posts.map { FeedItem(id: $0.id.uuidString, kind: .post($0)) }
        }

        var result: [FeedItem] = []
        for (index, post) in posts.enumerated() {
            result.append(FeedItem(id: post.id.uuidString, kind: .post(post)))
            if AppConfig.sponsorEvery > 0, (index + 1) % AppConfig.sponsorEvery == 0 {
                let sponsorId = "\(ad.id.uuidString)-\(index)"
                result.append(FeedItem(id: sponsorId, kind: .sponsor(ad, index: index)))
            }
        }
        if posts.isEmpty {
            let sponsorId = "\(ad.id.uuidString)-empty"
            result.append(FeedItem(id: sponsorId, kind: .sponsor(ad, index: -1)))
        }
        return result
    }

    struct VoteUpdate {
        let postId: UUID
        let oldVote: Int
        let newVote: Int
        let delta: Int
    }

    func applyVote(postId: UUID, target: Int) -> VoteUpdate? {
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return nil }
        let post = posts[idx]
        let oldVote = post.userVote
        let newVote = (oldVote == target) ? 0 : target
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
        return VoteUpdate(postId: postId, oldVote: oldVote, newVote: newVote, delta: delta)
    }

    func rollbackVote(_ update: VoteUpdate) {
        guard let idx = posts.firstIndex(where: { $0.id == update.postId }) else { return }
        let post = posts[idx]
        let updated = Post(
            id: post.id,
            type: post.type,
            text: post.text,
            photoURL: post.photoURL,
            linkURL: post.linkURL,
            poll: post.poll,
            score: post.score - update.delta,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
            userVote: update.oldVote
        )
        posts[idx] = updated
    }
}
