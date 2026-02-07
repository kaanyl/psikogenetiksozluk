import SwiftUI

@MainActor
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showCreate = false
    @State private var didRequestLocation = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 12) {
                        TopBar()
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 24)
                        }
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
                        ForEach(viewModel.items) { item in
                            switch item.kind {
                            case .post(let post):
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
                    onOptimisticAdd: { post in
                        viewModel.posts.insert(post, at: 0)
                    },
                    onOptimisticRemove: { id in
                        viewModel.posts.removeAll { $0.id == id }
                    },
                    onDidSubmit: {
                        if let location = locationManager.location {
                            Task { await viewModel.loadFeed(location: location) }
                        }
                    }
                )
            }
            .task {
                if !didRequestLocation {
                    didRequestLocation = true
                    locationManager.requestWhenInUse()
                }
            }
            .onChange(of: locationManager.location) { location in
                guard let location else { return }
                Task {
                    await viewModel.loadFeed(location: location)
                }
            }
        }
    }

    private func refresh() async {
        guard let location = locationManager.location else { return }
        await viewModel.loadFeed(location: location)
    }

    private func loadMoreIfNeeded(currentPostId: UUID) {
        guard let lastId = viewModel.posts.last?.id else { return }
        guard currentPostId == lastId else { return }
        guard let location = locationManager.location else { return }
        Task { await viewModel.loadMore(location: location) }
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
