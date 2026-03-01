import Foundation

/// A stamp the user has claimed; id matches StampDefinition.id.
public struct ClaimedStamp: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let dateClaimed: Date
}
