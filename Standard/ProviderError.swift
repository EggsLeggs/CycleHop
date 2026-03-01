import Foundation

/// Errors from bike share providers (network, decoding, auth, rate limit, unsupported).
public enum ProviderError: Error, @unchecked Sendable {
    case networkUnavailable
    case dataNotFound
    case decodingFailed(underlying: Error)
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case unsupportedOperation(String)
    case providerUnavailable(String)
}

extension ProviderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable."
        case .dataNotFound:
            return "Requested data was not found."
        case .decodingFailed(let underlying):
            return "Decoding failed: \(underlying.localizedDescription)"
        case .unauthorized:
            return "Authorization required."
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited. Retry after \(Int(retryAfter)) seconds."
            }
            return "Rate limited."
        case .unsupportedOperation(let op):
            return "Unsupported operation: \(op)"
        case .providerUnavailable(let reason):
            return "Provider unavailable: \(reason)"
        }
    }
}
