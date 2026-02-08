import Foundation
import CoreLocation

enum Neighborhoods {
    static let areas: [(name: String, coordinate: CLLocationCoordinate2D)] = [
        ("Kadıköy", .init(latitude: 40.9901, longitude: 29.0286)),
        ("Beşiktaş", .init(latitude: 41.0430, longitude: 29.0094)),
        ("Taksim", .init(latitude: 41.0369, longitude: 28.9850)),
        ("Üsküdar", .init(latitude: 41.0226, longitude: 29.0122)),
        ("Karaköy", .init(latitude: 41.0256, longitude: 28.9744))
    ]

    static func nearestName(to coord: CLLocationCoordinate2D?) -> String {
        guard let coord else { return "İstanbul" }
        let current = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        var best = (name: "İstanbul", distance: CLLocationDistance.greatestFiniteMagnitude)
        for area in areas {
            let d = current.distance(from: CLLocation(latitude: area.coordinate.latitude, longitude: area.coordinate.longitude))
            if d < best.distance {
                best = (area.name, d)
            }
        }
        return best.name
    }
}
