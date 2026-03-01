import Foundation

extension String {
    /// Splits a bike point name on ", " into primary and optional secondary (e.g. "Name, Street").
    func splitBikePointName() -> (primary: String, secondary: String?) {
        let components = self.components(separatedBy: ", ")
        guard components.count >= 2 else { return (self, nil) }
        return (components[0], components.dropFirst().joined(separator: ", "))
    }
}
