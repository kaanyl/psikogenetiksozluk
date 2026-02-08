import Foundation

enum NightMode {
    static func isNight(_ date: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 0 && hour < 5
    }
}
