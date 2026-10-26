import Foundation

enum InputCommand: Equatable {
    case insert(String)
    case deleteBackward
}

enum Consonant: String, CaseIterable {
    case k = "か"
    case s = "さ"
    case t = "た"
    case n = "な"
    case h = "は"
    case m = "ま"
    case y = "や"
    case r = "ら"
    case w = "わ"
}

enum Vowel: String, CaseIterable {
    case a = "あ"
    case i = "い"
    case u = "う"
    case e = "え"
    case o = "お"
}

struct InputEngine {
    private(set) var pendingConsonant: Consonant?

    mutating func input(vowel: Vowel) -> [InputCommand] {
        guard let consonant = pendingConsonant else {
            return [.insert(vowel.rawValue)]
        }

        pendingConsonant = nil
        return [.deleteBackward, .insert(Self.kana[consonant]![vowel]!)]
    }

    mutating func input(consonant: Consonant) -> [InputCommand] {
        pendingConsonant = consonant
        return [.insert(Self.kana[consonant]![.a]!)]
    }

    mutating func inputDirect(_ text: String) -> [InputCommand] {
        pendingConsonant = nil
        return [.insert(text)]
    }

    mutating func commit() -> [InputCommand] {
        pendingConsonant = nil
        return []
    }

    mutating func delete() -> [InputCommand] {
        pendingConsonant = nil
        return [.deleteBackward]
    }

    mutating func resetComposition() {
        pendingConsonant = nil
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
        .w: [.a: "わ", .i: "ゐ", .u: "う", .e: "ゑ", .o: "を"]
    ]
}

