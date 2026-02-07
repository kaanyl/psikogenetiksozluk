import Foundation

struct FeedItem: Identifiable, Hashable {
    enum Kind: Hashable {
        case post(Post)
        case sponsor(AdCard, index: Int)
    }

    let id: String
    let kind: Kind
}
