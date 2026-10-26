import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary

final class KanaKanjiConversionEngine {
    private let converter = KanaKanjiConverter.withDefaultDictionary()

    func candidates(for reading: String) -> [String] {
        guard !reading.isEmpty else { return [] }

        var composingText = ComposingText()
        composingText.insertAtCursorPosition(reading, inputStyle: .direct)
        let storageURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let results = converter.requestCandidates(
            composingText,
            options: .init(
                N_best: 10,
                requireJapanesePrediction: true,
                requireEnglishPrediction: false,
                keyboardLanguage: .ja_JP,
                englishCandidateInRoman2KanaInput: false,
                fullWidthRomanCandidate: false,
                halfWidthKanaCandidate: false,
                learningType: .nothing,
                maxMemoryCount: 0,
                shouldResetMemory: false,
                memoryDirectoryURL: storageURL,
                sharedContainerURL: storageURL,
                textReplacer: .withDefaultEmojiDictionary(),
                specialCandidateProviders: KanaKanjiConverter.defaultSpecialCandidateProviders,
                metadata: .init(versionString: "myke 1.0")
            )
        )
        return results.mainResults.map(\.text)
    }
}
