import Foundation

/// A pricing plan for a bike share system (price, currency, description, surge).
public struct PricingPlan: Identifiable, Codable, Sendable {
    public enum Currency: String, Codable, Sendable {
        case gbp
        case eur
        case usd
    }

    public let id: String
    public let systemId: String
    public let name: String
    public let currency: Currency
    public let price: Decimal
    public let isTaxable: Bool
    public let description: String
    public let perMinPrice: Decimal?
    public let surgeFactor: Double
    public let planURL: URL?

    public init(
        id: String,
        systemId: String,
        name: String,
        currency: Currency,
        price: Decimal,
        isTaxable: Bool,
        description: String,
        perMinPrice: Decimal?,
        surgeFactor: Double,
        planURL: URL?
    ) {
        self.id = id
        self.systemId = systemId
        self.name = name
        self.currency = currency
        self.price = price
        self.isTaxable = isTaxable
        self.description = description
        self.perMinPrice = perMinPrice
        self.surgeFactor = surgeFactor
        self.planURL = planURL
    }
}
