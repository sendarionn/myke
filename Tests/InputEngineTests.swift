import XCTest
#if SWIFT_PACKAGE
@testable import MykeInput
#else
@testable import myke
#endif

final class InputEngineTests: XCTestCase {
    func testVowelIsInsertedDirectly() {
        var engine = InputEngine()
        XCTAssertEqual(engine.input(vowel: .i), [.insert("い")])
        XCTAssertNil(engine.pendingConsonant)
    }

    func testConsonantStartsProvisionalInputAndVowelReplacesIt() {
        var engine = InputEngine()
        XCTAssertEqual(engine.input(consonant: .k), [.insert("か")])
        XCTAssertEqual(engine.pendingConsonant, .k)
        XCTAssertEqual(engine.input(vowel: .u), [.deleteBackward, .insert("く")])
        XCTAssertNil(engine.pendingConsonant)
    }

    func testAnotherConsonantKeepsPreviousTextAndStartsNextInput() {
        var engine = InputEngine()
        XCTAssertEqual(engine.input(consonant: .k), [.insert("か")])
        XCTAssertEqual(engine.input(consonant: .s), [.insert("さ")])
        XCTAssertEqual(engine.input(vowel: .i), [.deleteBackward, .insert("し")])
    }

    func testCommitEndsProvisionalInputWithoutEditingText() {
        var engine = InputEngine()
        _ = engine.input(consonant: .t)
        XCTAssertEqual(engine.commit(), [])
        XCTAssertNil(engine.pendingConsonant)
        XCTAssertEqual(engine.input(vowel: .e), [.insert("え")])
    }

    func testDeleteRemovesProvisionalCharacterFirst() {
        var engine = InputEngine()
        _ = engine.input(consonant: .n)
        XCTAssertEqual(engine.delete(), [.deleteBackward])
        XCTAssertNil(engine.pendingConsonant)
    }

    func testDirectInputCommitsProvisionalInput() {
        var engine = InputEngine()
        _ = engine.input(consonant: .h)
        XCTAssertEqual(engine.inputDirect(" "), [.insert(" ")])
        XCTAssertNil(engine.pendingConsonant)
    }

    func testAllKanaRows() {
        let expected: [Consonant: [String]] = [
            .k: ["か", "き", "く", "け", "こ"], .s: ["さ", "し", "す", "せ", "そ"],
            .t: ["た", "ち", "つ", "て", "と"], .n: ["な", "に", "ぬ", "ね", "の"],
            .h: ["は", "ひ", "ふ", "へ", "ほ"], .m: ["ま", "み", "む", "め", "も"],
            .y: ["や", "い", "ゆ", "え", "よ"], .r: ["ら", "り", "る", "れ", "ろ"],
            .w: ["わ", "ゐ", "う", "ゑ", "を"]
        ]
        for consonant in Consonant.allCases {
            for (index, vowel) in Vowel.allCases.enumerated() {
                var engine = InputEngine()
                _ = engine.input(consonant: consonant)
                XCTAssertEqual(engine.input(vowel: vowel), [.deleteBackward, .insert(expected[consonant]![index])])
            }
        }
    }
}

