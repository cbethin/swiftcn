import Foundation
import Observation

struct DayTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var project: String
    var done = false
    var date = Date()
}
struct Expense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var cents: Int
    var category: String
    var date = Date()
}
struct JournalEntry: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var mood: String
    var starred = false
    var date = Date()
}
struct Trip: Identifiable, Codable {
    var id = UUID()
    var title: String
    var subtitle: String
    var symbol: String
    var date: Date
    var activities: [TripActivity]
    var packing: [PackingItem]
}
struct TripActivity: Identifiable, Codable {
    var id = UUID()
    var title: String
    var time: String
    var done = false
}
struct PackingItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var packed = false
}
struct ShowcaseData: Codable {
    var tasks: [DayTask]
    var expenses: [Expense]
    var entries: [JournalEntry]
    var trips: [Trip]
    var budgetCents = 200000
    static var sample: Self {
        .init(tasks: [
            .init(title: "Make space for a good idea", project: "Personal"),
            .init(title: "Sketch the next chapter", project: "Studio"),
            .init(title: "A walk without headphones", project: "Personal"),
            .init(title: "Send the first draft", project: "Studio", done: true)
        ], expenses: [
            .init(title: "Sunday groceries", cents: 6420, category: "Food"),
            .init(title: "Corner café", cents: 650, category: "Food"),
            .init(title: "Train to the coast", cents: 2800, category: "Travel"),
            .init(title: "A very good book", cents: 2400, category: "Life"),
            .init(title: "Studio supplies", cents: 3850, category: "Life")
        ], entries: [
            .init(title: "Small things, noticed", body: "The light came through the kitchen window just right this morning. Coffee, an open notebook, and nowhere to rush.\n\nI want to make more room for days like this.", mood: "Peaceful", starred: true),
            .init(title: "A little further", body: "Took the long way home. Found a tiny bookshop I had walked past a hundred times.\n\nSometimes a different route is all it takes.", mood: "Inspired", date: Date().addingTimeInterval(-86400)),
            .init(title: "Things worth keeping", body: "Dinner with old friends. A conversation that went on longer than the meal. That feeling of being understood.", mood: "Grateful", date: Date().addingTimeInterval(-172800))
        ], trips: [
            .init(title: "A weekend in Kyoto", subtitle: "Slow mornings. New streets.", symbol: "leaf", date: Date().addingTimeInterval(86400 * 14),
                  activities: [.init(title: "Coffee by the river", time: "09:00"), .init(title: "Walk the Philosopher’s Path", time: "11:00"), .init(title: "Dinner in Gion", time: "18:30")],
                  packing: [.init(title: "Passport"), .init(title: "Camera"), .init(title: "Walking shoes"), .init(title: "A good book")]),
            .init(title: "The coast, unhurried", subtitle: "Salt air and nothing scheduled.", symbol: "water.waves", date: Date().addingTimeInterval(86400 * 35),
                  activities: [.init(title: "Find the ocean", time: "10:00"), .init(title: "Lunch at the harbor", time: "13:00")],
                  packing: [.init(title: "Sunglasses"), .init(title: "Swimsuit"), .init(title: "Sunscreen")])
        ])
    }
}

/// One small value snapshot; observation tracks reads, and edits persist immediately.
@MainActor @Observable final class ShowcaseStore {
    private let defaults: UserDefaults
    var data: ShowcaseData { didSet { persist() } }
    var saveError: String?
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.data(forKey: "swiftcn.showcase.v1"),
           let decoded = try? JSONDecoder().decode(ShowcaseData.self, from: saved) { data = decoded }
        else { data = .sample }
    }
    private func persist() {
        do { defaults.set(try JSONEncoder().encode(data), forKey: "swiftcn.showcase.v1"); saveError = nil }
        catch { saveError = "Your last change could not be saved. Please try again." }
    }
    var monthlyExpenses: [Expense] {
        data.expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }
    var spentCents: Int { monthlyExpenses.reduce(0) { $0 + $1.cents } }
    static func cents(from text: String) -> Int? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }), clean.filter({ $0 == "." }).count <= 1,
              let amount = Decimal(string: clean, locale: Locale(identifier: "en_US_POSIX")), amount > 0, amount <= 1000000 else { return nil }
        let scaled = amount * 100
        var source = scaled, rounded = Decimal()
        NSDecimalRound(&rounded, &source, 0, .plain)
        guard rounded > 0 else { return nil }
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
