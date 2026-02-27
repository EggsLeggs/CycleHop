import Foundation

extension String {
    func splitBikePointName() -> (primary: String, secondary: String?) {
        let components = self.components(separatedBy: ", ")
        guard components.count >= 2 else { return (self, nil) }
        return (components[0], components.dropFirst().joined(separator: ", "))
    }
}
