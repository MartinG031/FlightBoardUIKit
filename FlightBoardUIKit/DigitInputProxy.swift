import UIKit

final class DigitInputProxy: UIControl, UIKeyInput {
    var text = ""
    var keyboardType: UIKeyboardType = .numberPad
    var inputAccessory: UIView?
    var onTextChanged: ((String) -> Void)?
    var onDidEndEditing: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        backgroundColor = .clear
        isAccessibilityElement = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var inputAccessoryView: UIView? {
        inputAccessory
    }

    var hasText: Bool {
        !text.isEmpty
    }

    func insertText(_ text: String) {
        setText((self.text + text).digitsPrefix(4), notify: true)
    }

    func deleteBackward() {
        guard !text.isEmpty else { return }
        setText(String(text.dropLast()), notify: true)
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign {
            onDidEndEditing?()
        }
        return didResign
    }

    func setText(_ value: String, notify: Bool) {
        text = value.digitsPrefix(4)
        if notify {
            onTextChanged?(text)
        }
    }
}

private extension StringProtocol {
    func digitsPrefix(_ maxLength: Int) -> String {
        String(filter(\.isNumber).prefix(maxLength))
    }
}
