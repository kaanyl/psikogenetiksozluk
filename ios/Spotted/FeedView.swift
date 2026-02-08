import SwiftUI
import CoreLocation

@MainActor
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showCreate = false
    @State private var didRequestLocation = false
    @State private var radiusKm: Double = 1
    @State private var mode: FeedMode = .nearby
    @State private var showEventPings = true
    @State private var randomPost: Post? = nil
    @State private var showDailyQuestion = true
    @State private var selectedNeighborhood: String? = nil
    @State private var autoNeighborhood: String = "Konum yok"
    private let fallbackLocation = CLLocationCoordinate2D(latitude: 41.0369, longitude: 28.9851)

    enum FeedMode: String, CaseIterable {
        case nearby = "Akış"
        case pulse = "Pulse"
        case explore = "Keşif"
        case night = "Gece"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 12) {
                        TopBarView(title: "\(selectedNeighborhood ?? autoNeighborhood) · \(Int(radiusKm)) km")
                        Picker("", selection: $mode) {
                            ForEach(FeedMode.allCases, id: \.self) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 12) {
                            Text("Mikro‑kanal")
                                .font(.subheadline)
                            Spacer()
                            Menu {
                                Button("Otomatik (GPS)") {
                                    selectedNeighborhood = nil
                                    autoNeighborhood = Neighborhoods.nearestName(to: locationManager.location)
                                }
                                ForEach(Neighborhoods.areas, id: \.name) { area in
                                    Button(area.name) {
                                        selectedNeighborhood = area.name
                                    }
                                }
                            } label: {
                                Text(selectedNeighborhood ?? autoNeighborhood)
                            }
                        }
                        .padding(.horizontal, 4)

                        if mode == .explore {
                            HeatmapView(points: MockData.heatPoints)
                                .frame(height: 260)
                                .cornerRadius(16)

                            if showEventPings {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Yakındaki ping’ler")
                                            .font(.subheadline)
                                        Spacer()
                                        Button("Kapat") { showEventPings = false }
                                            .font(.caption)
                                    }
                                    ForEach(MockData.eventPings) { ping in
                                        EventPingCard(ping: ping)
                                    }
                                }
                            }

                            if !viewModel.topPollPosts.isEmpty {
                                PollLeagueView(polls: viewModel.topPollPosts)
                            }

                            if showDailyQuestion {
                                DailyQuestionCard(question: DailyQuestions.today) {
                                    showCreate = true
                                }
                            }

                            ForEach(MockData.localDeals) { deal in
                                LocalDealCard(deal: deal)
                            }

                            RandomPostCard {
                                if let post = viewModel.posts.randomElement() {
                                    randomPost = post
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Text("\(Int(radiusKm)) km")
                                .font(.subheadline)
                                .frame(width: 48, alignment: .leading)
                            Slider(value: $radiusKm, in: 1...10, step: 1)
                        }
                        .padding(.horizontal, 4)

                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 24)
                        }
                        Text("API: \(AppConfig.apiBaseURL.absoluteString)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        if let error = viewModel.errorMessage ?? locationManager.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.vertical, 8)
                        }
                        if !viewModel.isLoading && viewModel.posts.isEmpty {
                            VStack(spacing: 8) {
                                Text("Henüz gönderi yok.")
                                    .font(.headline)
                                Text("Yakınında bir şey yoksa ilk postu sen at.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                        }

                        if mode == .night {
                            Text("Gece akışı (00:00–05:00)")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        if mode == .pulse && viewModel.pulsePosts.isEmpty {
                            Text("Pulse boş. Son 15 dakikada hareket yok.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        ForEach(mode == .pulse ? pulseItems() : (mode == .explore ? [] : viewModel.items)) { item in
                            switch item.kind {
                            case .post(let post):
                                if mode == .night && !NightMode.isNight(post.createdAt) {
                                    EmptyView()
                                } else {
                                    NavigationLink(value: post) {
                                        PostCardView(post: post) { delta in
                                            Task {
                                                await vote(post: post, target: delta)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        loadMoreIfNeeded(currentPostId: post.id)
                                    }
                                }
                            case .sponsor(let ad, _):
                                SponsorCardView(ad: ad)
                            }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView().padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await refresh()
                }

                FloatingActionButton {
                    showCreate = true
                }
                .padding(16)
            }
            .background(Color(white: 0.96))
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .sheet(isPresented: $showCreate) {
                CreatePostView(
                    location: locationManager.location,
                    onOptimisticAdd: { _ in },
                    onOptimisticRemove: { _ in },
                    onOptimisticReplace: { _, _ in },
                    onDidSubmit: {
                        if let location = locationManager.location {
                            Task { await viewModel.loadFeed(location: location, radiusKm: radiusKm) }
                        }
                    }
                )
            }
            .sheet(item: $randomPost) { post in
                NavigationStack {
                    PostDetailView(post: post)
                }
            }
            .task {
                if !didRequestLocation {
                    didRequestLocation = true
                    locationManager.requestWhenInUse()
                }
                let initial = locationManager.location ?? fallbackLocation
                autoNeighborhood = Neighborhoods.nearestName(to: initial)
                await viewModel.loadFeed(location: initial, radiusKm: radiusKm)
            }
            .onChange(of: locationManager.locationToken) { _ in
                guard let location = locationManager.location else { return }
                autoNeighborhood = Neighborhoods.nearestName(to: location)
                Task {
                    await viewModel.loadFeed(location: location, radiusKm: radiusKm)
                }
            }
            .onChange(of: radiusKm) { _ in
                guard let location = locationManager.location else { return }
                Task { await viewModel.loadFeed(location: location, radiusKm: radiusKm) }
            }
        }
    }

    private func refresh() async {
        guard let location = locationManager.location else { return }
        await viewModel.loadFeed(location: location, radiusKm: radiusKm)
    }

    private func pulseItems() -> [FeedItem] {
        viewModel.pulsePosts.map { FeedItem(id: $0.id.uuidString, kind: .post($0)) }
    }

    private func loadMoreIfNeeded(currentPostId: UUID) {
        guard let lastId = viewModel.posts.last?.id else { return }
        guard currentPostId == lastId else { return }
        guard let location = locationManager.location else { return }
        Task { await viewModel.loadMore(location: location, radiusKm: radiusKm) }
    }

    private func vote(post: Post, target: Int) async {
        guard let update = viewModel.applyVote(postId: post.id, target: target) else { return }
        do {
            try await APIClient.shared.vote(postId: post.id, value: update.newVote)
        } catch {
            viewModel.rollbackVote(update)
        }
    }
}

#Preview {
    FeedView()
}
