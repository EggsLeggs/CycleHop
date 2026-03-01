import SwiftUI
import UIKit

extension Color {
    /// WCAG relative luminance (0 = black, 1 = white)
    var relativeLuminance: Double {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0 }
        func lin(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * Double(lin(r)) + 0.7152 * Double(lin(g)) + 0.0722 * Double(lin(b))
    }

    /// WCAG contrast ratio between this color and another (always ≥ 1.0)
    func contrastRatio(against other: Color) -> Double {
        let l1 = max(relativeLuminance, other.relativeLuminance)
        let l2 = min(relativeLuminance, other.relativeLuminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }

    /// Returns a version of this color adjusted to meet the minimum contrast ratio
    /// against the given background. Lightens on dark backgrounds, darkens on light ones.
    func withAdequateContrast(against background: Color, minimumRatio: Double = 3.5) -> Color {
        guard contrastRatio(against: background) < minimumRatio else { return self }
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }

        let bgIsDark = background.relativeLuminance < 0.5
        var adjB = b
        var adjS = s

        for _ in 0..<40 {
            if bgIsDark {
                adjB = min(1.0, adjB + 0.05)
                adjS = max(0.3, adjS - 0.015)
            } else {
                adjB = max(0.0, adjB - 0.05)
            }
            let candidate = Color(hue: Double(h), saturation: Double(adjS), brightness: Double(adjB))
            if candidate.contrastRatio(against: background) >= minimumRatio {
                return candidate
            }
        }
        return Color(hue: Double(h), saturation: Double(adjS), brightness: Double(adjB))
    }

    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
