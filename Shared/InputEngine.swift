import Foundation

enum InputCommand: Equatable {
    case insert(String)
    case deleteBackward
}

enum Consonant: String, CaseIterable {
    case k = "か", s = "さ", t = "た", n = "な", h = "は"
    case m = "ま", y = "や", r = "ら", w = "わ"
}

enum Vowel: String, CaseIterable {
    case a = "あ", i = "い", u = "う", e = "え", o = "お"
}

enum InputPhase: Equatable {
    case idle
    case composing
    case kanaProvisional
    case selectingConversion
}

enum CandidateKind: Equatable {
    case derived
    case conversion
}

struct CandidateList: Equatable {
    let kind: CandidateKind
    let values: [String]
}

struct InputEngine {
    private(set) var pendingConsonant: Consonant?
    private(set) var composingText = ""
    private(set) var phase: InputPhase = .idle
    private(set) var conversionCandidates: [String] = []
    private var currentBaseKana: String?
    private var displayedKana: String?

    var candidates: CandidateList? {
        if phase == .selectingConversion {
            return CandidateList(kind: .conversion, values: conversionCandidates)
        }
        guard let currentBaseKana,
              let values = Self.derivedKana[currentBaseKana],
              values.count > 1 else {
            return nil
        }
        return CandidateList(kind: .derived, values: values)
    }

    mutating func input(vowel: Vowel) -> [InputCommand] {
        conversionCandidates = []
        guard let consonant = pendingConsonant else {
            return appendKana(vowel.rawValue)
        }

        if consonant == .w, Self.kana[consonant]?[vowel] == nil {
            pendingConsonant = nil
            return appendKana(vowel.rawValue)
        }

        guard let kana = Self.kana[consonant]?[vowel], displayedKana != nil else {
            clearProvisionalState()
            return []
        }

        pendingConsonant = nil
        replaceLastComposingCharacter(with: kana)
        currentBaseKana = kana
        displayedKana = kana
        phase = .kanaProvisional
        return [.deleteBackward, .insert(kana)]
    }

    mutating func input(consonant: Consonant) -> [InputCommand] {
        conversionCandidates = []
        let kana = Self.kana[consonant]![.a]!
        pendingConsonant = consonant
        return appendKana(kana)
    }

    mutating func selectDerivedCandidate(_ candidate: String) -> [InputCommand] {
        guard phase == .kanaProvisional,
              displayedKana != nil,
              candidates?.kind == .derived,
              candidates?.values.contains(candidate) == true else {
            return []
        }

        replaceLastComposingCharacter(with: candidate)
        displayedKana = candidate
        return [.deleteBackward, .insert(candidate)]
    }

    mutating func beginConversion(with engineCandidates: [String]) {
        guard !composingText.isEmpty else { return }
        clearProvisionalState()
        let katakana = composingText.applyingTransform(.hiraganaToKatakana, reverse: false) ?? composingText
        conversionCandidates = Self.uniqued([composingText, katakana] + engineCandidates)
        phase = .selectingConversion
    }

    mutating func selectConversionCandidate(_ candidate: String) -> [InputCommand] {
        guard phase == .selectingConversion,
              conversionCandidates.contains(candidate),
              !composingText.isEmpty else {
            return []
        }
        let deleteCommands = Array(repeating: InputCommand.deleteBackward, count: composingText.count)
        resetComposition()
        return deleteCommands + [.insert(candidate)]
    }

    mutating func inputDirect(_ text: String) -> [InputCommand] {
        resetComposition()
        return [.insert(text)]
    }

    mutating func commit() -> [InputCommand] {
        resetComposition()
        return []
    }

    mutating func delete() -> [InputCommand] {
        conversionCandidates = []
        guard !composingText.isEmpty else {
            clearProvisionalState()
            phase = .idle
            return [.deleteBackward]
        }

        composingText.removeLast()
        clearProvisionalState()
        phase = composingText.isEmpty ? .idle : .composing
        return [.deleteBackward]
    }

    mutating func resetComposition() {
        pendingConsonant = nil
        composingText = ""
        phase = .idle
        conversionCandidates = []
        currentBaseKana = nil
        displayedKana = nil
    }

    private mutating func appendKana(_ kana: String) -> [InputCommand] {
        composingText.append(contentsOf: kana)
        currentBaseKana = kana
        displayedKana = kana
        phase = .kanaProvisional
        return [.insert(kana)]
    }

    private mutating func replaceLastComposingCharacter(with kana: String) {
        if !composingText.isEmpty {
            composingText.removeLast()
        }
        composingText.append(contentsOf: kana)
    }

    private mutating func clearProvisionalState() {
        pendingConsonant = nil
        currentBaseKana = nil
        displayedKana = nil
    }

    private static func uniqued(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private static let kana: [Consonant: [Vowel: String]] = [
        .k: [.a: "か", .i: "き", .u: "く", .e: "け", .o: "こ"],
        .s: [.a: "さ", .i: "し", .u: "す", .e: "せ", .o: "そ"],
        .t: [.a: "た", .i: "ち", .u: "つ", .e: "て", .o: "と"],
        .n: [.a: "な", .i: "に", .u: "ぬ", .e: "ね", .o: "の"],
        .h: [.a: "は", .i: "ひ", .u: "ふ", .e: "へ", .o: "ほ"],
        .m: [.a: "ま", .i: "み", .u: "む", .e: "め", .o: "も"],
        .y: [.a: "や", .i: "い", .u: "ゆ", .e: "え", .o: "よ"],
        .r: [.a: "ら", .i: "り", .u: "る", .e: "れ", .o: "ろ"],
        .w: [.a: "わ", .u: "ん", .o: "を"]
    ]

    private static let derivedKana: [String: [String]] = [
        "あ": ["あ", "ぁ"], "い": ["い", "ぃ"], "う": ["う", "ぅ", "ゔ"],
        "え": ["え", "ぇ"], "お": ["お", "ぉ"],
        "か": ["か", "が"], "き": ["き", "ぎ"], "く": ["く", "ぐ"], "け": ["け", "げ"], "こ": ["こ", "ご"],
        "さ": ["さ", "ざ"], "し": ["し", "じ"], "す": ["す", "ず"], "せ": ["せ", "ぜ"], "そ": ["そ", "ぞ"],
        "た": ["た", "だ"], "ち": ["ち", "ぢ"], "つ": ["つ", "っ", "づ"], "て": ["て", "で"], "と": ["と", "ど"],
        "は": ["は", "ば", "ぱ"], "ひ": ["ひ", "び", "ぴ"], "ふ": ["ふ", "ぶ", "ぷ"], "へ": ["へ", "べ", "ぺ"], "ほ": ["ほ", "ぼ", "ぽ"],
        "や": ["や", "ゃ"], "ゆ": ["ゆ", "ゅ"], "よ": ["よ", "ょ"], "わ": ["わ", "ゎ"]
    ]
}
