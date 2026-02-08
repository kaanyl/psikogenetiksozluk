import SwiftUI
import LinkPresentation

@MainActor
final class LinkPreviewModel: ObservableObject {
    @Published var metadata: LPLinkMetadata? = nil
    @Published var errorMessage: String? = nil

    private var cache: [URL: LPLinkMetadata] = [:]
    private var currentTask: Task<Void, Never>? = nil
    private var latestURL: URL? = nil

    func load(url: URL) {
        if let cached = cache[url] {
            metadata = cached
            errorMessage = nil
            return
        }

        latestURL = url
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard let self, !Task.isCancelled else { return }

            let provider = LPMetadataProvider()
            do {
                let meta = try await provider.startFetchingMetadata(for: url)
                guard self.latestURL == url else { return }
                self.cache[url] = meta
                self.metadata = meta
                self.errorMessage = nil
            } catch {
                guard self.latestURL == url else { return }
                self.errorMessage = error.localizedDescription
                self.metadata = nil
            }
        }
    }
}

struct LinkPreviewView: UIViewRepresentable {
    let metadata: LPLinkMetadata

    func makeUIView(context: Context) -> LPLinkView {
        LPLinkView(metadata: metadata)
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {
        uiView.metadata = metadata
    }
}
