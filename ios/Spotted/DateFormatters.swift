import Foundation

enum DateFormatters {
    static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    static func relativeString(from date: Date) -> String {
        relative.localizedString(for: date, relativeTo: Date())
    }
}
