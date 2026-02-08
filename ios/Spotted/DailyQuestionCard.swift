import SwiftUI

struct DailyQuestionCard: View {
    let question: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Günün sorusu")
                .font(.caption)
                .foregroundColor(.gray)
            Text(question)
                .font(.subheadline)
                .bold()
            Button("Cevapla") { action() }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(16)
    }
}
