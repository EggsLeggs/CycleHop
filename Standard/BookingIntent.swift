import Foundation

/// Describes how to open booking for a station (deep link, web, or unavailable).
public struct BookingIntent: Sendable {
    public enum Method: Sendable {
        case appDeepLink(url: URL, webFallback: URL?)
        case webOnly(url: URL)
        case unavailable
    }

    public let stationId: String
    public let method: Method
    public let displayName: String

    public init(stationId: String, method: Method, displayName: String) {
        self.stationId = stationId
        self.method = method
        self.displayName = displayName
    }
}
