import UIKit

enum FlightGridLayout {
    struct Frames {
        let index: CGRect
        let flight: CGRect
        let stand: CGRect
        let times: [CGRect]
    }

    static let horizontalInset: CGFloat = 8
    static let verticalInset: CGFloat = 3
    static let contentInset: CGFloat = 6
    static let columnGap: CGFloat = 4
    static let indexWidth: CGFloat = 16
    static let visualColumnCount: CGFloat = 7

    static func frames(
        in bounds: CGRect,
        horizontalInset: CGFloat = Self.horizontalInset,
        verticalInset: CGFloat = Self.verticalInset,
        contentVerticalInset: CGFloat = 7
    ) -> Frames {
        let card = bounds.insetBy(dx: horizontalInset, dy: verticalInset)
        let content = card.insetBy(dx: contentInset, dy: contentVerticalInset)

        let availableColumnWidth = content.width - indexWidth - columnGap * visualColumnCount
        let columnWidth = max(36, availableColumnWidth / visualColumnCount)

        var x = content.minX
        let index = CGRect(x: x, y: content.minY, width: indexWidth, height: content.height)
        x += indexWidth + columnGap

        let flight = CGRect(
            x: x,
            y: content.minY,
            width: columnWidth * 2 + columnGap,
            height: content.height
        )
        x += flight.width + columnGap

        let stand = CGRect(x: x, y: content.minY, width: columnWidth, height: content.height)
        x += columnWidth + columnGap

        let times = (0..<4).map { offset in
            CGRect(
                x: x + CGFloat(offset) * (columnWidth + columnGap),
                y: content.minY,
                width: columnWidth,
                height: content.height
            )
        }

        return Frames(index: index, flight: flight, stand: stand, times: times)
    }
}

final class FlightRowView: UIView, UITextFieldDelegate {
    var onAirlineChange: ((FlightEntry.Airline) -> Void)?
    var onCustomAirlineChange: ((String) -> Void)?
    var onTextChange: ((FlightField, String) -> Void)?
    var onDigitFieldTap: ((FlightField, String) -> Void)?
    var onDigitFieldLongPress: ((FlightField, String) -> Void)?
    var onEditingBegan: (() -> Void)?
    var onEditingFinished: (() -> Void)?

    private let indexLabel = UILabel()
    private let airlineButton = UIButton(type: .system)
    private let customAirlineField = UITextField()
    private let numberField = FlightDigitCellView()
    private let standField = FlightDigitCellView()
    private let timeFields = (0..<4).map { _ in FlightDigitCellView() }
    private let card = UIView()
    private var currentAirline: FlightEntry.Airline = .mu

    enum FlightField: Equatable {
        case number
        case stand
        case time(Int)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        buildLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(entry: FlightEntry, row: Int) {
        currentAirline = entry.airline
        setRowNumber(row + 1)
        setAirlineTitle(entry)
        customAirlineField.text = entry.customAirline
        updateAirlineControls()
        numberField.setText(entry.flightNumber)
        standField.setText(entry.stand)
        for index in 0..<timeFields.count {
            timeFields[index].setText(entry.times[index])
        }
        setNeedsLayout()
    }

    func setRowNumber(_ value: Int) {
        indexLabel.text = "\(value)"
    }

    func value(for field: FlightField) -> String {
        switch field {
        case .number:
            return numberField.text
        case .stand:
            return standField.text
        case .time(let index):
            return timeFields[index].text
        }
    }

    func setValue(_ value: String, for field: FlightField) {
        switch field {
        case .number:
            numberField.setText(value)
        case .stand:
            standField.setText(value)
        case .time(let index):
            timeFields[index].setText(value)
        }
    }

    func setActiveField(_ activeField: FlightField?) {
        numberField.isActive = activeField == .number
        standField.isActive = activeField == .stand
        for index in 0..<timeFields.count {
            timeFields[index].isActive = activeField == .time(index)
        }
    }

