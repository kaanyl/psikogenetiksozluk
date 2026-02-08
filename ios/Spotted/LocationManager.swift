import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D? = nil
    @Published var locationToken = UUID()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String? = nil

    private let manager: CLLocationManager

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestWhenInUse() {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            requestLocation()
            return
        }
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .denied, .restricted:
            errorMessage = "Konum izni reddedildi."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first?.coordinate {
            location = loc
            locationToken = UUID()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if location == nil {
            location = CLLocationCoordinate2D(latitude: 41.0369, longitude: 28.9851)
            locationToken = UUID()
            errorMessage = "Konum alınamadı. Varsayılan konum (Taksim) kullanılıyor."
            return
        }
        errorMessage = error.localizedDescription
    }
}
