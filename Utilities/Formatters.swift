import Foundation

func formatDistance(_ meters: Double) -> String {
    if meters < 1000 {
        return "\(Int(meters))m"
    } else {
        return String(format: "%.1fkm", meters / 1000)
    }
}

func formatWalkingTime(_ seconds: Double) -> String {
    let minutes = Int(seconds / 60)
    if minutes < 1 {
        return "<1 min"
    } else if minutes == 1 {
        return "1 min"
    } else {
        return "\(minutes) mins"
    }
}
