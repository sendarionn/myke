import UIKit

@MainActor
protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ keyboardView: KeyboardView, perform commands: [InputCommand])
    func keyboardViewDidRequestNextKeyboard(_ keyboardView: KeyboardView)
}

final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?
    var showsNextKeyboardKey = false {
        didSet { nextKeyboardButton.isHidden = !showsNextKeyboardKey }
    }

    private var engine = InputEngine()
    private let utilityStack = UIStackView()
    private let nextKeyboardButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let gridStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    func resetComposition() {
        engine.resetComposition()
    }

    private func configureView() {
        backgroundColor = UIColor.systemGray5
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)

        let root = UIStackView(arrangedSubviews: [utilityStack, gridStack])
        root.axis = .vertical
        root.spacing = 5
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            root.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            root.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            utilityStack.heightAnchor.constraint(equalToConstant: 38)
        ])

        utilityStack.axis = .horizontal
        utilityStack.spacing = 6
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.accessibilityLabel = "次のキーボード"
        nextKeyboardButton.addTarget(self, action: #selector(nextKeyboardTapped), for: .touchUpInside)
        deleteButton.setTitle("削除", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        utilityStack.addArrangedSubview(nextKeyboardButton)
        utilityStack.addArrangedSubview(UIView())
        utilityStack.addArrangedSubview(deleteButton)
        nextKeyboardButton.isHidden = !showsNextKeyboardKey

        gridStack.axis = .vertical
        gridStack.spacing = 5
        let rows: [[Key]] = [
            [.vowel(.a), .action("空白", " "), .consonant(.k), .consonant(.s)],
            [.vowel(.i), .commit, .consonant(.t), .consonant(.n)],
            [.vowel(.u), .picker("、。", ["、", "。", "？", "！"]), .consonant(.h), .consonant(.m)],
            [.vowel(.e), .picker("記号", ["「", "」", "（", "）", "…"]), .consonant(.y), .consonant(.r)],
            [.vowel(.o), .picker("絵文字", ["😀", "😊", "👍", "❤️", "🙏"]), .consonant(.w), .action("ー", "ー")]
        ]

        for rowKeys in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 5
            row.distribution = .fill
            let buttons = rowKeys.map(makeButton)
            for button in buttons {
                row.addArrangedSubview(button)
            }
            for (index, button) in buttons.enumerated() {
                if index == 0 || index == 1 {
                    button.widthAnchor.constraint(equalTo: buttons[2].widthAnchor, multiplier: 2).isActive = true
                } else if index == 3 {
                    button.widthAnchor.constraint(equalTo: buttons[2].widthAnchor).isActive = true
                }
            }
            gridStack.addArrangedSubview(row)
        }
    }

    private func makeButton(for key: Key) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .systemBackground
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .medium
        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.setTitle(key.title, for: .normal)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        button.addAction(UIAction { [weak self] _ in self?.handle(key) }, for: .touchUpInside)
        return button
    }

    private func handle(_ key: Key) {
        switch key {
        case .vowel(let vowel): perform(engine.input(vowel: vowel))
        case .consonant(let consonant): perform(engine.input(consonant: consonant))
        case .action(_, let text): perform(engine.inputDirect(text))
        case .commit: perform(engine.commit())
        case .picker(_, let choices): showChoices(choices)
        }
    }

    private func showChoices(_ choices: [String]) {
        utilityStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for choice in choices {
            let button = UIButton(type: .system)
            button.setTitle(choice, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20)
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.perform(self.engine.inputDirect(choice))
                self.restoreUtilityButtons()
            }, for: .touchUpInside)
            utilityStack.addArrangedSubview(button)
        }
        let cancel = UIButton(type: .system)
        cancel.setTitle("戻る", for: .normal)
        cancel.addAction(UIAction { [weak self] _ in self?.restoreUtilityButtons() }, for: .touchUpInside)
        utilityStack.addArrangedSubview(cancel)
    }

    private func restoreUtilityButtons() {
        utilityStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        utilityStack.addArrangedSubview(nextKeyboardButton)
        utilityStack.addArrangedSubview(UIView())
        utilityStack.addArrangedSubview(deleteButton)
        nextKeyboardButton.isHidden = !showsNextKeyboardKey
    }

    private func perform(_ commands: [InputCommand]) {
        delegate?.keyboardView(self, perform: commands)
    }

    @objc private func deleteTapped() { perform(engine.delete()) }
    @objc private func nextKeyboardTapped() { delegate?.keyboardViewDidRequestNextKeyboard(self) }
}

private enum Key {
    case vowel(Vowel)
    case consonant(Consonant)
    case action(String, String)
    case commit
    case picker(String, [String])

    var title: String {
        switch self {
        case .vowel(let value): value.rawValue
        case .consonant(let value): value.rawValue
        case .action(let title, _), .picker(let title, _): title
        case .commit: "確定"
        }
    }
}

