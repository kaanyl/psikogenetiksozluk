import Foundation
import CoreLocation

struct LocalDeal: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let distanceMeters: Double
    let linkURL: URL
}
