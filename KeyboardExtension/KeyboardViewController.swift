import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardViewDelegate {
    private let keyboardView = KeyboardView()

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)
        NSLayoutConstraint.activate([
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardView.showsNextKeyboardKey = needsInputModeSwitchKey
    }

    override func textWillChange(_ textInput: (any UITextInput)?) {
        keyboardView.resetComposition()
    }

    func keyboardView(_ keyboardView: KeyboardView, perform commands: [InputCommand]) {
        for command in commands {
            switch command {
            case .insert(let text): textDocumentProxy.insertText(text)
            case .deleteBackward: textDocumentProxy.deleteBackward()
            }
        }
    }

    func keyboardViewDidRequestNextKeyboard(_ keyboardView: KeyboardView) {
        advanceToNextInputMode()
    }
}

