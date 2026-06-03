import UIKit

final class FlightRowsView: UIView {
    private enum Constants {
        static let rowHeight: CGFloat = 52
    }

    private var rowViews: [FlightRowView] = []

    var requiredHeight: CGFloat {
        height(forRowCount: rowViews.count)
    }

    func height(forRowCount count: Int) -> CGFloat {
        CGFloat(count) * Constants.rowHeight
    }

    func setRows(_ rows: [FlightRowView]) {
        rowViews.forEach { $0.removeFromSuperview() }
        rowViews = rows
        rows.forEach(addSubview)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func appendRows(_ rows: [FlightRowView]) {
        rowViews.append(contentsOf: rows)
        rows.forEach(addSubview)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func setRowOrder(_ rows: [FlightRowView]) {
        rowViews = rows
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: requiredHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for (index, rowView) in rowViews.enumerated() {
            rowView.frame = CGRect(
                x: 0,
                y: CGFloat(index) * Constants.rowHeight,
                width: bounds.width,
                height: Constants.rowHeight
            )
        }
    }
}

final class FlightHeaderView: UIView {
    private let flightLabel = FlightHeaderView.makeLabel("航班号")
    private let standLabel = FlightHeaderView.makeLabel("机位")
    private let timeLabels = ["机务", "入", "推", "结束"].map(FlightHeaderView.makeLabel)

    override init(frame: CGRect) {
        super.init(frame: frame)
        [flightLabel, standLabel].forEach(addSubview)
        timeLabels.forEach(addSubview)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let frames = FlightGridLayout.frames(in: bounds, verticalInset: 0, contentVerticalInset: 0)
        flightLabel.frame = frames.flight
        standLabel.frame = frames.stand
        for (label, frame) in zip(timeLabels, frames.times) {
            label.frame = frame
        }
    }

    private static func makeLabel(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }
}
