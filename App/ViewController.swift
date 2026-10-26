import UIKit

final class ViewController: UIViewController, KeyboardViewDelegate, UITextViewDelegate {
    private let textView = UITextView()
    private let keyboardView = KeyboardView()
    private var isApplyingKeyboardCommands = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "myke"
        view.backgroundColor = .systemBackground

        textView.font = .systemFont(ofSize: 22)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = 8
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false

        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textView)
        view.addSubview(keyboardView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 180),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            keyboardView.heightAnchor.constraint(equalToConstant: 348)
        ])
    }

    func keyboardView(_ keyboardView: KeyboardView, perform commands: [InputCommand]) {
        isApplyingKeyboardCommands = true
        defer { isApplyingKeyboardCommands = false }
        for command in commands {
            switch command {
            case .insert(let text): textView.insertText(text)
            case .deleteBackward: textView.deleteBackward()
            }
        }
    }

    func keyboardViewDidRequestNextKeyboard(_ keyboardView: KeyboardView) {}

    func textViewDidChangeSelection(_ textView: UITextView) {
        if !isApplyingKeyboardCommands {
            keyboardView.resetComposition()
        }
    }
}

