import MapKit
import SwiftUI

// MARK: Annotation model

final class BikePointAnnotation: NSObject, MKAnnotation {
    let bikePoint: BikePoint

    var coordinate: CLLocationCoordinate2D { bikePoint.coordinate }
    var title: String? { bikePoint.commonName }

    init(bikePoint: BikePoint) {
        self.bikePoint = bikePoint
    }
}

// MARK: Annotation view

final class BikePointAnnotationView: MKAnnotationView {
    private var hostingVC: UIHostingController<AnyView>?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        frame = CGRect(x: 0, y: 0, width: 50, height: 56)
        // Anchor bottom center of the view on the coordinate
        centerOffset = CGPoint(x: 0, y: -28)
        isEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(bikePoint: BikePoint, isSelected: Bool) {
        let marker = AnyView(BikePointMarker(bikePoint: bikePoint, isSelected: isSelected))
        if let vc = hostingVC {
            vc.rootView = marker
        } else {
            let vc = UIHostingController(rootView: marker)
            vc.view.backgroundColor = .clear
            vc.view.frame = bounds
            addSubview(vc.view)
            hostingVC = vc
        }
        isAccessibilityElement = true
        accessibilityLabel = String(format: NSLocalizedString("a11y_bikes_available_format", bundle: .localized, comment: ""), bikePoint.commonName, bikePoint.nbBikes ?? 0)
    }
}

// MARK: OfflineMapView

/// Map view using bundled OSM tiles, bike point annotations, and optional destination pin.
struct OfflineMapView: UIViewRepresentable {
    let initialCenter: CLLocationCoordinate2D
    @Binding var cameraPosition: MapCameraPosition
    @Binding var mapCameraCenter: CLLocationCoordinate2D?
    let filteredBikePoints: [BikePoint]
    @Binding var selectedBikePoint: BikePoint?
    let destinationCoordinate: CLLocationCoordinate2D?
    let isCompact: Bool
    let onBikePointTap: (BikePoint) -> Void
    let onMapTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView

        // OSM land beige shown outside tile coverage
        mapView.backgroundColor = UIColor(
            red: 237 / 255, green: 232 / 255, blue: 222 / 255, alpha: 1)
        mapView.showsUserLocation = true
        mapView.showsScale = true

        // Add offline tile overlay as base layer
        let overlay = LocalTileOverlay()
        mapView.addOverlay(overlay, level: .aboveLabels)

        // Set initial camera — mark as programmatic so regionDidChangeAnimated
        // doesn't immediately overwrite mapCameraCenter while bikePoints are loading.
        let region =
            cameraPosition.region
            ?? MKCoordinateRegion(
                center: initialCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        context.coordinator.isSettingRegion = true
        mapView.setRegion(region, animated: false)
        context.coordinator.lastAppliedPosition = cameraPosition

        // Constrain zoom-out so the user can't pan past the level where
        // z=12 tiles are displayed. camera.altitude is unavailable before
        // the view enters the window, so we use a fixed value derived from
        // the standard MapKit altitude scale (each zoom step ≈ 2× altitude):
        //   z=14 ≈ 18 000 m  →  z=13 ≈ 36 000 m  →  z=12 ≈ 72 000 m
        // 75 000 m sits just past z=12, keeping the full city tile visible
        // while preventing the blank-background overshoot.
        mapView.setCameraZoomRange(
            MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 75_000),
            animated: false
        )

        // Map tap gesture to deselect
        let tap = UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tap.delegate = context.coordinator
        mapView.addGestureRecognizer(tap)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator

        // Apply camera if the binding changed externally
        if cameraPosition != coordinator.lastAppliedPosition {
            coordinator.lastAppliedPosition = cameraPosition
            if let region = cameraPosition.region {
                coordinator.isSettingRegion = true
                mapView.setRegion(region, animated: true)
            }
        }

        // Sync bike point annotations
        let existingAnnotations = mapView.annotations
            .compactMap { $0 as? BikePointAnnotation }
        let existingIDs = Set(existingAnnotations.map { $0.bikePoint.id })
        let desiredIDs = Set(filteredBikePoints.map { $0.id })

        // Remove stale
        let toRemove = existingAnnotations.filter { !desiredIDs.contains($0.bikePoint.id) }
        mapView.removeAnnotations(toRemove)

        // Add new
        let toAdd =
            filteredBikePoints
            .filter { !existingIDs.contains($0.id) }
            .map { BikePointAnnotation(bikePoint: $0) }
        mapView.addAnnotations(toAdd)

        // MapKit sometimes won't call viewFor(annotation:) for freshly-added
        // annotations until the next user-initiated region change. Force a
        // layout pass so pins appear immediately after data loads.
        if !toAdd.isEmpty {
            DispatchQueue.main.async {
                coordinator.isSettingRegion = true
                mapView.setRegion(mapView.region, animated: false)
            }
        }

        // Update selection appearance on all visible annotation views
        for annotation in mapView.annotations.compactMap({ $0 as? BikePointAnnotation }) {
            if let view = mapView.view(for: annotation) as? BikePointAnnotationView {
                let isSelected = selectedBikePoint?.id == annotation.bikePoint.id
                view.update(bikePoint: annotation.bikePoint, isSelected: isSelected)
            }
        }

