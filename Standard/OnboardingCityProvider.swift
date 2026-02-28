import SwiftUI

/// A `BikeShareProvider` that can appear in the onboarding city picker.
public protocol OnboardingCityProvider: BikeShareProvider {
    /// Human-readable city name, e.g. "London"
    var cityDisplayName: String { get }
    /// Bike-share system name, e.g. "Santander Cycles"
    var systemDisplayName: String { get }
    /// Default map centre for this city
    var defaultCenter: Coordinate { get }
    /// Brand colour derived from the provider's hex colour string
    var brandColor: Color { get }
    /// Foreground colour for text rendered on top of brandColor
    var brandForegroundColor: Color { get }
    /// Name of the bundled SVG illustration for this city (without extension), or nil for fallback art
    var cityArtSVGName: String? { get }
    /// Base name of the bundled PNG fallback artwork (without color/state suffix), or nil to use gradient.
    /// E.g. "LondonLocation" resolves to "LondonLocationLight", "LondonLocationDarkHighlighted", etc.
    var cityArtPNGBaseName: String? { get }
    /// Name of the bundled stamp SVG for this city (without extension), or nil if unavailable
    var stampSVGName: String? { get }
}

public extension OnboardingCityProvider {
    var brandForegroundColor: Color { .white }
    var cityArtSVGName: String? { nil }
    var cityArtPNGBaseName: String? { nil }
    var stampSVGName: String? { nil }
}
