import MapKit
import UIKit

/// MKTileOverlay subclass that loads pre-bundled OSM raster tiles from
/// Resources/tile_{z}_{x}_{y}.png, enabling fully offline map rendering.
///
/// Zoom strategy:
/// - z 12 to 14: serve the exact bundled tile
/// - z > 14: overzoom by cropping the z=14 ancestor tile to the sub-region
///   that corresponds to the requested tile, then scale back to 256x256
///   (slightly soft when very close, but correct geography)
/// - z < 12: return nil so MKMapView shows the background colour
///
/// minimumZ/maximumZ span 0 to 21 so canReplaceMapContent suppresses Apple Maps
/// at every zoom level.
class LocalTileOverlay: MKTileOverlay {

    private let minTileZ = 12
    private let maxTileZ = 14

    init() {
        super.init(urlTemplate: nil)
        canReplaceMapContent = true
        minimumZ = 0
        maximumZ = 21
        tileSize = CGSize(width: 256, height: 256)
    }

    override func loadTile(
        at path: MKTileOverlayPath,
        result: @escaping (Data?, Error?) -> Void
    ) {
        let requestedZ = path.z

        if requestedZ < minTileZ {
            result(nil, nil)
            return
        }

        if requestedZ <= maxTileZ {
            // Exact tile: serve directly.
            let url = Bundle.main.url(
                forResource: "tile_\(requestedZ)_\(path.x)_\(path.y)",
                withExtension: "png"
            )
            result(url.flatMap { try? Data(contentsOf: $0) }, nil)
            return
        }

        // Overzoom: find the z=14 ancestor, then crop it to the sub-region
        // that corresponds to the requested tile.
        let delta = requestedZ - maxTileZ           // e.g. 1 for z=15, 2 for z=16
        let parentX = path.x >> delta
        let parentY = path.y >> delta

        guard
            let parentURL = Bundle.main.url(
                forResource: "tile_\(maxTileZ)_\(parentX)_\(parentY)",
                withExtension: "png"
            ),
            let parentData = try? Data(contentsOf: parentURL)
        else {
            result(nil, nil)
            return
        }

        // Which sub-tile within the parent are we?
        // At delta=1 the parent is split 2×2; at delta=2 it's split 4×4, etc.
        let divisions  = 1 << delta                 // 2^delta tiles per side
        let subX       = path.x & (divisions - 1)  // column within the parent
        let subY       = path.y & (divisions - 1)  // row within the parent
        let cropSize   = 256 / divisions            // pixel size of the sub-region
        let cropRect   = CGRect(
            x: subX * cropSize,
            y: subY * cropSize,
            width: cropSize,
            height: cropSize
        )

        result(crop(parentData, to: cropRect), nil)
    }

    // MARK: Image helpers

    /// Crops `data` (a PNG) to `rect` and scales the result back to 256x256.
    private func crop(_ data: Data, to rect: CGRect) -> Data? {
        guard
            let provider = CGDataProvider(data: data as CFData),
            let source   = CGImage(
                pngDataProviderSource: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            ),
            let cropped  = source.cropping(to: rect)
        else { return nil }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        return renderer.pngData { ctx in
            ctx.cgContext.interpolationQuality = .none  // pixel-art style, fast
            UIImage(cgImage: cropped).draw(in: CGRect(x: 0, y: 0, width: 256, height: 256))
        }
    }
}