    private func buildLayout() {
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 8
        card.layer.cornerCurve = .continuous
        addSubview(card)

        indexLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        indexLabel.textColor = .secondaryLabel
        indexLabel.textAlignment = .center
        indexLabel.translatesAutoresizingMaskIntoConstraints = false

        airlineButton.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        airlineButton.contentHorizontalAlignment = .center
        airlineButton.showsMenuAsPrimaryAction = true
        airlineButton.menu = buildAirlineMenu()
        airlineButton.backgroundColor = .tertiarySystemGroupedBackground
        airlineButton.layer.cornerRadius = 6

        configureCustomAirlineField()
        numberField.addTarget(self, action: #selector(numberCellTapped), for: .touchUpInside)
        standField.addTarget(self, action: #selector(standCellTapped), for: .touchUpInside)
        for (index, field) in timeFields.enumerated() {
            field.tag = index
            field.addTarget(self, action: #selector(timeCellTapped(_:)), for: .touchUpInside)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(timeCellLongPressed(_:)))
            longPress.minimumPressDuration = 0.35
            field.addGestureRecognizer(longPress)
        }

        customAirlineField.addTarget(self, action: #selector(customAirlineEdited), for: .editingChanged)

        [indexLabel, airlineButton, customAirlineField, numberField, standField].forEach(card.addSubview)
        timeFields.forEach(card.addSubview)
    }

    private func configureCustomAirlineField() {
        let field = customAirlineField
        field.borderStyle = .none
        field.backgroundColor = .tertiarySystemGroupedBackground
        field.textColor = .label
        field.tintColor = .systemBlue
        field.layer.cornerRadius = 6
        field.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        field.adjustsFontSizeToFitWidth = false
        field.textAlignment = .center
        field.keyboardType = .asciiCapable
        field.autocapitalizationType = .allCharacters
        field.autocorrectionType = .no
        field.delegate = self
        field.clearButtonMode = .never
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        card.frame = bounds.insetBy(dx: FlightGridLayout.horizontalInset, dy: FlightGridLayout.verticalInset)
        let frames = FlightGridLayout.frames(in: card.bounds, horizontalInset: 0, verticalInset: 0)
        indexLabel.frame = CGRect(
            x: frames.index.minX,
            y: 0,
            width: frames.index.width,
            height: card.bounds.height
        )
        layoutFlightFields(frame: frames.flight)
        standField.frame = frames.stand

        for (field, frame) in zip(timeFields, frames.times) {
            field.frame = frame
        }
    }

    private func layoutFlightFields(frame: CGRect) {
        let fieldWidth = (frame.width - FlightGridLayout.columnGap) / 2
        let airlineFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: fieldWidth,
            height: frame.height
        )
        let numberFrame = CGRect(
            x: airlineFrame.maxX + FlightGridLayout.columnGap,
            y: frame.minY,
            width: fieldWidth,
            height: frame.height
        )

        airlineButton.frame = airlineFrame
        customAirlineField.frame = airlineFrame
        numberField.frame = numberFrame
    }

    private func buildAirlineMenu() -> UIMenu {
        let actions = FlightEntry.Airline.allCases.map { airline in
            UIAction(title: airline.rawValue) { [weak self] _ in
                self?.currentAirline = airline
                self?.airlineButton.setTitle(airline.rawValue, for: .normal)
                self?.updateAirlineControls()
                self?.setNeedsLayout()
                self?.onAirlineChange?(airline)
            }
        }
        return UIMenu(children: actions)
    }

    private func setAirlineTitle(_ entry: FlightEntry) {
        airlineButton.setTitle(entry.airline.rawValue, for: .normal)
        customAirlineField.placeholder = nil
    }

    @objc private func customAirlineEdited() {
        let value = customAirlineField.text ?? ""
        let uppercased = value.uppercased()
        if value != uppercased {
            customAirlineField.text = uppercased
        }
        if currentAirline == .custom, !uppercased.isEmpty {
            airlineButton.setTitle(uppercased, for: .normal)
        }
        onCustomAirlineChange?(uppercased)
    }

    private func updateAirlineControls() {
        let isCustom = currentAirline == .custom
        airlineButton.isHidden = isCustom
        customAirlineField.isHidden = !isCustom
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onEditingFinished?()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onEditingBegan?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func numberCellTapped() {
        digitCellTapped(.number)
    }

    @objc private func standCellTapped() {
        digitCellTapped(.stand)
    }

    @objc private func timeCellTapped(_ sender: FlightDigitCellView) {
        digitCellTapped(.time(sender.tag))
    }

    @objc private func timeCellLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard
            recognizer.state == .began,
            let sender = recognizer.view as? FlightDigitCellView
        else { return }

        onEditingBegan?()
        onDigitFieldLongPress?(.time(sender.tag), value(for: .time(sender.tag)))
    }

    private func digitCellTapped(_ field: FlightField) {
        onEditingBegan?()
        onDigitFieldTap?(field, value(for: field))
    }
}

private final class FlightDigitCellView: UIControl {
    private let valueLabel = UILabel()

    private(set) var text = ""

    var isActive = false {
        didSet { updateAppearance() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ value: String) {
        text = value
        valueLabel.text = value
    }

    private func buildLayout() {
        backgroundColor = .tertiarySystemGroupedBackground
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous

        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.isUserInteractionEnabled = false
        addSubview(valueLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        valueLabel.frame = bounds.insetBy(dx: 2, dy: 0)
    }

    override var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        if isActive {
            backgroundColor = .systemBlue.withAlphaComponent(0.18)
            layer.borderColor = UIColor.systemBlue.cgColor
            layer.borderWidth = 1
        } else {
            backgroundColor = isHighlighted ? .quaternarySystemFill : .tertiarySystemGroupedBackground
            layer.borderWidth = 0
        }
    }
}
