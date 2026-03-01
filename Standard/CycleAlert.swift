import Foundation

/// A service alert: severity, title, body, affected stations, time range.
public struct CycleAlert: Identifiable, Codable, Sendable {
    public enum Severity: String, Codable, Sendable {
        case info
        case warning
        case critical
    }

    public let id: String
    public let systemId: String
    public let severity: Severity
    public let title: String
    public let body: String?
    public let affectedStationIds: [String]
    public let startsAt: Date?
    public let endsAt: Date?

    public init(
        id: String,
        systemId: String,
        severity: Severity,
        title: String,
        body: String?,
        affectedStationIds: [String],
        startsAt: Date?,
        endsAt: Date?
    ) {
        self.id = id
        self.systemId = systemId
        self.severity = severity
        self.title = title
        self.body = body
        self.affectedStationIds = affectedStationIds
        self.startsAt = startsAt
        self.endsAt = endsAt
    }
}
