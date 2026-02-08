import SwiftUI

struct ComponentPreviews: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TopBarView(title: "Kadıköy · 3 km")
                PostCardView(post: MockData.posts[0])
                PostCardView(post: MockData.posts[1])
                PostCardView(post: MockData.posts[2])
                PostCardView(post: MockData.posts[3])
                SponsorCardView(ad: MockData.ad)
                EventPingCard(ping: MockData.eventPings[0])
                PollLeagueView(polls: MockData.posts)
                DailyQuestionCard(question: DailyQuestions.today) { }
                LocalDealCard(deal: MockData.localDeals[0])
                RandomPostCard { }
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
