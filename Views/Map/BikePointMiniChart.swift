import SwiftUI

/// A wedge of a circle for pie chart segments.
struct PieSegment: Shape {
    var startAngle: Double
    var endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle - 90),
            endAngle: .degrees(endAngle - 90),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

/// Pie chart showing standard bikes (red), e-bikes (blue), empty docks (grey ring).
struct BikePointMiniChart: View {
    let standardBikes: Int
    let eBikes: Int
    let emptyDocks: Int
    let size: CGFloat

    private var total: Int {
        max(standardBikes + eBikes + emptyDocks, 1)
    }

    private var standardAngle: Double {
        Double(standardBikes) / Double(total) * 360
    }

    private var eBikeAngle: Double {
        Double(eBikes) / Double(total) * 360
    }

    var body: some View {
        ZStack {
            // Grey background for empty docks
            Circle()
                .fill(Color.gray.opacity(0.3))

            // Standard bikes (red)
            if standardBikes > 0 {
                PieSegment(startAngle: 0, endAngle: standardAngle)
                    .fill(Color.red)
            }

            // E-bikes (blue)
            if eBikes > 0 {
                PieSegment(startAngle: standardAngle, endAngle: standardAngle + eBikeAngle)
                    .fill(Color.blue)
            }

            // Inner circle with count
            Circle()
                .fill(.white)
                .frame(width: size * 0.55, height: size * 0.55)

            Text("\(standardBikes + eBikes)")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(.primary)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: NSLocalizedString("a11y_chart_format", bundle: .localized, comment: ""), standardBikes, eBikes, emptyDocks))
    }
}
