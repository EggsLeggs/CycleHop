import Foundation

public struct CycleSystem: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let city: String
    public let country: String
    public let operatorName: String?
    public let brandColour: String?
    public let logoURL: URL?
    public let infoURL: URL?
    public let serviceArea: ServiceArea?
    public let timezone: String
    public let capabilities: ProviderCapabilities

    public init(
        id: String,
        name: String,
        city: String,
        country: String,
        operatorName: String?,
        brandColour: String?,
        logoURL: URL?,
        infoURL: URL?,
        serviceArea: ServiceArea?,
        timezone: String,
        capabilities: ProviderCapabilities
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.country = country
        self.operatorName = operatorName
        self.brandColour = brandColour
        self.logoURL = logoURL
        self.infoURL = infoURL
        self.serviceArea = serviceArea
        self.timezone = timezone
        self.capabilities = capabilities
    }
}
