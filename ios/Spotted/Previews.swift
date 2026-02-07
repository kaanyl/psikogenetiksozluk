import SwiftUI

struct ComponentPreviews: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TopBar()
                PostCardView(post: MockData.posts[0])
                PostCardView(post: MockData.posts[1])
                PostCardView(post: MockData.posts[2])
                PostCardView(post: MockData.posts[3])
                SponsorCardView(ad: MockData.ad)
                FloatingActionButton { }
            }
            .padding(16)
        }
        .background(Color(white: 0.96))
    }
}

#Preview("Components") {
    ComponentPreviews()
}
