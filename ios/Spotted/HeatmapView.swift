import SwiftUI
import MapKit

struct HeatmapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )

    let points: [HeatPoint]

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: points) { point in
            MapAnnotation(coordinate: point.coordinate) {
                Circle()
                    .fill(Color.red.opacity(point.intensity))
                    .frame(width: 40, height: 40)
                    .blur(radius: 6)
            }
        }
    }
}

struct HeatPoint: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let intensity: Double
}

#Preview {
    HeatmapView(points: MockData.heatPoints)
}
