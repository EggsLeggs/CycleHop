import Foundation

extension Bundle {
    /// Returns the `.lproj` sub-bundle matching the user's in-app language
    /// preference (set via Settings.bundle), falling back to `Bundle.main`
    /// when set to "system" or unset.
    static var localized: Bundle {
        let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        guard code != "system",
              let path = main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
