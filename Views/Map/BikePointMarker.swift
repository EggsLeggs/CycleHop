import SwiftUI

struct BikePointMarker: View {
    let bikePoint: BikePoint
    let isSelected: Bool

    private var standardBikes: Int { bikePoint.nbStandardBikes ?? 0 }
    private var eBikes: Int { bikePoint.nbEBikes ?? 0 }
    private var emptyDocks: Int { bikePoint.nbEmptyDocks ?? 0 }
    private var markerSize: CGFloat { isSelected ? 44 : 32 }

    var body: some View {
        VStack(spacing: 0) {
            BikePointMiniChart(
                standardBikes: standardBikes,
                eBikes: eBikes,
                emptyDocks: emptyDocks,
                size: markerSize
            )
            .shadow(color: .black.opacity(isSelected ? 0.3 : 0.15), radius: isSelected ? 4 : 2, y: isSelected ? 2 : 1)

            // Pin stem
            if isSelected {
                Triangle()
                    .fill(.white)
                    .frame(width: 10, height: 6)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
