import Foundation

public struct ClaimedStamp: Identifiable, Codable, Equatable, Sendable {
    public let id: String   // matches StampDefinition.id
    public let dateClaimed: Date
}
