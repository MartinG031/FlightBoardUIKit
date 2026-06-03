import Foundation

final class FlightEntriesStore {
    private enum Constants {
        static let storageKey = "flight_entries_v1"
        static let rowCount = 9
        static let digitLimit = 4
    }

    private static let loadQueue = DispatchQueue(label: "FlightBoardUIKit.flightEntriesStore.load", qos: .userInitiated)
    private let saveQueue = DispatchQueue(label: "FlightBoardUIKit.flightEntriesStore.save", qos: .utility)
    private var pendingSaveWorkItem: DispatchWorkItem?
    private(set) var entries: [FlightEntry]

    init() {
        entries = Self.loadEntries()
    }

    static func loadAsync(completion: @escaping (FlightEntriesStore) -> Void) {
        loadQueue.async {
            let store = FlightEntriesStore()
            DispatchQueue.main.async {
                completion(store)
            }
        }
    }

    func update(id: FlightEntry.ID, mutate: (inout FlightEntry) -> Void) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let previous = entries[index]
        mutate(&entries[index])
        guard entries[index] != previous else { return }
        scheduleSave()
    }

    func clear() {
        entries = FlightEntry.emptyRows(count: Constants.rowCount)
        saveNow()
    }

    @discardableResult
    func sortCompletedRowsFirst() -> Bool {
        let oldEntries = entries
        entries = entries.enumerated().sorted { lhs, rhs in
            let left = lhs.element
            let right = rhs.element
            switch (left.isComplete, right.isComplete, left.sortTime, right.sortTime) {
            case (true, true, let leftTime?, let rightTime?):
                if leftTime == rightTime { return lhs.offset < rhs.offset }
                return leftTime < rightTime
            case (true, false, _, _):
                return true
            case (false, true, _, _):
                return false
            default:
                return lhs.offset < rhs.offset
            }
        }.map(\.element)

        guard entries != oldEntries else { return false }
        saveNow()
        return true
    }

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()
        let snapshot = entries
        let item = DispatchWorkItem { [weak self, snapshot] in
            self?.save(snapshot: snapshot)
        }
        pendingSaveWorkItem = item
        saveQueue.asyncAfter(deadline: .now() + 0.75, execute: item)
    }

    private func saveNow() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        let snapshot = entries
        saveQueue.async { [weak self, snapshot] in
            self?.save(snapshot: snapshot)
        }
    }

    private func save(snapshot: [FlightEntry]) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Constants.storageKey)
    }

    private static func loadEntries() -> [FlightEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: Constants.storageKey),
            let decoded = try? JSONDecoder().decode([FlightEntry].self, from: data)
        else {
            return FlightEntry.emptyRows(count: Constants.rowCount)
        }
        return normalizedRowCount(decoded)
    }

    private static func normalizedRowCount(_ source: [FlightEntry]) -> [FlightEntry] {
        var rows = Array(source.prefix(Constants.rowCount)).enumerated().map { index, entry in
            sanitizedEntry(entry, row: index)
        }
        while rows.count < Constants.rowCount {
            rows.append(FlightEntry.emptyRows(count: Constants.rowCount)[rows.count])
        }
        return rows
    }

    private static func sanitizedEntry(_ entry: FlightEntry, row: Int) -> FlightEntry {
        var sanitized = entry
        if isBlank(sanitized) {
            sanitized.airline = FlightEntry.emptyRows(count: Constants.rowCount)[row].airline
        }
        sanitized.flightNumber = fourDigits(sanitized.flightNumber)
        sanitized.stand = fourDigits(sanitized.stand)
        sanitized.times = sanitized.times.map(fourDigits)
        return sanitized
    }

    private static func isBlank(_ entry: FlightEntry) -> Bool {
        entry.customAirline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        entry.flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        entry.stand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        entry.times.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func fourDigits(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(Constants.digitLimit))
    }
}
