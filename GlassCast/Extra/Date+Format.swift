import Foundation

extension Date {
    func weekdayShort() -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    func longDayMonth() -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: self)
    }
}
