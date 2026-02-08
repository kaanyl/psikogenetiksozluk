import Foundation

enum DailyQuestions {
    static let questions = [
        "Bugün İstanbul'da en iyi simit nerede?",
        "Şehirde bu hafta en keyifli yürüyüş rotası?",
        "Akşam için en iyi manzara nerede?"
    ]

    static var today: String {
        let day = Calendar.current.component(.day, from: Date())
        return questions[day % questions.count]
    }
}
