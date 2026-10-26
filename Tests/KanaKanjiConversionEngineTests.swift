import XCTest
#if SWIFT_PACKAGE
@testable import MykeInput
#else
@testable import myke
#endif

final class KanaKanjiConversionEngineTests: XCTestCase {
    func testOfflineDictionaryConvertsHiraganaToKanji() {
        let candidates = KanaKanjiConversionEngine().candidates(for: "かんじ")
        XCTAssertTrue(candidates.contains("漢字"))
    }

    func testSentenceConversionReturnsCandidateWithoutLosingReading() {
        let candidates = KanaKanjiConversionEngine().candidates(for: "きょうはいいてんきです")
        XCTAssertFalse(candidates.isEmpty)
    }
}
