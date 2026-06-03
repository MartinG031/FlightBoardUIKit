import Foundation

struct FlightEntry: Codable, Equatable, Identifiable {
    enum Airline: String, Codable, CaseIterable {
        case mu = "MU"
        case ca = "CA"
        case cz = "CZ"
        case custom = "自定"
    }

    var id = UUID()
    var airline: Airline = .mu
    var customAirline = ""
    var flightNumber = ""
    var stand = ""
    var times = Array(repeating: "", count: 4)

    var prefix: String {
        let value = airline == .custom ? customAirline : airline.rawValue
        return value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var displayFlightNumber: String {
        prefix + flightNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isComplete: Bool {
        !prefix.isEmpty &&
        !flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !stand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        times.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var sortTime: Int? {
        times.compactMap(Self.normalizedTimeValue).min()
    }

    static func emptyRows(count: Int = 9) -> [FlightEntry] {
        (0..<count).map { index in
            var entry = FlightEntry()
            switch index {
            case 0...1:
                entry.airline = .mu
            case 2...3:
                entry.airline = .ca
            case 4...5:
                entry.airline = .cz
            default:
                entry.airline = .custom
            }
            return entry
        }
    }

    static func normalizedTimeValue(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 3 || digits.count == 4, let value = Int(digits) else { return nil }
        let hour = value / 100
        let minute = value % 100
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return hour * 60 + minute
    }
}
