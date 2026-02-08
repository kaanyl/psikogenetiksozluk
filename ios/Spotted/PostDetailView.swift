import SwiftUI

@MainActor
struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @State private var commentText: String = ""
    @State private var isSending = false

    init(post: Post) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    PostCardView(post: viewModel.post) { target in
                        Task { await vote(target: target) }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yorumlar (\(max(viewModel.post.commentCount, viewModel.comments.count)))")
                            .font(.headline)

                        if viewModel.isLoading && viewModel.comments.isEmpty {
                            ProgressView().padding(.vertical, 8)
                        }

                        if !viewModel.isLoading && viewModel.comments.isEmpty {
                            Text("Henüz yorum yok.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        ForEach(viewModel.comments) { c in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    if let name = c.nickname {
                                        Text("@\(name)").font(.caption).bold()
                                    }
                                    Text(DateFormatters.relativeString(from: c.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Text(c.text).font(.body)
                            }
                            .onAppear {
                                if c.id == viewModel.comments.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView().padding(.vertical, 8)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .padding(16)
            }

            VStack(spacing: 8) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red).font(.footnote)
                }
                HStack {
                    TextField("Yorum yaz...", text: $commentText)
                    Button("Gönder") {
                        Task { await submitComment() }
                    }
                    .disabled(isSending)
                }
            }
            .padding(12)
            .background(Color.white)
        }
        .background(Color(white: 0.96))
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadInitial() }
    }

    private func vote(target: Int) async {
        let update = viewModel.applyVote(target: target)
        do {
            try await APIClient.shared.vote(postId: viewModel.post.id, value: update.newVote)
        } catch {
            viewModel.rollbackVote(update)
        }
    }

    private func submitComment() async {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard viewModel.isReady else {
            viewModel.errorMessage = "Post sunucuda hazır değil. Lütfen yenileyip tekrar dene."
            return
        }

        isSending = true
        let tempId = viewModel.addOptimisticComment(text: trimmed)
        commentText = ""

        do {
            try await APIClient.shared.createComment(postId: viewModel.post.id, text: trimmed)
        } catch {
            viewModel.removeOptimisticComment(id: tempId)
            viewModel.errorMessage = error.localizedDescription
        }
        isSending = false
    }
}

#Preview {
    PostDetailView(post: MockData.posts[0])
}
