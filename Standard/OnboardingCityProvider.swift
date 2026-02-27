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
}

public extension OnboardingCityProvider {
    var brandForegroundColor: Color { .white }
    var cityArtSVGName: String? { nil }
}
