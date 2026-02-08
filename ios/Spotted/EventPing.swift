import Foundation
import CoreLocation

struct EventPing: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        coordinate: CLLocationCoordinate2D,
        distanceMeters: Double,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.distanceMeters = distanceMeters
        self.createdAt = createdAt
    }
}
