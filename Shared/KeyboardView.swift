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
    private lazy var conversionEngine = KanaKanjiConversionEngine()
    private let candidateContainer = UIStackView()
    private let candidateLabel = UILabel()
    private let candidateScrollView = UIScrollView()
    private let candidateStack = UIStackView()
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
        refreshCandidates()
    }

    private func configureView() {
        backgroundColor = .systemGray5
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)

        configureCandidateBar()
        configureUtilityBar()
        configureKeyGrid()

        let root = UIStackView(arrangedSubviews: [candidateContainer, utilityStack, gridStack])
        root.axis = .vertical
        root.spacing = 5
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            root.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            root.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            candidateContainer.heightAnchor.constraint(equalToConstant: 40),
            utilityStack.heightAnchor.constraint(equalToConstant: 38)
        ])
        candidateContainer.isHidden = true
    }

    private func configureCandidateBar() {
        candidateContainer.axis = .horizontal
        candidateContainer.spacing = 6
        candidateContainer.alignment = .fill

        candidateLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        candidateLabel.textColor = .secondaryLabel
        candidateLabel.setContentHuggingPriority(.required, for: .horizontal)
        candidateContainer.addArrangedSubview(candidateLabel)
        candidateContainer.addArrangedSubview(candidateScrollView)

        candidateScrollView.showsHorizontalScrollIndicator = false
        candidateStack.axis = .horizontal
        candidateStack.spacing = 6
        candidateStack.translatesAutoresizingMaskIntoConstraints = false
        candidateScrollView.addSubview(candidateStack)
        NSLayoutConstraint.activate([
            candidateStack.leadingAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.leadingAnchor),
            candidateStack.trailingAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.trailingAnchor),
            candidateStack.topAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.topAnchor),
            candidateStack.bottomAnchor.constraint(equalTo: candidateScrollView.contentLayoutGuide.bottomAnchor),
            candidateStack.heightAnchor.constraint(equalTo: candidateScrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    private func configureUtilityBar() {
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
    }

    private func configureKeyGrid() {
        gridStack.axis = .vertical
        gridStack.spacing = 5
        gridStack.distribution = .fillEqually
        let rows: [[Key]] = [
            [.vowel(.a), .space, .consonant(.k), .consonant(.s)],
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
            buttons.forEach(row.addArrangedSubview)
            buttons[0].widthAnchor.constraint(equalTo: buttons[2].widthAnchor, multiplier: 2).isActive = true
            buttons[1].widthAnchor.constraint(equalTo: buttons[2].widthAnchor, multiplier: 2).isActive = true
            buttons[3].widthAnchor.constraint(equalTo: buttons[2].widthAnchor).isActive = true
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
        case .space: handleSpace()
        case .commit: perform(engine.commit())
        case .picker(let title, let choices): showStaticCandidates(title: title, choices: choices)
        }
    }

    private func handleSpace() {
        guard !engine.composingText.isEmpty else {
            perform(engine.inputDirect(" "))
            return
        }
        let values = conversionEngine.candidates(for: engine.composingText)
        engine.beginConversion(with: values)
        refreshCandidates()
    }

    private func refreshCandidates() {
        guard let candidates = engine.candidates else {
            hideCandidates()
            return
        }
        candidateLabel.text = candidates.kind == .derived ? "派生" : "変換"
        showCandidateButtons(candidates.values) { [weak self] candidate in
            guard let self else { return }
            let commands: [InputCommand]
            switch candidates.kind {
            case .derived: commands = self.engine.selectDerivedCandidate(candidate)
            case .conversion: commands = self.engine.selectConversionCandidate(candidate)
            }
            self.perform(commands)
        }
    }

    private func showStaticCandidates(title: String, choices: [String]) {
        candidateLabel.text = title
        showCandidateButtons(choices) { [weak self] choice in
            guard let self else { return }
            self.perform(self.engine.inputDirect(choice))
        }
    }

    private func showCandidateButtons(_ values: [String], selection: @escaping (String) -> Void) {
        candidateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for value in values {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = .systemBackground
            configuration.baseForegroundColor = .label
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
            let button = UIButton(configuration: configuration)
            button.setTitle(value, for: .normal)
            button.addAction(UIAction { _ in selection(value) }, for: .touchUpInside)
            candidateStack.addArrangedSubview(button)
        }
        candidateContainer.isHidden = values.isEmpty
        candidateScrollView.setContentOffset(.zero, animated: false)
    }

    private func hideCandidates() {
        candidateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        candidateContainer.isHidden = true
    }

    private func perform(_ commands: [InputCommand]) {
        delegate?.keyboardView(self, perform: commands)
        refreshCandidates()
    }

    @objc private func deleteTapped() { perform(engine.delete()) }
    @objc private func nextKeyboardTapped() { delegate?.keyboardViewDidRequestNextKeyboard(self) }
}

private enum Key {
    case vowel(Vowel)
    case consonant(Consonant)
    case action(String, String)
    case space
    case commit
    case picker(String, [String])

    var title: String {
        switch self {
        case .vowel(let value): value.rawValue
        case .consonant(let value): value.rawValue
        case .action(let title, _), .picker(let title, _): title
        case .space: "空白"
        case .commit: "確定"
        }
    }
}
