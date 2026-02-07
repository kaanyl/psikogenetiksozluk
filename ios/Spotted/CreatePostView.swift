import SwiftUI
import PhotosUI
import CoreLocation
import UIKit

struct CreatePostView: View {
    @State private var selectedType: PostType = .text
    @State private var content: String = ""
    @State private var linkURL: String = ""
    @State private var pollQuestion: String = ""
    @State private var pollOptions: [String] = ["", ""]
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @StateObject private var linkPreview = LinkPreviewModel()
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss

    let location: CLLocationCoordinate2D?
    let onOptimisticAdd: (Post) -> Void
    let onOptimisticRemove: (UUID) -> Void
    let onDidSubmit: () -> Void

    init(
        location: CLLocationCoordinate2D?,
        onOptimisticAdd: @escaping (Post) -> Void = { _ in },
        onOptimisticRemove: @escaping (UUID) -> Void = { _ in },
        onDidSubmit: @escaping () -> Void = {}
    ) {
        self.location = location
        self.onOptimisticAdd = onOptimisticAdd
        self.onOptimisticRemove = onOptimisticRemove
        self.onDidSubmit = onDidSubmit
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $selectedType) {
                Text("Text").tag(PostType.text)
                Text("Photo").tag(PostType.photo)
                Text("Link").tag(PostType.link)
                Text("Poll").tag(PostType.poll)
            }
            .pickerStyle(SegmentedPickerStyle())

            if selectedType == .text {
                TextEditor(text: $content)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
            }

            if selectedType == .photo {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 8) {
                        if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "photo")
                            Text("Fotoğraf Seç")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                }
                .onChange(of: selectedPhotoItem) { item in
                    Task {
                        guard let item else { return }
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                        }
                    }
                }
            }

            if selectedType == .link {
                TextField("Link URL", text: $linkURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                TextEditor(text: $content)
                    .frame(height: 140)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                if let metadata = linkPreview.metadata {
                    LinkPreviewView(metadata: metadata)
                        .frame(height: 120)
                        .cornerRadius(12)
                }
                if let error = linkPreview.errorMessage {
                    Text(error).font(.footnote).foregroundColor(.red)
                }
            }

            if selectedType == .poll {
                TextField("Soru", text: $pollQuestion)
                    .textFieldStyle(.roundedBorder)
                ForEach(pollOptions.indices, id: \.self) { idx in
                    TextField("Seçenek \(idx + 1)", text: $pollOptions[idx])
                        .textFieldStyle(.roundedBorder)
                }
                Button("Seçenek Ekle") {
                    if pollOptions.count < 4 { pollOptions.append("") }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button("Gönder") {
                Task { await submit() }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isSubmitting)

            Spacer()
        }
        .padding(16)
        .background(Color(white: 0.96))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Kapat") { dismiss() }
            }
        }
        .onChange(of: linkURL) { newValue in
            guard let url = URL(string: newValue), newValue.hasPrefix("http") else {
                linkPreview.metadata = nil
                return
            }
            linkPreview.load(url: url)
        }
    }

    private func submit() async {
        errorMessage = nil
        guard let location else {
            errorMessage = "Konum bulunamadı."
            return
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        switch selectedType {
        case .text:
            guard !trimmed.isEmpty else {
                errorMessage = "Metin boş olamaz."
                return
            }
        case .photo:
            guard selectedPhotoData != nil else {
                errorMessage = "Fotoğraf seçmelisin."
                return
            }
        case .link:
            guard let _ = URL(string: linkURL), linkURL.hasPrefix("http") else {
                errorMessage = "Geçerli bir link gir."
                return
            }
        case .poll:
            let options = pollOptions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            guard !pollQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Anket sorusu boş olamaz."
                return
            }
            guard options.count >= 2 else {
                errorMessage = "En az 2 seçenek gerekli."
                return
            }
        }

        isSubmitting = true
        let tempId = UUID()
        onOptimisticAdd(makeOptimisticPost(id: tempId))
        defer { isSubmitting = false }

        do {
            var photoURL: String? = nil
            if selectedType == .photo, let data = selectedPhotoData {
                photoURL = try await APIClient.shared.uploadPhoto(data: data)
            }

            let request = PostCreateRequest(
                type: selectedType,
                text: selectedType == .text || selectedType == .link ? trimmed : nil,
                photoURL: photoURL,
                linkURL: selectedType == .link ? linkURL : nil,
                poll: selectedType == .poll ? PollCreateRequest(
                    question: pollQuestion,
                    options: pollOptions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                ) : nil,
                lat: location.latitude,
                lng: location.longitude
            )

            try await APIClient.shared.createPost(request)
            onDidSubmit()
            dismiss()
        } catch {
            onOptimisticRemove(tempId)
            errorMessage = error.localizedDescription
        }
    }

    private func makeOptimisticPost(id: UUID) -> Post {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let poll: Poll? = selectedType == .poll ? Poll(
            id: UUID(),
            question: pollQuestion,
            options: pollOptions.map { text in
                PollOption(id: UUID(), text: text, votePercent: 0)
            }
        ) : nil

        return Post(
            id: id,
            type: selectedType,
            text: selectedType == .text || selectedType == .link ? trimmed : (selectedType == .poll ? nil : trimmed),
            photoURL: nil,
            linkURL: selectedType == .link ? URL(string: linkURL) : nil,
            poll: poll,
            score: 0,
            commentCount: 0,
            createdAt: Date(),
            userVote: 0
        )
    }
}

#Preview {
    CreatePostView(location: nil)
}
