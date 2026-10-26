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
        XCTAssertEqual(engine.composingText, "い")
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
        XCTAssertEqual(engine.composingText, "")
    }

    func testWaAndUProducesN() {
        var engine = InputEngine()
        XCTAssertEqual(engine.input(consonant: .w), [.insert("わ")])
        XCTAssertEqual(engine.input(vowel: .u), [.deleteBackward, .insert("ん")])
        XCTAssertEqual(engine.composingText, "ん")
    }

    func testUndefinedWaRowCombinationKeepsText() {
        var engine = InputEngine()
        _ = engine.input(consonant: .w)
        XCTAssertEqual(engine.input(vowel: .i), [.insert("い")])
        XCTAssertEqual(engine.composingText, "わい")
    }

    func testVoicedCandidateReplacesOnlyCurrentKana() {
        var engine = InputEngine()
        _ = engine.input(vowel: .a)
        _ = engine.input(consonant: .k)
        XCTAssertEqual(engine.candidates, CandidateList(kind: .derived, values: ["か", "が"]))
        XCTAssertEqual(engine.selectDerivedCandidate("が"), [.deleteBackward, .insert("が")])
        XCTAssertEqual(engine.composingText, "あが")
    }

    func testSemiVoicedCandidates() {
        var engine = InputEngine()
        _ = engine.input(consonant: .h)
        XCTAssertEqual(engine.candidates?.values, ["は", "ば", "ぱ"])
        XCTAssertEqual(engine.selectDerivedCandidate("ぱ"), [.deleteBackward, .insert("ぱ")])
    }

    func testDerivedCandidatesFollowVowelChange() {
        var engine = InputEngine()
        _ = engine.input(consonant: .h)
        _ = engine.selectDerivedCandidate("ば")
        XCTAssertEqual(engine.input(vowel: .i), [.deleteBackward, .insert("ひ")])
        XCTAssertEqual(engine.candidates?.values, ["ひ", "び", "ぴ"])
    }

    func testSmallTsuAndSmallYa() {
        var tsu = InputEngine()
        _ = tsu.input(consonant: .t)
        _ = tsu.input(vowel: .u)
        XCTAssertEqual(tsu.selectDerivedCandidate("っ"), [.deleteBackward, .insert("っ")])

        var ya = InputEngine()
        _ = ya.input(consonant: .y)
        XCTAssertEqual(ya.selectDerivedCandidate("ゃ"), [.deleteBackward, .insert("ゃ")])
    }

    func testDerivedSelectionDoesNotChangeEarlierCharacter() {
        var engine = InputEngine()
        _ = engine.input(consonant: .k)
        _ = engine.input(consonant: .h)
        _ = engine.selectDerivedCandidate("ぱ")
        XCTAssertEqual(engine.composingText, "かぱ")
    }

    func testHiraganaCanBeCommittedFromConversionCandidates() {
        var engine = makeKanjiReadingEngine()
        engine.beginConversion(with: ["漢字"])
        XCTAssertEqual(engine.candidates?.values.prefix(3), ["かんじ", "カンジ", "漢字"])
        XCTAssertEqual(
            engine.selectConversionCandidate("かんじ"),
            [.deleteBackward, .deleteBackward, .deleteBackward, .insert("かんじ")]
        )
        XCTAssertEqual(engine.phase, .idle)
    }

    func testKatakanaCanBeCommitted() {
        var engine = makeKanjiReadingEngine()
        engine.beginConversion(with: [])
        XCTAssertEqual(engine.selectConversionCandidate("カンジ").last, .insert("カンジ"))
    }

    func testConversionCandidateCanBeSelectedAndTypingCanContinue() {
        var engine = makeKanjiReadingEngine()
        engine.beginConversion(with: ["漢字", "感じ"])
        XCTAssertEqual(engine.selectConversionCandidate("感じ").last, .insert("感じ"))
        XCTAssertEqual(engine.input(vowel: .o), [.insert("お")])
        XCTAssertEqual(engine.composingText, "お")
    }

    func testDeleteWhileSelectingConversionReturnsToComposition() {
        var engine = makeKanjiReadingEngine()
        engine.beginConversion(with: ["漢字"])
        XCTAssertEqual(engine.delete(), [.deleteBackward])
        XCTAssertEqual(engine.composingText, "かん")
        XCTAssertEqual(engine.phase, .composing)
        XCTAssertNil(engine.candidates)
    }

    private func makeKanjiReadingEngine() -> InputEngine {
        var engine = InputEngine()
        _ = engine.input(consonant: .k)
        _ = engine.input(consonant: .w)
        _ = engine.input(vowel: .u)
        _ = engine.input(consonant: .s)
        _ = engine.input(vowel: .i)
        _ = engine.selectDerivedCandidate("じ")
        return engine
    }
}

