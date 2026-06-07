import UIKit

final class FlightsViewController: UIViewController {
    private enum Constants {
        static let maxDigitCount = 4
    }

    private enum DigitActivationMode {
        case primaryTap
        case manualInput
    }

    private var store: FlightEntriesStore?
    private let scrollView = UIScrollView()
    private let rowsView = FlightRowsView()
    private let headerView = FlightHeaderView()
    private let loadingLabel = UILabel()
    private let sharedDigitInput = DigitInputProxy()
    private var sortWorkItem: DispatchWorkItem?
    private var rowViewsByID: [FlightEntry.ID: FlightRowView] = [:]
    private var rowsHeightConstraint: NSLayoutConstraint?
    private var activeDigitRowID: FlightEntry.ID?
    private var activeDigitField: FlightRowView.FlightField?
    private var hasLoadedRows = false
    private var isLoadingRows = false
    private var hasStartedInitialLoad = false
    private var rowBuildWorkItem: DispatchWorkItem?
    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HHmm"
        return formatter
    }()
    private lazy var digitAccessoryToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(endEditingAndSort))
        ]
        toolbar.sizeToFit()
        return toolbar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "航班"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "清空",
            style: .plain,
            target: self,
            action: #selector(clearRows)
        )

        buildHeader()
        buildRowsContainer()
        buildSharedDigitInput()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startInitialLoadIfNeeded()
    }

    private func buildSharedDigitInput() {
        sharedDigitInput.keyboardType = .numberPad
        sharedDigitInput.inputAccessory = digitAccessoryToolbar
        sharedDigitInput.onTextChanged = { [weak self] text in
            self?.updateActiveDigitValue(text)
        }
        sharedDigitInput.onDidEndEditing = { [weak self] in
            self?.clearActiveDigitSelection()
            self?.scheduleSort()
        }
        view.addSubview(sharedDigitInput)
    }

    private func buildHeader() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        container.addSubview(headerView)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 24),
            headerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func buildRowsContainer() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        rowsView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(rowsView)
        rowsHeightConstraint = rowsView.heightAnchor.constraint(equalToConstant: 60)
        rowsHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -58),

            rowsView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            rowsView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            rowsView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            rowsView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            rowsView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        loadingLabel.text = "正在准备航班表..."
        loadingLabel.font = .preferredFont(forTextStyle: .footnote)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        rowsView.addSubview(loadingLabel)
        NSLayoutConstraint.activate([
            loadingLabel.leadingAnchor.constraint(equalTo: rowsView.leadingAnchor),
            loadingLabel.trailingAnchor.constraint(equalTo: rowsView.trailingAnchor),
            loadingLabel.topAnchor.constraint(equalTo: rowsView.topAnchor),
            loadingLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func scheduleSort() {
        sortWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.sortRows(animated: true)
        }
        sortWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    private func cancelPendingSort() {
        sortWorkItem?.cancel()
        sortWorkItem = nil
    }

    private func clearActiveDigitSelection() {
        guard let activeDigitRowID, let rowView = rowViewsByID[activeDigitRowID] else {
            self.activeDigitRowID = nil
            activeDigitField = nil
            return
        }
        rowView.setActiveField(nil)
        self.activeDigitRowID = nil
        activeDigitField = nil
    }

    private func sortRows(animated: Bool) {
        guard let store, store.sortCompletedRowsFirst() else { return }
        let reorder = { self.reorderRowsFromStore() }
        animated ? UIView.animate(withDuration: 0.18, animations: reorder) : reorder()
    }

    private func startInitialLoadIfNeeded() {
        guard !hasStartedInitialLoad else { return }
        hasStartedInitialLoad = true
        DispatchQueue.main.async { [weak self] in
            self?.loadRowsIfNeeded()
        }
    }

    private func loadRowsIfNeeded() {
        guard !hasLoadedRows, !isLoadingRows else { return }
        isLoadingRows = true
        FlightEntriesStore.loadAsync { [weak self] store in
            guard let self else { return }
            self.store = store
            self.hasLoadedRows = true
            self.isLoadingRows = false
            self.reloadRowViews()
        }
    }

    private func reloadRowViews() {
        guard let store else { return }
        rowBuildWorkItem?.cancel()
        rowBuildWorkItem = nil
        rowViewsByID.removeAll()
        loadingLabel.removeFromSuperview()
        rowsView.setRows([])
        rowsHeightConstraint?.constant = rowsView.height(forRowCount: store.entries.count)
        buildRowsIncrementally(from: store.entries, startIndex: 0)
    }

    private func buildRowsIncrementally(from entries: [FlightEntry], startIndex: Int) {
        guard startIndex < entries.count else { return }

        let batchEnd = min(startIndex + 3, entries.count)
        var newRows: [FlightRowView] = []
        for index in startIndex..<batchEnd {
            let entry = entries[index]
            let rowView = makeRowView(entry: entry, row: index)
            rowViewsByID[entry.id] = rowView
            newRows.append(rowView)
        }
        rowsView.appendRows(newRows)

        guard batchEnd < entries.count else { return }
        let item = DispatchWorkItem { [weak self, entries] in
            self?.buildRowsIncrementally(from: entries, startIndex: batchEnd)
        }
        rowBuildWorkItem = item
        DispatchQueue.main.async(execute: item)
    }

    private func reorderRowsFromStore() {
        guard let store else { return }
        var orderedRows: [FlightRowView] = []
        for (index, entry) in store.entries.enumerated() {
            guard let rowView = rowViewsByID[entry.id] else { continue }
            rowView.setRowNumber(index + 1)
            orderedRows.append(rowView)
        }
        rowsView.setRowOrder(orderedRows)
    }

    private func makeRowView(entry: FlightEntry, row: Int) -> FlightRowView {
        let rowView = FlightRowView()
        rowView.translatesAutoresizingMaskIntoConstraints = true
        rowView.configure(entry: entry, row: row)
        rowView.onAirlineChange = { [weak self, id = entry.id] airline in
            self?.store?.update(id: id) { entry in
                entry.airline = airline
                if airline != .custom { entry.customAirline = "" }
            }
        }
        rowView.onCustomAirlineChange = { [weak self, id = entry.id] value in
            self?.store?.update(id: id) { entry in
                entry.customAirline = value
            }
        }
        rowView.onTextChange = { [weak self, id = entry.id] field, value in
            self?.store?.update(id: id) { entry in
                switch field {
                case .number:
                    entry.flightNumber = value
                case .stand:
                    entry.stand = value
                case .time(let index):
                    entry.times[index] = value
                }
            }
        }
        rowView.onEditingBegan = { [weak self] in
            self?.cancelPendingSort()
            self?.clearActiveDigitSelection()
        }
        rowView.onDigitFieldTap = { [weak self, id = entry.id, weak rowView] field, value in
            guard let self, let rowView else { return }
            self.activateDigitField(rowID: id, rowView: rowView, field: field, value: value, mode: .primaryTap)
        }
        rowView.onDigitFieldLongPress = { [weak self, id = entry.id, weak rowView] field, value in
            guard let self, let rowView else { return }
            self.activateDigitField(rowID: id, rowView: rowView, field: field, value: value, mode: .manualInput)
        }
        rowView.onEditingFinished = { [weak self] in
            self?.scheduleSort()
        }
        return rowView
    }

    @objc private func clearRows() {
        let alert = UIAlertController(title: "清空航班", message: "清空 9 行输入内容？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            self?.loadRowsIfNeeded()
            self?.clearActiveDigitSelection()
            self?.sharedDigitInput.setText("", notify: false)
            self?.store?.clear()
            self?.reloadRowViews()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func endEditingAndSort() {
        clearActiveDigitSelection()
        view.endEditing(true)
        sortRows(animated: true)
    }

    private func activateDigitField(
        rowID: FlightEntry.ID,
        rowView: FlightRowView,
        field: FlightRowView.FlightField,
        value: String,
        mode: DigitActivationMode
    ) {
        cancelPendingSort()

        if case .time = field, mode == .primaryTap {
            sharedDigitInput.resignFirstResponder()
            clearActiveDigitSelection()
            applyDigitValue(timestampFormatter.string(from: Date()), rowID: rowID, rowView: rowView, field: field)
            scheduleSort()
            return
        }

        if activeDigitRowID != rowID {
            clearActiveDigitSelection()
        } else if let activeDigitField, activeDigitField != field {
            rowView.setActiveField(nil)
        }

        activeDigitRowID = rowID
        activeDigitField = field
        rowView.setActiveField(field)
        sharedDigitInput.setText(value, notify: false)
        sharedDigitInput.becomeFirstResponder()
    }

    private func updateActiveDigitValue(_ rawValue: String) {
        guard
            let activeDigitRowID,
            let activeDigitField,
            let rowView = rowViewsByID[activeDigitRowID]
        else { return }

        let value = fourDigits(rawValue)
        if sharedDigitInput.text != value {
            sharedDigitInput.setText(value, notify: false)
        }
        applyDigitValue(value, rowID: activeDigitRowID, rowView: rowView, field: activeDigitField)
    }

    private func applyDigitValue(
        _ value: String,
        rowID: FlightEntry.ID,
        rowView: FlightRowView,
        field: FlightRowView.FlightField
    ) {
        rowView.setValue(value, for: field)
        store?.update(id: rowID) { entry in
            switch field {
            case .number:
                entry.flightNumber = value
            case .stand:
                entry.stand = value
            case .time(let index):
                entry.times[index] = value
            }
        }
    }

    private func fourDigits(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(Constants.maxDigitCount))
    }
}
