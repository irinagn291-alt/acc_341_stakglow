import Foundation

/// Monday of the week that contains `date`, as YYYYMMDD from `startOfDay`.
enum WeekDaykey {
    static func monday(containing date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: start)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: start) else {
            return 0
        }
        let parts = calendar.dateComponents([.year, .month, .day], from: monday)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}
