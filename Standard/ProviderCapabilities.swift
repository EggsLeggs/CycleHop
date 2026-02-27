import Foundation

public struct ProviderCapabilities: Sendable, Codable {
    public let hasDocking: Bool
    public let hasFreeFloating: Bool
    public let hasEBikes: Bool
    public let hasCargoBikes: Bool
    public let hasAdaptiveBikes: Bool
    public let hasRealtimeAvailability: Bool
    public let supportsReservations: Bool
    public let supportsInAppBooking: Bool
    public let requiresAuthentication: Bool
    public let dataSource: DataSource

    public enum DataSource: String, Sendable, Codable {
        case bundledJSON
        case liveAPI
        case hybrid
    }

    public init(
        hasDocking: Bool,
        hasFreeFloating: Bool,
        hasEBikes: Bool,
        hasCargoBikes: Bool,
        hasAdaptiveBikes: Bool,
        hasRealtimeAvailability: Bool,
        supportsReservations: Bool,
        supportsInAppBooking: Bool,
        requiresAuthentication: Bool,
        dataSource: DataSource
    ) {
        self.hasDocking = hasDocking
        self.hasFreeFloating = hasFreeFloating
        self.hasEBikes = hasEBikes
        self.hasCargoBikes = hasCargoBikes
        self.hasAdaptiveBikes = hasAdaptiveBikes
        self.hasRealtimeAvailability = hasRealtimeAvailability
        self.supportsReservations = supportsReservations
        self.supportsInAppBooking = supportsInAppBooking
        self.requiresAuthentication = requiresAuthentication
        self.dataSource = dataSource
    }
}
