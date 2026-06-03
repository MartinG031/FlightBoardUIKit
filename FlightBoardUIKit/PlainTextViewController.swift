import UIKit

final class PlainTextViewController: UIViewController, UITextViewDelegate {
    private enum Constants {
        static let storageKey = "plain_text_v1"
    }

    private let textView = UITextView()
    private let saveQueue = DispatchQueue(label: "FlightBoardUIKit.plainText.save", qos: .utility)
    private var pendingSave: DispatchWorkItem?

    deinit {
        pendingSave?.cancel()
        save(textView.text ?? "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文本"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneEditing)
        )
        buildTextView()
    }

    private func buildTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true
        textView.delegate = self
        textView.text = UserDefaults.standard.string(forKey: Constants.storageKey)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func textViewDidChange(_ textView: UITextView) {
        scheduleSave(textView.text)
    }

    @objc private func doneEditing() {
        flushPendingSave()
        view.endEditing(true)
    }

    private func scheduleSave(_ text: String) {
        pendingSave?.cancel()
        let item = DispatchWorkItem { [text] in
            UserDefaults.standard.set(text, forKey: Constants.storageKey)
        }
        pendingSave = item
        saveQueue.asyncAfter(deadline: .now() + 0.6, execute: item)
    }

    private func flushPendingSave() {
        pendingSave?.cancel()
        save(textView.text ?? "")
    }

    private func save(_ text: String) {
        UserDefaults.standard.set(text, forKey: Constants.storageKey)
    }
}