        // Sync destination pin
        let existingDestination = mapView.annotations.first(where: {
            ($0 as? MKPointAnnotation)?.title == "Destination"
        })
        if let dest = destinationCoordinate {
            if let existing = existingDestination as? MKPointAnnotation {
                existing.coordinate = dest
            } else {
                let pin = MKPointAnnotation()
                pin.coordinate = dest
                pin.title = "Destination"
                mapView.addAnnotation(pin)
            }
        } else if let existing = existingDestination {
            mapView.removeAnnotation(existing)
        }

        // Push MapKit's built-in controls (scale, compass) above the bottom sheet
        mapView.layoutMargins.bottom = isCompact ? 100 : 0
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: OfflineMapView
        weak var mapView: MKMapView?
        var lastAppliedPosition: MapCameraPosition?
        var isSettingRegion = false

        init(parent: OfflineMapView) {
            self.parent = parent
        }

        // MARK: Tile renderer
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: Tile coverage bounds (must match download_tiles.py CITIES bboxes)
        // Each tuple: (minLat, maxLat, minLon, maxLon)
        static let tileBounds: [(Double, Double, Double, Double)] = [
            (51.4462, 51.5638, -0.2074, -0.0226),   // london
            (48.8096, 48.9104,  2.2458,  2.4642),   // paris
            (40.6728, 40.8072, -74.0472, -73.9128), // new_york
        ]

        /// Returns the coordinate clamped to the nearest tile-coverage bbox, or
        /// nil if the coordinate is already inside one of them.
        static func clampedCoordinate(
            _ coord: CLLocationCoordinate2D
        ) -> CLLocationCoordinate2D? {
            for (minLat, maxLat, minLon, maxLon) in tileBounds {
                if coord.latitude  >= minLat && coord.latitude  <= maxLat &&
                   coord.longitude >= minLon && coord.longitude <= maxLon {
                    return nil  // already inside a covered area
                }
            }
            // Outside all bboxes: clamp to the nearest one
            func squaredDist(_ coord: CLLocationCoordinate2D,
                             _ b: (Double, Double, Double, Double)) -> Double {
                let (minLat, maxLat, minLon, maxLon) = b
                let dLat = coord.latitude  - min(max(coord.latitude,  minLat), maxLat)
                let dLon = coord.longitude - min(max(coord.longitude, minLon), maxLon)
                return dLat * dLat + dLon * dLon
            }
            let nearest = tileBounds.min { squaredDist(coord, $0) < squaredDist(coord, $1) }!
            let (minLat, maxLat, minLon, maxLon) = nearest
            return CLLocationCoordinate2D(
                latitude:  min(max(coord.latitude,  minLat), maxLat),
                longitude: min(max(coord.longitude, minLon), maxLon)
            )
        }

        // MARK: Region change → clamp + update binding
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard !isSettingRegion else {
                isSettingRegion = false
                return
            }
            let center = mapView.region.center
            if let clamped = Coordinator.clampedCoordinate(center) {
                isSettingRegion = true
                var snapped = mapView.region
                snapped.center = clamped
                mapView.setRegion(snapped, animated: true)
                return
            }
            parent.mapCameraCenter = center
        }

        // MARK: Annotation views
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let bikeAnnotation = annotation as? BikePointAnnotation {
                let id = "BikePoint"
                let view =
                    (mapView.dequeueReusableAnnotationView(withIdentifier: id)
                        as? BikePointAnnotationView)
                    ?? BikePointAnnotationView(annotation: bikeAnnotation, reuseIdentifier: id)
                view.annotation = bikeAnnotation
                let isSelected = parent.selectedBikePoint?.id == bikeAnnotation.bikePoint.id
                view.update(bikePoint: bikeAnnotation.bikePoint, isSelected: isSelected)
                return view
            }

            if let point = annotation as? MKPointAnnotation, point.title == "Destination" {
                let id = "Destination"
                let view =
                    mapView.dequeueReusableAnnotationView(withIdentifier: id)
                    as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.markerTintColor = .orange
                view.isEnabled = false
                return view
            }

            return nil
        }

        // MARK: Annotation selection → bike point tap
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let bikeAnnotation = view.annotation as? BikePointAnnotation {
                parent.onBikePointTap(bikeAnnotation.bikePoint)
            }
            // Immediately deselect so the same pin can be tapped again
            mapView.deselectAnnotation(view.annotation, animated: false)
        }

        // MARK: Map background tap → deselect
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView, gesture.state == .recognized else { return }
            let location = gesture.location(in: mapView)

            // Walk up from the hit view: if we pass through an annotation view,
            // this tap is on a pin and should not deselect.
            var hitView: UIView? = mapView.hitTest(location, with: nil)
            while let v = hitView {
                if v is MKAnnotationView { return }
                hitView = v.superview
            }

            parent.onMapTap()
        }

        // Allow the map's own internal gesture recognizers to coexist
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
